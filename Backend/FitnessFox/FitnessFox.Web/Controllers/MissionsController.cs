using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering; // Pour la liste déroulante
using Microsoft.EntityFrameworkCore;        // Pour ToListAsync
using FitnessFox.Web.Data;                  // Pour ApplicationDbContext
using FitnessFox.Web.Models;                // Pour Mission

namespace FitnessFox.Web.Controllers
{
    public class MissionsController : Controller
    {
        // 👇 ICI : On déclare la connexion à la base de données
        private readonly ApplicationDbContext _context;

        // 👇 LE CONSTRUCTEUR : On injecte la connexion
        public MissionsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // 1. AFFICHER LA LISTE (GET)
        public async Task<IActionResult> Index()
        {
            // On demande directement à la base de données, plus besoin d'API ici !
            return View(await _context.Missions.ToListAsync());
        }

        // 2. AFFICHER LE FORMULAIRE (GET)
        public IActionResult Create()
        {
            // On charge la liste des joueurs pour le menu déroulant
            // Si _context est souligné en rouge ici avant, maintenant ça marchera !
            ViewData["Users"] = new SelectList(_context.Users, "Id", "Pseudo");
            return View();
        }

        // 3. ENREGISTRER LA MISSION (POST)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Mission mission)
        {
            // On force les valeurs par défaut
            mission.IsCompleted = false;

            // On sauvegarde dans la base V5
            _context.Add(mission);
            await _context.SaveChangesAsync();

            return RedirectToAction(nameof(Index));
        }

        // 4. SUPPRIMER (Bonus : version BDD)
        public async Task<IActionResult> Delete(int id)
        {
            var mission = await _context.Missions.FindAsync(id);
            if (mission != null)
            {
                _context.Missions.Remove(mission);
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }
    }
}