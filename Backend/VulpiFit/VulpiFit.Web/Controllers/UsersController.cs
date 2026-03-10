using VulpiFit.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;

namespace VulpiFit.Web.Controllers
{
    public class UsersController : Controller
    {
        private readonly string _apiBaseUrl = "http://localhost:5045/api/Users"; // Vérifie ton port !
        private readonly HttpClient _client;

        public UsersController()
        {
            _client = new HttpClient();
        }

        public async Task<IActionResult> Index()
        {
            List<User> users = new List<User>();
            HttpResponseMessage response = await _client.GetAsync(_apiBaseUrl);

            if (response.IsSuccessStatusCode)
            {
                string data = await response.Content.ReadAsStringAsync();
                users = JsonConvert.DeserializeObject<List<User>>(data);
            }

            return View(users);
        }
    }
}