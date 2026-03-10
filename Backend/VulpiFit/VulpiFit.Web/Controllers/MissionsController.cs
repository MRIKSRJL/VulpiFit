using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Text;
using System.Text.Json;
using VulpiFit.Web.Models; // Vérifie bien que c'est le namespace de ton projet

namespace VulpiFit.Web.Controllers
{
    public class MissionsController : Controller
    {
        // 🌐 Les adresses de ton API Azure
        private readonly string _apiMissionsUrl = "https://fitnessfoxapi20260301200033-agegbhcpfqdvhaep.canadacentral-01.azurewebsites.net/api/Missions";
        private readonly string _apiUsersUrl = "https://fitnessfoxapi20260301200033-agegbhcpfqdvhaep.canadacentral-01.azurewebsites.net/api/Users";
        private readonly JsonSerializerOptions _jsonOptions = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

        // 1. AFFICHER LA LISTE (GET)
        public async Task<IActionResult> Index()
        {
            List<Mission> missions = new List<Mission>();
            using (var client = new HttpClient())
            {
                var response = await client.GetAsync(_apiMissionsUrl);
                if (response.IsSuccessStatusCode)
                {
                    var jsonString = await response.Content.ReadAsStringAsync();
                    missions = JsonSerializer.Deserialize<List<Mission>>(jsonString, _jsonOptions);
                }
            }
            return View(missions);
        }

        // 2. AFFICHER LE FORMULAIRE (GET)
        public async Task<IActionResult> Create()
        {
            // On récupère la liste des utilisateurs via l'API pour le menu déroulant
            List<User> users = new List<User>();
            using (var client = new HttpClient())
            {
                var response = await client.GetAsync(_apiUsersUrl);
                if (response.IsSuccessStatusCode)
                {
                    var jsonString = await response.Content.ReadAsStringAsync();
                    users = JsonSerializer.Deserialize<List<User>>(jsonString, _jsonOptions);
                }
            }

            ViewData["Users"] = new SelectList(users, "Id", "Pseudo");
            return View();
        }

        // 3. ENREGISTRER LA MISSION (POST)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Mission mission)
        {
            mission.IsCompleted = false;

            using (var client = new HttpClient())
            {
                // On transforme l'objet mission en texte JSON
                var jsonContent = new StringContent(JsonSerializer.Serialize(mission), Encoding.UTF8, "application/json");

                // On l'envoie à l'API !
                var response = await client.PostAsync(_apiMissionsUrl, jsonContent);

                if (response.IsSuccessStatusCode)
                {
                    return RedirectToAction(nameof(Index));
                }
            }

            // En cas d'échec, on réaffiche le formulaire
            return View(mission);
        }

        // 4. SUPPRIMER (via l'API)
        public async Task<IActionResult> Delete(int id)
        {
            using (var client = new HttpClient())
            {
                // On demande à l'API de supprimer la mission
                await client.DeleteAsync($"{_apiMissionsUrl}/{id}");
            }
            return RedirectToAction(nameof(Index));
        }
    }
}