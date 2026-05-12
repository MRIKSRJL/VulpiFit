using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VulpiFit.API.Data;
using VulpiFit.API.Models;
using VulpiFit.API.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.Text.RegularExpressions;

namespace VulpiFit.API.Controllers
{
    [Authorize] 
    [Route("api/[controller]")]
    [ApiController]
    public class MissionsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly GroqService _groqService;
        private readonly CoopStreakService _coopStreakService;
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _environment;

        public MissionsController(
            ApplicationDbContext context,
            GroqService groqService,
            CoopStreakService coopStreakService,
            IConfiguration configuration,
            IWebHostEnvironment environment)
        {
            _context = context;
            _groqService = groqService;
            _coopStreakService = coopStreakService;
            _configuration = configuration;
            _environment = environment;
        }

        /// <summary>
        /// Normalise une date issue de la BDD (souvent Kind=Unspecified) comme UTC pour la comparaison de streak.
        /// </summary>
        private static DateTime NormalizeActivityUtc(DateTime value)
        {
            return value.Kind switch
            {
                DateTimeKind.Utc => value,
                DateTimeKind.Local => value.ToUniversalTime(),
                _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
            };
        }

        /// <summary>
        /// Jour calendaire local : évite le bug minuit (ex. validation à 00h01 le « nouveau » jour
        /// alors que UTC était encore « hier » par rapport aux missions basées sur DateTime.Today serveur).
        /// </summary>
        private static DateTime GetLocalCalendarDayFromUtc(DateTime utc)
        {
            return TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(utc, DateTimeKind.Utc), TimeZoneInfo.Local).Date;
        }

        private static void UpdateStreakForCompletion(User user, DateTime nowUtc)
        {
            var todayLocal = GetLocalCalendarDayFromUtc(nowUtc);
            DateTime? lastLocalDay = null;
            if (user.LastActivityDate.HasValue)
            {
                var lastUtc = NormalizeActivityUtc(user.LastActivityDate.Value);
                lastLocalDay = GetLocalCalendarDayFromUtc(lastUtc);
            }

            if (lastLocalDay == null)
            {
                if (user.CurrentStreak <= 0) user.CurrentStreak = 1;
            }
            else if (lastLocalDay == todayLocal)
            {
                if (user.CurrentStreak == 0) user.CurrentStreak = 1;
            }
            else if (lastLocalDay == todayLocal.AddDays(-1))
            {
                user.CurrentStreak += 1;
            }
            else
            {
                user.CurrentStreak = 1;
            }

            user.LastActivityDate = nowUtc;
        }

        private static bool HasQuantity(string title)
        {
            return Regex.IsMatch(title, @"\b\d+\s?(g|kg|ml|l|min|minutes?|page|pages|tranches?|oeufs?|fruit|fruits)\b", RegexOptions.IgnoreCase);
        }

        /// Lecture / podcast / pages : toujours Mental, jamais Sport (corrige les erreurs du LLM).
        private static bool LooksLikeMentalActivityTitle(string title)
        {
            if (string.IsNullOrWhiteSpace(title)) return false;
            var lower = title.ToLowerInvariant();
            if (Regex.IsMatch(lower, @"\b(lire|lectures?|podcast)\b")) return true;
            if (Regex.IsMatch(lower, @"\b\d+\s+pages?\b")) return true;
            return false;
        }

        private static bool IsNutritionTooVague(string title)
        {
            var lower = title.ToLowerInvariant();
            return lower.Contains("manger équilibr") ||
                   lower.Contains("petit-déjeuner équilibr") ||
                   lower.Contains("manger un fruit") ||
                   lower.Contains("boire de l'eau") ||
                   lower.Contains("boire au moins 1l d'eau") ||
                   lower.Contains("boire 2l d'eau");
        }

        private static bool IsMentalTooVague(string title)
        {
            var lower = title.ToLowerInvariant();
            return lower.Contains("gratitude 1 minute") ||
                   lower == "respirer" ||
                   lower.Contains("se détendre") ||
                   lower.Contains("penser positif");
        }

        private static int ComputeQualityScore(Mission mission)
        {
            var score = 0;
            var title = mission.Title ?? string.Empty;
            if (title.Length >= 25) score += 1;
            if (HasQuantity(title)) score += 2;
            if (title.Contains(":")) score += 1;
            if (mission.Type == "Mental" && (title.ToLowerInvariant().Contains("lire") || title.ToLowerInvariant().Contains("podcast"))) score += 1;
            return score;
        }

        private List<Mission> ImproveMissionQuality(User user, List<Mission> missions)
        {
            var improved = new List<Mission>();
            var fallbackPool = _groqService.BuildQualityFallbackMissions(user);
            var fallbackNutrition = fallbackPool.Where(m => m.Type == "Nutrition").ToList();
            var fallbackMental = fallbackPool.Where(m => m.Type == "Mental").ToList();
            var fallbackSport = fallbackPool.FirstOrDefault(m => m.Type == "Sport");

            var nutritionIdx = 0;
            var mentalIdx = 0;

            foreach (var mission in missions)
            {
                if (mission == null) continue;
                mission.Type = (mission.Type ?? string.Empty).Trim();
                mission.Title = (mission.Title ?? string.Empty).Trim();
                mission.Points = Math.Clamp(mission.Points, 10, 30);

                if (mission.Type.Equals("Sport", StringComparison.OrdinalIgnoreCase) &&
                    LooksLikeMentalActivityTitle(mission.Title))
                {
                    mission.Type = "Mental";
                }

                var replace = false;
                if (mission.Type.Equals("Nutrition", StringComparison.OrdinalIgnoreCase))
                {
                    replace = !HasQuantity(mission.Title) || IsNutritionTooVague(mission.Title);
                    if (replace && nutritionIdx < fallbackNutrition.Count)
                    {
                        mission.Title = fallbackNutrition[nutritionIdx++].Title;
                    }
                }
                else if (mission.Type.Equals("Mental", StringComparison.OrdinalIgnoreCase))
                {
                    replace = (!HasQuantity(mission.Title) && !mission.Title.ToLowerInvariant().Contains("lire") && !mission.Title.ToLowerInvariant().Contains("podcast"))
                              || IsMentalTooVague(mission.Title);
                    if (replace && mentalIdx < fallbackMental.Count)
                    {
                        mission.Title = fallbackMental[mentalIdx++].Title;
                    }
                }
                else if (mission.Type.Equals("Sport", StringComparison.OrdinalIgnoreCase))
                {
                    if (string.IsNullOrWhiteSpace(mission.Title) && fallbackSport != null)
                    {
                        mission.Title = fallbackSport.Title;
                    }
                }
                else
                {
                    // Type inconnu: ignorer pour garder uniquement Sport/Nutrition/Mental.
                    continue;
                }

                improved.Add(mission);
            }

            // Garantit présence de Mental et Nutrition même si la génération est partielle.
            if (!improved.Any(m => m.Type.Equals("Nutrition", StringComparison.OrdinalIgnoreCase)))
            {
                improved.AddRange(fallbackNutrition.Take(2));
            }
            if (!improved.Any(m => m.Type.Equals("Mental", StringComparison.OrdinalIgnoreCase)))
            {
                improved.Add(fallbackMental.First());
            }

            return improved.Take(8).ToList();
        }

        private static void CalibratePointsByProfile(User user, List<Mission> missions)
        {
            var goals = (user.Goals ?? string.Empty).ToLowerInvariant();
            var streak = user.CurrentStreak;
            foreach (var mission in missions)
            {
                var points = mission.Points;
                if (streak >= 10) points += 2;
                if (streak == 0) points -= 2;

                if (mission.Type == "Sport" && (goals.Contains("perte") || goals.Contains("gras")))
                {
                    points += 1;
                }

                if (mission.Type == "Nutrition" && goals.Contains("muscle"))
                {
                    points += 1;
                }

                mission.Points = Math.Clamp(points, 10, 30);
            }
        }

        // GET: api/Missions
        [HttpGet("{userId}")]
        public async Task<ActionResult<IEnumerable<Mission>>> GetMissionsForUser(int userId)
        {
            // Vérification de sécurité : l'utilisateur ne peut voir que ses propres missions
            var authenticatedUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (authenticatedUserId != userId.ToString())
            {
                return Forbid();
            }

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("Utilisateur non trouvé.");

            var today = DateTime.Today;

            // 1. VÉRIFICATION : généreration des missions aujourd'hui ?
            var dailyMissions = await _context.Missions
                .Where(m => m.UserId == userId && m.AssignedDate.Date == today)
                .ToListAsync();

            if (dailyMissions.Any())
            {
                return Ok(dailyMissions);
            }

            // 2. CRÉATION PAR L'IA AVEC HISTORIQUE 
            Console.WriteLine($"🚀 Génération de missions IA pour le joueur {user.Pseudo}...");

            // On récupère les 15 dernières performances (Poids/Reps) du joueur
            var recentLogs = await _context.ExerciseLogs
                .Where(e => e.UserId == userId)
                .OrderByDescending(e => e.Date)
                .Take(15)
                .ToListAsync();

            List<Mission> newMissions;
            string? groqError = null;
            try
            {
                //  On passe l'historique à notre GroqService
                newMissions = await _groqService.GenerateDailyMissionsAsync(user, recentLogs);
            }
            catch (Exception ex)
            {
                groqError = ex.Message;
                newMissions = new List<Mission>();
            }

            var useFallback = _configuration.GetValue<bool?>("Groq:UseFallbackMissions")
                ?? !_environment.IsDevelopment();

            // Plan de secours : Si Groq a un bug réseau
            if (newMissions == null || !newMissions.Any())
            {
                if (!useFallback)
                {
                    return StatusCode(502, $"Groq generation failed: {groqError ?? "unknown error"}");
                }

                Console.WriteLine("⚠️ Échec IA : Utilisation des missions de secours.");
                newMissions = _groqService.BuildQualityFallbackMissions(user);
            }

            newMissions = ImproveMissionQuality(user, newMissions);
            CalibratePointsByProfile(user, newMissions);
            foreach (var m in newMissions)
            {
                Console.WriteLine($"[MissionQuality] Type={m.Type} Score={ComputeQualityScore(m)} Title={m.Title}");
            }

            // 3. SAUVEGARDE 
            foreach (var mission in newMissions)
            {
                mission.UserId = userId;
                mission.AssignedDate = today;
                mission.IsCompleted = false;
                _context.Missions.Add(mission);
            }

            await _context.SaveChangesAsync();
            return Ok(newMissions);
        }

        // POST: api/Missions/Complete
        [HttpPost("Complete/{id}")]
        public async Task<IActionResult> CompleteMission(int id, [FromQuery] int userId)
        {
            try
            {
                // Vérification de sécurité
                var authenticatedUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (authenticatedUserId != userId.ToString())
                {
                    return Forbid();
                }

                var mission = await _context.Missions.FindAsync(id);
                if (mission == null || mission.UserId != userId) return NotFound();

                // On vérifie que la mission n'est pas déjà complétée
                if (!mission.IsCompleted)
                {
                    mission.IsCompleted = true;

                    var user = await _context.Users.FindAsync(userId);
                    if (user != null)
                    {
                        // 1. On ajoute les points
                        user.Score += mission.Points;
                        user.TotalMissionsCompleted += 1;

                        // 2. Streak : jours calendaires **locaux** (minuit / 00h01 inclus)
                        var nowUtc = DateTime.UtcNow;
                        UpdateStreakForCompletion(user, nowUtc);
                    }

                    await _context.SaveChangesAsync();
                    await _coopStreakService.UpdateCoopStreakAsync(userId);
                }

                return Ok(mission);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }

        // POST: api/Missions/Undo
        [HttpPost("Undo/{id}")]
        public async Task<IActionResult> UndoMission(int id, [FromQuery] int userId)
        {
            // Vérification de sécurité
            var authenticatedUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (authenticatedUserId != userId.ToString())
            {
                return Forbid();
            }

            var mission = await _context.Missions.FirstOrDefaultAsync(m => m.Id == id && m.UserId == userId);
            if (mission == null) return NotFound();

            if (mission.IsCompleted)
            {
                mission.IsCompleted = false;

                var user = await _context.Users.FindAsync(userId);
                if (user != null)
                {
                    user.Score -= mission.Points;
                    user.TotalMissionsCompleted -= 1;
                }
                await _context.SaveChangesAsync();
            }
            return Ok();
        }

        /// <summary>
        /// ENDPOINT DE DEBUG (temporaire) :
        /// Permet de visualiser le prompt exact envoyé à Groq pour différents niveaux de streak,
        /// SANS appeler l'API Groq. Utilise un utilisateur synthétique.
        /// Exemple :
        ///   GET /api/Missions/debug/groq-prompt?streak=0
        ///   GET /api/Missions/debug/groq-prompt?streak=5
        ///   GET /api/Missions/debug/groq-prompt?streak=15
        /// </summary>
        [HttpGet("debug/groq-prompt")]
        [AllowAnonymous]
        public ActionResult<object> GetGroqPromptDebug([FromQuery] int streak = 0)
        {
            var fakeUser = new User
            {
                Id = 0,
                Pseudo = $"Debug_Streak_{streak}",
                CurrentStreak = streak,
                Score = 0,
                TotalMissionsCompleted = 0,
                Weight = 70,
                Height = 175,
                Injuries = "Aucune blessure majeure",
                Goals = "Perte de gras et gain de force",
                LastFeedback = "Debug prompt uniquement.",
                LastDifficulty = 5
            };

            var prompt = _groqService.BuildDailyMissionPrompt(fakeUser, new List<ExerciseLog>());

            return Ok(new
            {
                streak,
                pseudo = fakeUser.Pseudo,
                prompt
            });
        }
        // ROUTE  POUR LE SITE WEB ADMIN (MVC)
        [HttpGet]
        [AllowAnonymous] // dit au videur de laisser passer la requête sans Token VIP
        public async Task<ActionResult<IEnumerable<Mission>>> GetAllMissionsForAdmin()
        {
            // L'API va chercher toutes les missions dans la base de données et les donne au site Web
            return await _context.Missions.ToListAsync();
        }

        //  Créer une mission manuellement
        [HttpPost]
        [AllowAnonymous] // On laisse passer le site Web
        public async Task<IActionResult> CreateMissionForAdmin(Mission mission)
        {
            // On s'assure que la date d'assignation est bien mise à aujourd'hui
            if (mission.AssignedDate == default)
            {
                mission.AssignedDate = DateTime.Today;
            }

            // On sauvegarde dans la base de données
            _context.Missions.Add(mission);
            await _context.SaveChangesAsync();

            return Ok(mission);
        }

        //  Supprimer une mission
        [HttpDelete("{id}")]
        [AllowAnonymous] // On laisse passer le site Web
        public async Task<IActionResult> DeleteMissionForAdmin(int id)
        {
            // 1. On cherche la mission dans la base de données
            var mission = await _context.Missions.FindAsync(id);

            // 2. Si elle n'existe pas, on renvoie une erreur 404
            if (mission == null)
            {
                return NotFound();
            }

            // 3. On la supprime et on sauvegarde
            _context.Missions.Remove(mission);
            await _context.SaveChangesAsync();

            return Ok();
        }
    }
}

