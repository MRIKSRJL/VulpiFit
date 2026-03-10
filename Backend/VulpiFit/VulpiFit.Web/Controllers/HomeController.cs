using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using System.Text.Json;
using VulpiFit.Models;
using VulpiFit.Web.Models; // Assure-toi que ce namespace est le bon

namespace VulpiFit.Controllers
{
    public class HomeController : Controller
    {
        // On remet l'adresse technique de ton API Azure
        private readonly string _apiUrl = "https://fitnessfoxapi20260301200033-agegbhcpfqdvhaep.canadacentral-01.azurewebsites.net/api/Users";

        // L'action Index() est celle qui se lance quand on arrive sur la page d'accueil
        public async Task<IActionResult> Index()
        {
            List<UserViewModel> users = new List<UserViewModel>();

            using (var client = new HttpClient())
            {
                // Le site web fait une requête GET à ton API
                var response = await client.GetAsync(_apiUrl);

                if (response.IsSuccessStatusCode)
                {
                    // Si l'API répond 200 OK, on lit le JSON
                    var jsonString = await response.Content.ReadAsStringAsync();

                    // On transforme le JSON en liste d'objets C#
                    users = JsonSerializer.Deserialize<List<UserViewModel>>(jsonString, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                }
                else
                {
                    // En cas d'erreur (ex: 401 ou 404), on prévient la Vue
                    ViewBag.ErrorMessage = $"Erreur lors de la récupération des données : {response.StatusCode}";
                }
            }

            // On envoie la liste des utilisateurs à la page web (la Vue)
            return View(users);
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}