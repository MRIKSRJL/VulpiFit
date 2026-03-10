using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VulpiFit.API.Data;
using VulpiFit.API.Models;
using VulpiFit.API.Services;
using Microsoft.AspNetCore.Authorization;

namespace VulpiFit.API.Controllers
{
    [Authorize] // 👈 Le vigile est toujours là !
    [Route("api/[controller]")]
    [ApiController]
    public class MissionsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly GroqService _groqService;

        public MissionsController(ApplicationDbContext context, GroqService groqService)
        {
            _context = context;
            _groqService = groqService;
        }

        // GET: api/Missions/5
        [HttpGet("{userId}")]
        public async Task<ActionResult<IEnumerable<Mission>>> GetMissionsForUser(int userId)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("Utilisateur non trouvé.");

            var today = DateTime.Today;

            // 1. VÉRIFICATION : Est-ce qu'on a déjà généré les missions aujourd'hui ?
            var dailyMissions = await _context.Missions
                .Where(m => m.UserId == userId && m.AssignedDate.Date == today)
                .ToListAsync();

            if (dailyMissions.Any())
            {
                return Ok(dailyMissions);
            }

            // 2. CRÉATION PAR L'IA AVEC HISTORIQUE 🧠
            Console.WriteLine($"🚀 Génération de missions IA pour le joueur {user.Pseudo}...");

            // 👇 NOUVEAU : On récupère les 15 dernières performances (Poids/Reps) du joueur
            var recentLogs = await _context.ExerciseLogs
                .Where(e => e.UserId == userId)
                .OrderByDescending(e => e.Date)
                .Take(15)
                .ToListAsync();

            // 👇 NOUVEAU : On passe l'historique à notre GroqService
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

        // POST: api/Missions/Complete/5?userId=1
        [HttpPost("Complete/{id}")]
        public async Task<IActionResult> CompleteMission(int id, [FromQuery] int userId)
        {
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

                    // 2. LOGIQUE DE LA STREAK (SÉRIE DE JOURS)
                    var today = DateTime.UtcNow.Date;
                    var lastActivity = user.LastActivityDate?.Date;

                    if (lastActivity == today.AddDays(-1))
                    {
                        user.CurrentStreak += 1;
                    }
                    else if (lastActivity == today)
                    {
                        if (user.CurrentStreak == 0)
                        {
                            user.CurrentStreak = 1;
                        }
                    }
                    else
                    {
                        user.CurrentStreak = 1;
                    }

                    // 3. On met à jour la date de dernière activité
                    user.LastActivityDate = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();
            }

            return Ok(mission);
        }

        // POST: api/Missions/Undo/5?userId=1
        [HttpPost("Undo/{id}")]
        public async Task<IActionResult> UndoMission(int id, [FromQuery] int userId)
        {
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
        // 🚨 ROUTE SPÉCIALE POUR LE SITE WEB ADMIN (MVC)
        [HttpGet]
        [AllowAnonymous] // Ce badge magique dit au videur de laisser passer la requête sans Token VIP
        public async Task<ActionResult<IEnumerable<Mission>>> GetAllMissionsForAdmin()
        {
            // L'API va chercher toutes les missions dans la base de données et les donne au site Web
            return await _context.Missions.ToListAsync();
        }
    }
}