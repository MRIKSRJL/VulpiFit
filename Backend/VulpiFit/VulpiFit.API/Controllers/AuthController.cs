using VulpiFit.API.Data;
using VulpiFit.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BCrypt.Net;

namespace VulpiFit.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public AuthController(ApplicationDbContext context)
        {
            _context = context;
        }

        // 1. INSCRIPTION SÉCURISÉE
        [HttpPost("register")]
        public async Task<ActionResult<User>> Register(User user)
        {
            if (await _context.Users.AnyAsync(u => u.Pseudo == user.Pseudo))
            {
                return BadRequest("Ce pseudo est déjà pris ! 🦊❌");
            }

            // 👇 LA MAGIE EST ICI : On hache le mot de passe avant de sauvegarder
            string passwordHash = BCrypt.Net.BCrypt.HashPassword(user.Password);
            user.Password = passwordHash;

            // Initialisation des stats
            user.Score = 0;
            user.TotalMissionsCompleted = 0;
            user.CurrentStreak = 0;
            user.LastActivityDate = DateTime.Now;

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(user);
        }

        // 2. CONNEXION SÉCURISÉE
        [HttpPost("login")]
        public async Task<ActionResult<User>> Login(User loginRequest)
        {
            // On cherche l'utilisateur par son Pseudo (pas encore le mot de passe)
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Pseudo == loginRequest.Pseudo);

            // Si l'utilisateur n'existe pas
            if (user == null)
            {
                return Unauthorized("Pseudo ou mot de passe incorrect ! ⛔");
            }

            // 👇 VÉRIFICATION DU HASH : On compare le mot de passe donné avec le hash en BDD
            // (loginRequest.Password = "1234", user.Password = "$2a$11$...")
            if (!BCrypt.Net.BCrypt.Verify(loginRequest.Password, user.Password))
            {
                return Unauthorized("Pseudo ou mot de passe incorrect ! ⛔");
            }

            return Ok(user);
        }
    }
}