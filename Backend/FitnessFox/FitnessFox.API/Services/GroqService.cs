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

            // 👇 LE NOUVEAU CERVEAU DE L'IA (Plusieurs missions par catégorie)
            var prompt = $@"Tu es Fitness Fox, un coach sportif et nutritionnel virtuel expert.
Aujourd'hui, tu dois générer un programme complet pour cet utilisateur sous forme de multiples missions :
- Objectif : {user.Goals ?? "Garder la forme"}
- Poids : {user.Weight} kg
- Taille : {user.Height} cm
- Blessures : {user.Injuries ?? "Aucune"}

CONSIGNES DE GÉNÉRATION :
1. SPORT : Crée une séance de sport logique (ex: Séance Push, Tirage, ou Jambes). Génère 3 à 5 missions de 'Sport' qui correspondent aux différents exercices de cette séance (ex: Développé couché, puis Élévations latérales).
2. NUTRITION : Génère 2 à 4 missions de 'Nutrition' réparties sur la journée (ex: Petit-déjeuner, Déjeuner, Dîner, Collation) adaptées à son objectif.
3. MENTAL : Génère 1 ou 2 missions de 'Mental' (ex: Méditation, lecture, étirements relaxants).";

            // Ajout du feedback s'il existe
            if (!string.IsNullOrEmpty(user.LastFeedback))
            {
                prompt += $@"
- RETOUR D'HIER : L'utilisateur a laissé ce commentaire : ""{user.LastFeedback}"". 
- DIFFICULTÉ RESSENTIE HIER : {user.LastDifficulty}/10. 
ADAPTATION OBLIGATOIRE : Si la note est haute (8-10), rends le programme d'aujourd'hui plus facile (moins de volume ou exercices plus simples). Si la note est basse (1-4), augmente un peu le défi (surcharge progressive). Prends en compte son commentaire pour ajuster les exercices d'aujourd'hui.";
            }

            prompt += @"
Réponds UNIQUEMENT avec un tableau JSON valide. Ne mets aucun texte avant ou après. N'utilise pas de balises markdown.
Utilise les propriétés : Title, Type, Points.
Types autorisés : Sport, Nutrition, Mental.
Points : 10 à 30 par mission. Adapte impérativement les exercices aux blessures de l'utilisateur.

Exemple de format attendu :
[
  { ""Title"": ""Développé couché - 4 séries de 10"", ""Type"": ""Sport"", ""Points"": 20 },
  { ""Title"": ""Élévations latérales - 3 séries de 15"", ""Type"": ""Sport"", ""Points"": 15 },
  { ""Title"": ""Extension triceps à la poulie - 3 séries de 12"", ""Type"": ""Sport"", ""Points"": 15 },
  { ""Title"": ""Petit-déjeuner : Flocons d'avoine, œufs et fruit"", ""Type"": ""Nutrition"", ""Points"": 15 },
  { ""Title"": ""Déjeuner : Poulet, riz basmati et brocolis"", ""Type"": ""Nutrition"", ""Points"": 20 },
  { ""Title"": ""10 minutes de cohérence cardiaque (Respiration)"", ""Type"": ""Mental"", ""Points"": 15 }
]";

            var requestBody = new
            {
                model = "llama-3.3-70b-versatile",
                messages = new[] { new { role = "user", content = prompt } },
                temperature = 0.7 // 0.7 laisse un peu de créativité à l'IA pour varier les entraînements
            };

            var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

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