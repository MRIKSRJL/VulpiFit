using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitnessFox.API.Data;
using FitnessFox.API.Models;
using BCrypt.Net;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using System.Text;

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

            // 🛡️ NOUVEAUTÉ SÉCURITÉ : On crypte le mot de passe avant de le sauvegarder !
            if (!string.IsNullOrEmpty(user.Password))
            {
                user.Password = BCrypt.Net.BCrypt.HashPassword(user.Password);
            }

            user.Score = 0;
            user.CurrentStreak = 0;
            user.TotalMissionsCompleted = 0;
            user.LastActivityDate = null;

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetUsers", new { id = user.Id }, user);
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Pseudo.ToLower() == request.Pseudo.ToLower());
            if (user == null) return Unauthorized("Pseudo ou mot de passe incorrect.");

            bool isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.Password);
            if (!isPasswordValid) return Unauthorized("Pseudo ou mot de passe incorrect.");

            // 🎟️ FABRICATION DU BRACELET VIP (JWT)
            var jwtKey = "LaCleSecreteDeFitnessFoxSuperLongueEtSecurisee2026!"; // La même que dans Program.cs
            var keyBytes = Encoding.UTF8.GetBytes(jwtKey);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                // Ce que contient le bracelet (l'ID du joueur)
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Pseudo)
                }),
                Expires = DateTime.UtcNow.AddDays(7), // Valable 7 jours
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(keyBytes), SecurityAlgorithms.HmacSha256Signature)
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            var jwtString = tokenHandler.WriteToken(token);

            // On renvoie le bracelet (token) ET les infos de l'utilisateur
            return Ok(new { Token = jwtString, User = user });
        }

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

        [HttpPost("{userId}/feedback")]
        public async Task<IActionResult> SaveDailyFeedback(int userId, [FromBody] FeedbackRequest request)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound();

            // 1. On met à jour l'état actuel
            user.LastFeedback = request.FeedbackText;
            user.LastDifficulty = request.DifficultyLevel;

            // 2. 📸 ON PREND LA PHOTO POUR LA ROADMAP !
            var dailyLog = new UserProgressLog
            {
                UserId = user.Id,
                Date = DateTime.UtcNow,
                Weight = user.Weight ?? 0, // Ou une valeur par défaut
                TotalScore = user.Score
            };
            _context.UserProgressLogs.Add(dailyLog);

            await _context.SaveChangesAsync();
            return Ok();
        }

        [HttpGet("{userId}/progress")]
        public async Task<IActionResult> GetUserProgress(int userId)
        {
            // On récupère tout l'historique du joueur, trié du plus ancien au plus récent
            var logs = await _context.UserProgressLogs
                .Where(l => l.UserId == userId)
                .OrderBy(l => l.Date)
                .ToListAsync();

            return Ok(logs);
        }

        // 👇 NOUVELLE MISSION : Le droit à l'oubli
        // DELETE: api/Users/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            // 1. On cherche l'utilisateur dans la base de données
            var user = await _context.Users.FindAsync(id);

            // 2. Si on ne le trouve pas, on renvoie une erreur 404
            if (user == null)
            {
                return NotFound(new { message = "Utilisateur introuvable." });
            }

            // 3. Si on le trouve, on donne l'ordre de le supprimer
            _context.Users.Remove(user);

            // 4. On sauvegarde la modification dans le Cloud Azure
            await _context.SaveChangesAsync();

            // 5. On renvoie un code 204 (No Content) pour dire que tout s'est bien passé
            return NoContent();
        }

        // --- CLASSES DTO (Moules de données) ---

        public class FeedbackRequest
        {
            public string FeedbackText { get; set; } = "";
            public int DifficultyLevel { get; set; }
        }

        public class LoginRequest
        {
            public string Pseudo { get; set; } = "";
            public string Password { get; set; } = "";
        }
    }

    public class UserOnboardingDto
    {
        public float Weight { get; set; }
        public int Height { get; set; }
        public string? Injuries { get; set; }
        public string? Goals { get; set; }
    }
}