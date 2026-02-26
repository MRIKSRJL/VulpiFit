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

        // 👇 NOUVEAU : On ajoute l'historique en paramètre
        public async Task<List<Mission>> GenerateDailyMissionsAsync(User user, List<ExerciseLog> exerciseHistory)
        {
            if (string.IsNullOrEmpty(_apiKey) || _apiKey == "TA_CLE_GROQ_GSK_ICI")
            {
                Console.WriteLine("🛑 ERREUR CRITIQUE : La clé API Groq est introuvable !");
                return new List<Mission>();
            }

            // 1. 🔄 PRÉPARATION DE L'HISTORIQUE POUR L'IA
            string historyText = "Aucun historique d'exercice récent. Propose des charges de départ prudentes pour évaluer son niveau.";
            if (exerciseHistory != null && exerciseHistory.Any())
            {
                var historyLines = exerciseHistory.Select(e => $"- {e.ExerciseName} : {e.Weight}kg x {e.Reps} reps (le {e.Date:dd/MM})");
                historyText = string.Join("\n", historyLines);
            }

            // 2. 🧠 LE NOUVEAU PROMPT SURPUISSANT
            var prompt = $@"Tu es Fitness Fox, un coach sportif et nutritionnel virtuel expert.
Aujourd'hui, tu dois générer un programme complet pour cet utilisateur sous forme de multiples missions :
- Objectif : {user.Goals ?? "Garder la forme"}
- Poids : {user.Weight} kg
- Taille : {user.Height} cm
- Blessures : {user.Injuries ?? "Aucune"}

HISTORIQUE DES PERFORMANCES RÉCENTES (Pour la surcharge progressive) :
{historyText}

CONSIGNES DE GÉNÉRATION :
1. SPORT : Crée une séance de sport logique (ex: Séance Push, Tirage, ou Jambes). 
TRÈS IMPORTANT : Analyse l'historique ci-dessus. Si tu proposes un exercice déjà réalisé, applique le principe de surcharge progressive (augmente la charge de 1 à 2.5kg, ou ajoute 1 à 2 répétitions). 
INCLUS OBLIGATOIREMENT la charge et les répétitions dans le titre (ex: 'Développé couché - 4 séries de 10 à 62.5kg'). Si c'est un nouvel exercice, propose une charge et des répétitions cohérentes avec son profil. Génère 3 à 5 missions de 'Sport'.
2. NUTRITION : Génère 2 à 4 missions de 'Nutrition' réparties sur la journée (ex: Petit-déjeuner, Déjeuner, Dîner, Collation) adaptées à ses objectifs spécifiques.
3. MENTAL : Génère 1 ou 2 missions de 'Mental' (ex: Méditation, lecture, étirements relaxants).";

            // Ajout du feedback s'il existe
            if (!string.IsNullOrEmpty(user.LastFeedback))
            {
                prompt += $@"
- RETOUR D'HIER : L'utilisateur a laissé ce commentaire : ""{user.LastFeedback}"". 
- DIFFICULTÉ RESSENTIE HIER : {user.LastDifficulty}/10. 
ADAPTATION OBLIGATOIRE : Si la note est haute (8-10), rends le programme d'aujourd'hui plus facile. Si la note est basse (1-4), augmente un peu le défi. Prends en compte son commentaire pour ajuster les exercices d'aujourd'hui.";
            }

            prompt += @"
Réponds UNIQUEMENT avec un tableau JSON valide. Ne mets aucun texte avant ou après. N'utilise pas de balises markdown.
Utilise les propriétés : Title, Type, Points.
Types autorisés : Sport, Nutrition, Mental.
Points : 10 à 30 par mission. Adapte impérativement les exercices aux blessures de l'utilisateur.

Exemple de format attendu :
[
  { ""Title"": ""Développé couché - 4 séries de 10 à 60kg"", ""Type"": ""Sport"", ""Points"": 20 },
  { ""Title"": ""Élévations latérales - 3 séries de 15 à 12kg"", ""Type"": ""Sport"", ""Points"": 15 },
  { ""Title"": ""Petit-déjeuner riche en protéines"", ""Type"": ""Nutrition"", ""Points"": 15 },
  { ""Title"": ""10 minutes de cohérence cardiaque"", ""Type"": ""Mental"", ""Points"": 15 }
]";

            var requestBody = new
            {
                model = "llama-3.3-70b-versatile",
                messages = new[] { new { role = "user", content = prompt } },
                temperature = 0.7
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