using FitnessFox.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json; // Tu devras peut-être installer ce package NuGet
using System.Text;

namespace FitnessFox.Web.Controllers
{
    public class MissionsController : Controller
    {
        // L'adresse de ton API (vérifie le port 5045 ou autre !)
        private readonly string _apiBaseUrl = "http://localhost:5045/api/Missions";
        private readonly HttpClient _client;

        public MissionsController()
        {
            _client = new HttpClient();
        }

        // 1. AFFICHER LA LISTE (GET)
        public async Task<IActionResult> Index()
        {
            List<Mission> missions = new List<Mission>();

            // On appelle l'API
            HttpResponseMessage response = await _client.GetAsync(_apiBaseUrl);

            if (response.IsSuccessStatusCode)
            {
                // On lit le résultat
                string data = await response.Content.ReadAsStringAsync();
                // On transforme le texte JSON en liste de Missions C#
                missions = JsonConvert.DeserializeObject<List<Mission>>(data);
            }

            return View(missions);
        }

        // 2. AFFICHER LE FORMULAIRE DE CRÉATION
        public IActionResult Create()
        {
            return View();
        }

        // 3. ENVOYER LA NOUVELLE MISSION (POST)
        [HttpPost]
        public async Task<IActionResult> Create(Mission mission)
        {
            // On force l'ID à 0 et non complété
            mission.Id = 0;
            mission.IsCompleted = false;

            string json = JsonConvert.SerializeObject(mission);
            StringContent content = new StringContent(json, Encoding.UTF8, "application/json");

            await _client.PostAsync(_apiBaseUrl, content);

            return RedirectToAction(nameof(Index));
        }

        // 4. SUPPRIMER UNE MISSION
        public async Task<IActionResult> Delete(int id)
        {
            await _client.DeleteAsync($"{_apiBaseUrl}/{id}");
            return RedirectToAction(nameof(Index));
        }
    }
}