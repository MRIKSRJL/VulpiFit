using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitnessFox.API.Data;
using FitnessFox.API.Models;

namespace FitnessFox.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public UsersController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/Users 
        [HttpGet]
        public async Task<ActionResult<IEnumerable<User>>> GetUsers()
        {
            return await _context.Users.ToListAsync();
        }

        // POST: api/Users (Création d'un compte)
        [HttpPost]
        public async Task<ActionResult<User>> PostUser(User user)
        {
            var pseudoExiste = await _context.Users.AnyAsync(u => u.Pseudo.ToLower() == user.Pseudo.ToLower());
            if (pseudoExiste) return BadRequest("Ce pseudo est déjà pris !");

            user.Score = 0;
            user.CurrentStreak = 0;
            user.TotalMissionsCompleted = 0;
            user.LastActivityDate = null;

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetUsers", new { id = user.Id }, user);
        }

        // 👇 LA ROUTE ONBOARDING EST BIEN ICI !
        // PUT: api/Users/{id}/onboarding
        [HttpPut("{id}/onboarding")]
        public async Task<IActionResult> UpdateOnboarding(int id, [FromBody] UserOnboardingDto onboardingData)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound("Utilisateur introuvable.");

            user.Weight = onboardingData.Weight;
            user.Height = onboardingData.Height;
            user.Injuries = onboardingData.Injuries;
            user.Goals = onboardingData.Goals;

            await _context.SaveChangesAsync();
            return Ok("Profil mis à jour pour l'IA !");
        }
    }

    // 👇 LE DTO (LE MOULE) EST PLACÉ ICI À LA FIN
    public class UserOnboardingDto
    {
        public float Weight { get; set; }
        public int Height { get; set; }
        public string? Injuries { get; set; }
        public string? Goals { get; set; }
    }
}