using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitnessFox.API.Data;
using FitnessFox.API.Models;
using FitnessFox.API.Services;

namespace FitnessFox.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MissionsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly GroqService _groqService;

        // On injecte le service IA proprement
        public MissionsController(ApplicationDbContext context, GroqService groqService)
        {
            _context = context;
            _groqService = groqService; // ✅ Maintenant ça pointe vers le bon objet !
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

            // 2. CRÉATION PAR L'IA
            Console.WriteLine($"🚀 Génération de missions IA pour le joueur {user.Pseudo}...");
            var newMissions = await _groqService.GenerateDailyMissionsAsync(user);

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
            var mission = await _context.Missions.FirstOrDefaultAsync(m => m.Id == id && m.UserId == userId);
            if (mission == null) return NotFound();

            if (!mission.IsCompleted)
            {
                mission.IsCompleted = true;

                var user = await _context.Users.FindAsync(userId);
                if (user != null)
                {
                    user.Score += mission.Points;
                    user.TotalMissionsCompleted += 1;
                }
                await _context.SaveChangesAsync();
            }
            return Ok();
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
    }
}