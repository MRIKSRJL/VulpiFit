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
            // 1. On vérifie si ce pseudo existe déjà !
            var pseudoExiste = await _context.Users
                .AnyAsync(u => u.Pseudo.ToLower() == user.Pseudo.ToLower());

            if (pseudoExiste)
            {
                // Si le profil existe, on refuse la création et on prévient Flutter
                return BadRequest("Ce pseudo est déjà pris !");
            }

            // 2. On s'assure que le nouveau compte est tout propre (anti-triche)
            user.Score = 0;
            user.CurrentStreak = 0;
            user.TotalMissionsCompleted = 0;
            user.LastActivityDate = null; // Aucune mission faite pour l'instant

            // 3. On sauvegarde dans la base
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetUsers", new { id = user.Id }, user);
        }
    }
}