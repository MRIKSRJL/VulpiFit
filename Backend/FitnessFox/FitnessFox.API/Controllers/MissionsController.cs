using FitnessFox.API.Data;
using FitnessFox.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FitnessFox.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MissionsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public MissionsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // 1. RÉCUPÉRER LES MISSIONS (Adapté à l'utilisateur)
        // On demande : "Donne-moi les missions et dis-moi si l'utilisateur X les a faites aujourd'hui"
        [HttpGet("{userId}")]
        public async Task<ActionResult<IEnumerable<Mission>>> GetMissionsForUser(int userId)
        {
            var today = DateTime.Today;

            // 👇 LA MODIF EST ICI : FILTRAGE
            // On prend les missions assignées à cet utilisateur (UserId == userId)
            // OU les missions globales (UserId == null)
            var userMissions = await _context.Missions
                .Where(m => m.UserId == userId || m.UserId == null)
                .ToListAsync();

            // Le reste ne change pas (vérification si déjà fait aujourd'hui)
            var doneTodayIds = await _context.MissionLogs
                .Where(log => log.UserId == userId && log.DateCompleted.Date == today)
                .Select(log => log.MissionId)
                .ToListAsync();

            foreach (var mission in userMissions)
            {
                mission.IsCompleted = doneTodayIds.Contains(mission.Id);
            }

            return userMissions;
        }

        [HttpPost("Complete/{id}")]
        public async Task<IActionResult> CompleteMission(int id, [FromQuery] int userId)
        {
            // 1. On cherche la mission
            var mission = await _context.Missions.FindAsync(id);
            if (mission == null)
            {
                // Si elle renvoie ça, c'est que la mission n'existe pas dans la table
                return NotFound($"ERREUR : La mission avec l'ID {id} est introuvable en base.");
            }

            var today = DateTime.Today;

            var alreadyDone = await _context.MissionLogs
                .AnyAsync(log => log.MissionId == id && log.UserId == userId && log.DateCompleted.Date == today);

            if (alreadyDone)
            {
                return BadRequest("ERREUR : Mission déjà accomplie aujourd'hui.");
            }

            // 2. On enregistre le log
            var log = new MissionLog
            {
                MissionId = id,
                UserId = userId,
                DateCompleted = DateTime.Now
            };
            _context.MissionLogs.Add(log);

            // 3. On met à jour l'utilisateur
            var user = await _context.Users.FindAsync(userId);
            if (user != null)
            {
                user.Score += mission.Points;
                user.TotalMissionsCompleted += 1;

                if (user.LastActivityDate == null)
                {
                    user.CurrentStreak = 1;
                }
                else if (user.LastActivityDate.Value.Date == today.AddDays(-1))
                {
                    user.CurrentStreak += 1;
                }
                else if (user.LastActivityDate.Value.Date < today.AddDays(-1))
                {
                    user.CurrentStreak = 1;
                }

                user.LastActivityDate = DateTime.Now;
            }
            else
            {
                return NotFound($"ERREUR : L'utilisateur avec l'ID {userId} est introuvable.");
            }

            await _context.SaveChangesAsync();

            // 200 OK avec un message de succès
            return Ok("Mission validée avec succès !");
        }
        [HttpPost("Undo/{id}")]
        public async Task<IActionResult> UndoMission(int id, [FromQuery] int userId)
        {
            var today = DateTime.Today;

            // On cherche le log d'aujourd'hui
            var log = await _context.MissionLogs
                .FirstOrDefaultAsync(l => l.MissionId == id && l.UserId == userId && l.DateCompleted.Date == today);

            if (log == null) return NotFound("Aucune validation trouvée pour aujourd'hui.");

            // 1. On supprime la trace dans le journal
            _context.MissionLogs.Remove(log);

            // 👇 2. ON RETIRE LES POINTS AU JOUEUR 👇
            var mission = await _context.Missions.FindAsync(id);
            var user = await _context.Users.FindAsync(userId);

            if (mission != null && user != null)
            {
                // On retire les points (sans descendre en dessous de 0)
                user.Score = Math.Max(0, user.Score - mission.Points);

                // On retire 1 au compteur global
                user.TotalMissionsCompleted = Math.Max(0, user.TotalMissionsCompleted - 1);

                // Note: L'annulation du Streak est plus complexe, 
                // généralement on le laisse tel quel s'il annule une mission.
            }

            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}