using System.Text;
using System.Text.Json;
using FitnessFox.API.Models;

namespace FitnessFox.API.Services
{
    public class GroqService
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;

        public GroqService(HttpClient httpClient, IConfiguration config)
        {
            _httpClient = httpClient;
            _apiKey = config["GroqApiKey"] ?? "";
        }

        public async Task<List<Mission>> GenerateDailyMissionsAsync(User user)
        {
            if (string.IsNullOrEmpty(_apiKey) || _apiKey == "TA_CLE_GROQ_GSK_ICI")
            {
                Console.WriteLine("🛑 ERREUR CRITIQUE : La clé API Groq est introuvable !");
                return new List<Mission>();
            }

            var prompt = $@"Tu es Fitness Fox, un coach sportif et bien-être virtuel.
Génère 3 missions quotidiennes personnalisées (exactement 1 'Sport', 1 'Nutrition', et 1 'Mental') pour cet utilisateur :
- Objectif : {user.Goals ?? "Garder la forme"}
- Poids : {user.Weight} kg
- Taille : {user.Height} cm
- Blessures : {user.Injuries ?? "Aucune"}";

            // 👇 LA NOUVELLE INTELLIGENCE EST ICI
            if (!string.IsNullOrEmpty(user.LastFeedback))
            {
                prompt += $@"
- RETOUR D'HIER : L'utilisateur a laissé ce commentaire : ""{user.LastFeedback}"". 
- DIFFICULTÉ RESSENTIE HIER : {user.LastDifficulty}/10. 
ADAPTATION OBLIGATOIRE : Si la note est haute (8-10), rends les missions d'aujourd'hui plus faciles. Si la note est basse (1-4), augmente un peu le défi. Prends en compte son commentaire texte pour ajuster les exercices.";
            }

            prompt += @"
Réponds UNIQUEMENT avec un tableau JSON valide. Ne mets aucun texte avant ou après. N'utilise pas de balises markdown.
Utilise les propriétés : Title, Type, Points.
Types autorisés : Sport, Nutrition, Mental.
Points : 10 à 50. Adapte les missions aux blessures.

Exemple :
[
  { ""Title"": ""Faire 10 pompes adaptées"", ""Type"": ""Sport"", ""Points"": 20 },
  { ""Title"": ""Boire 2 verres d'eau"", ""Type"": ""Nutrition"", ""Points"": 10 },
  { ""Title"": ""5 minutes de méditation"", ""Type"": ""Mental"", ""Points"": 15 }
]";

            var requestBody = new
            {
                model = "llama-3.3-70b-versatile",
                messages = new[] { new { role = "user", content = prompt } },
                temperature = 0.7
            };

            var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

            // 👇 LA MÉTHODE PROPRE ET BLINDÉE
            using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.groq.com/openai/v1/chat/completions");
            request.Headers.Add("Authorization", $"Bearer {_apiKey}");
            request.Content = content;

            try
            {
                Console.WriteLine("\n=== PROMPT ENVOYÉ À L'IA ==\n" + prompt + "\n===========================\n");
                var response = await _httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    var error = await response.Content.ReadAsStringAsync();
                    Console.WriteLine($"❌ Erreur API Groq : {error}");
                    return new List<Mission>();
                }

                var jsonResponse = await response.Content.ReadAsStringAsync();

                using var document = JsonDocument.Parse(jsonResponse);
                var root = document.RootElement;
                var generatedText = root.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString();

                if (!string.IsNullOrEmpty(generatedText))
                {
                    generatedText = generatedText.Replace("```json", "").Replace("```", "").Trim();
                    var missions = JsonSerializer.Deserialize<List<Mission>>(generatedText, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    return missions ?? new List<Mission>();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ Erreur pendant le traitement Groq : " + ex.Message);
            }

            return new List<Mission>();
        }
    }
}