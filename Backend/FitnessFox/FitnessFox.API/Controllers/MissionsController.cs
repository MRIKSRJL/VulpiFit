using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitnessFox.API.Data;
using FitnessFox.API.Models;

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

        // 1. GET: api/missions (Pour afficher la liste)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Mission>>> GetMissions()
        {
            return await _context.Missions.ToListAsync();
        }

        // 2. POST: api/missions (Pour créer une mission)
        [HttpPost]
        public async Task<ActionResult<Mission>> PostMission(Mission mission)
        {
            _context.Missions.Add(mission);
            await _context.SaveChangesAsync();
            return CreatedAtAction("GetMissions", new { id = mission.Id }, mission);
        }

        // 3. POST: api/missions/{id}/complete (VALIDER ✅)
        [HttpPost("{id}/complete")]
        public async Task<IActionResult> CompleteMission(int id)
        {
            var mission = await _context.Missions.FindAsync(id);
            if (mission == null) return NotFound("Mission introuvable");

            var user = await _context.Users.FindAsync(1);
            if (user == null) return NotFound("Utilisateur introuvable");

            // Si elle est déjà faite, on ne fait rien (pour éviter de tricher en cliquant 100 fois)
            if (mission.IsCompleted) return Ok(new { newScore = user.Score });

            // 1. On met à jour le score
            user.Score += mission.Points;
            user.TotalMissionsCompleted++;

            // 2. On marque la mission comme FAITE dans la base de données
            mission.IsCompleted = true; // 👈 C'EST CA QUI MANQUAIT !

            await _context.SaveChangesAsync();
            return Ok(new { newScore = user.Score });
        }

        // 4. POST: api/missions/{id}/undo (ANNULER ↩️)
        [HttpPost("{id}/undo")]
        public async Task<IActionResult> UndoMission(int id)
        {
            Console.WriteLine($"--- TENTATIVE ANNULATION MISSION {id} ---"); // 👀 Espion

            var mission = await _context.Missions.FindAsync(id);
            if (mission == null) return NotFound("Mission introuvable");

            var user = await _context.Users.FindAsync(1);
            if (user == null) return NotFound("Utilisateur introuvable");

            Console.WriteLine($"État actuel en base de données : IsCompleted = {mission.IsCompleted}"); // 👀 Espion

            // Si elle n'est pas faite, on ne peut pas l'annuler
            if (!mission.IsCompleted)
            {
                Console.WriteLine("ANNULATION REJETÉE : La mission est déjà considérée comme non-faite."); // 👀 Espion
                return Ok(new { newScore = user.Score });
            }

            // 1. On retire les points
            user.Score -= mission.Points;
            user.TotalMissionsCompleted--;

            if (user.Score < 0) user.Score = 0;
            if (user.TotalMissionsCompleted < 0) user.TotalMissionsCompleted = 0;

            // 2. On marque la mission comme NON FAITE
            mission.IsCompleted = false;

            await _context.SaveChangesAsync();

            Console.WriteLine($"SUCCÈS : Points retirés et IsCompleted passé à FALSE."); // 👀 Espion
            Console.WriteLine("-------------------------------------------");

            return Ok(new { newScore = user.Score });
        }
        // 👇 BOUTON D'URGENCE : Remet tout à zéro
        [HttpPost("reset-all")]
        public async Task<IActionResult> ResetAll()
        {
            // 1. Remettre le score du joueur à 0
            var user = await _context.Users.FindAsync(1);
            if (user != null)
            {
                user.Score = 0;
                user.TotalMissionsCompleted = 0;
            }

            // 2. Décocher toutes les missions
            var missions = await _context.Missions.ToListAsync();
            foreach (var mission in missions)
            {
                mission.IsCompleted = false;
            }

            await _context.SaveChangesAsync();
            return Ok("🔄 Tout est remis à zéro ! Score: 0, Missions: 0");
        }
    }
}