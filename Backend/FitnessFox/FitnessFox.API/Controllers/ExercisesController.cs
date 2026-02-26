using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitnessFox.API.Data;
using FitnessFox.API.Models;
using Microsoft.AspNetCore.Authorization;

namespace FitnessFox.API.Controllers
{
    [Authorize] // 🛡️ On garde notre vigile de sécurité !
    [Route("api/[controller]")]
    [ApiController]
    public class ExercisesController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ExercisesController(ApplicationDbContext context)
        {
            _context = context;
        }

        // POST: api/Exercises/log
        // Permet au téléphone d'enregistrer une performance
        [HttpPost("log")]
        public async Task<IActionResult> LogExercise([FromBody] ExerciseLogRequest request)
        {
            var log = new ExerciseLog
            {
                UserId = request.UserId,
                ExerciseName = request.ExerciseName,
                Weight = request.Weight,
                Reps = request.Reps,
                Date = DateTime.UtcNow
            };

            _context.ExerciseLogs.Add(log);
            await _context.SaveChangesAsync();

            return Ok(log);
        }

        // GET: api/Exercises/history/5
        // Permet à l'IA ou au téléphone de récupérer les performances passées
        [HttpGet("history/{userId}")]
        public async Task<IActionResult> GetUserHistory(int userId)
        {
            var history = await _context.ExerciseLogs
                .Where(e => e.UserId == userId)
                .OrderByDescending(e => e.Date)
                .Take(50) // On prend les 50 dernières séries pour ne pas surcharger la mémoire
                .ToListAsync();

            return Ok(history);
        }
    }

    // Le "moule" pour recevoir les données du téléphone
    public class ExerciseLogRequest
    {
        public int UserId { get; set; }
        public string ExerciseName { get; set; } = string.Empty;
        public float Weight { get; set; }
        public int Reps { get; set; }
    }
}