using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VulpiFit.API.Data;
using VulpiFit.API.Models;
using VulpiFit.API.Services;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

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

        public MissionsController(
            ApplicationDbContext context,
            GroqService groqService,
            CoopStreakService coopStreakService)
        {
            _context = context;
            _groqService = groqService;
            _coopStreakService = coopStreakService;
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

            //  On passe l'historique à notre GroqService
            var newMissions = await _groqService.GenerateDailyMissionsAsync(user, recentLogs);

            // Plan de secours : Si Groq a un bug réseau
            if (newMissions == null || !newMissions.Any())
            {
                Console.WriteLine("⚠️ Échec IA : Utilisation des missions de secours.");
                newMissions = new List<Mission>
                {
                    new Mission { Title = "Boire 2L d'eau aujourd'hui", Type = "Nutrition", Points = 10 },
                    new Mission { Title = "Faire 15 minutes de marche active", Type = "Sport", Points = 15 },
                    new Mission { Title = "Faire 3 minutes de respiration profonde", Type = "Mental", Points = 10 }
                };
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

