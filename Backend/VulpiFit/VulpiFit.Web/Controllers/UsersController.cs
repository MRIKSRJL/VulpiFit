using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using VulpiFit.Web.Models;

namespace VulpiFit.Web.Controllers
{
    public class UsersController : Controller
    {
        // On pointe vers ton vrai serveur Azure
        private readonly string _apiUsersUrl = "https://fitnessfoxapi20260301200033-agegbhcpfqdvhaep.canadacentral-01.azurewebsites.net/api/Users";
        private readonly JsonSerializerOptions _jsonOptions = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

        public async Task<IActionResult> Index()
        {
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

            return View(users);
        }
    }
}