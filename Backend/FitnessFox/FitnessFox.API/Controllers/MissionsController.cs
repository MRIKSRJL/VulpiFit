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

            // On prend l'utilisateur ID 1 (Toi)
            var user = await _context.Users.FindAsync(1);
            if (user == null) return NotFound("Utilisateur introuvable");

            // On ajoute les points
            user.Score += mission.Points;
            user.TotalMissionsCompleted++;

            await _context.SaveChangesAsync();
            return Ok(new { newScore = user.Score });
        }

        // 4. POST: api/missions/{id}/undo (ANNULER ↩️)
        [HttpPost("{id}/undo")]
        public async Task<IActionResult> UndoMission(int id)
        {
            var mission = await _context.Missions.FindAsync(id);
            if (mission == null) return NotFound("Mission introuvable");

            var user = await _context.Users.FindAsync(1);
            if (user == null) return NotFound("Utilisateur introuvable");

            // On enlève les points
            user.Score -= mission.Points;
            user.TotalMissionsCompleted--;

            // Sécurité : pas de score négatif
            if (user.Score < 0) user.Score = 0;
            if (user.TotalMissionsCompleted < 0) user.TotalMissionsCompleted = 0;

            await _context.SaveChangesAsync();
            return Ok(new { newScore = user.Score });
        }
    }
}