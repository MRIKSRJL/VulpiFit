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
            // 1. On récupère l'utilisateur pour voir sa dernière date d'activité
            var user = await _context.Users.FindAsync(1);

            // 2. LE TEST DU MATIN ☀️
            // Si l'utilisateur existe ET qu'il a joué avant (Date non nulle) ET que sa dernière activité n'est pas "Aujourd'hui"
            if (user != null && user.LastActivityDate != null && user.LastActivityDate.Value.Date < DateTime.Now.Date)
            {
                // C'est un nouveau jour ! On doit nettoyer les missions cochées la veille.

                var allMissions = await _context.Missions.ToListAsync();
                bool nettoyageEffectue = false;

                foreach (var mission in allMissions)
                {
                    // Si une mission est restée cochée, on la décoche
                    if (mission.IsCompleted)
                    {
                        mission.IsCompleted = false;
                        nettoyageEffectue = true;
                    }
                }

                // Si on a nettoyé quelque chose, on sauvegarde les changements
                if (nettoyageEffectue)
                {
                    await _context.SaveChangesAsync();
                }
            }

            // 3. Maintenant que c'est propre, on envoie la liste !
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

            // On récupère l'utilisateur (ID 1 pour l'instant)
            var user = await _context.Users.FindAsync(1);
            if (user == null) return NotFound("Utilisateur introuvable");

            // Sécurité anti-spam
            if (mission.IsCompleted) return Ok(new { newScore = user.Score });

            // --- 📅 LOGIQUE DES STREAKS (Séries) ---
            DateTime today = DateTime.Now.Date; // La date d'aujourd'hui (sans l'heure)

            // Si c'est la toute première fois qu'il joue
            if (user.LastActivityDate == null)
            {
                user.CurrentStreak = 1;
            }
            else
            {
                DateTime lastDate = user.LastActivityDate.Value.Date;

                if (lastDate == today)
                {
                    // Il a déjà joué aujourd'hui : On ne change pas la streak
                }
                else if (lastDate == today.AddDays(-1))
                {
                    // Il a joué hier : BRAVO ! La série continue 🔥
                    user.CurrentStreak++;
                }
                else
                {
                    // Il a raté hier (ou plus) : DOMMAGE ! Retour à 1 😭
                    user.CurrentStreak = 1;
                }
            }

            // On met à jour la date de dernière activité
            user.LastActivityDate = today;
            // -----------------------------------------

            // Mise à jour classique des points
            user.Score += mission.Points;
            user.TotalMissionsCompleted++;
            mission.IsCompleted = true;

            await _context.SaveChangesAsync();

            // 👇 On renvoie aussi la streak au téléphone pour l'afficher !
            return Ok(new { newScore = user.Score, newStreak = user.CurrentStreak });
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