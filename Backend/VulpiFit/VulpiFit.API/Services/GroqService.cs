using System.Text;
using System.Text.Json;
using VulpiFit.API.Models;

namespace VulpiFit.API.Services
{
    public class GroqService
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;
        private readonly bool _isDevelopment;

        public GroqService(HttpClient httpClient, IConfiguration config)
        {
            _httpClient = httpClient;
            _apiKey = (config["Groq:ApiKey"] ?? config["GroqApiKey"] ?? string.Empty).Trim();
            _isDevelopment = string.Equals(config["ASPNETCORE_ENVIRONMENT"], "Development", StringComparison.OrdinalIgnoreCase);

            var source = !string.IsNullOrWhiteSpace(config["Groq:ApiKey"])
                ? "Groq:ApiKey"
                : !string.IsNullOrWhiteSpace(config["GroqApiKey"])
                    ? "GroqApiKey (legacy)"
                    : "missing";
            Console.WriteLine($"[Groq] Key source={source}, keyPresent={!string.IsNullOrEmpty(_apiKey)}, env={(_isDevelopment ? "Development" : "NonDevelopment")}");
        }

        private static string BuildStreakBlock(int streak)
        {
            if (streak <= 0)
            {
                return @"CAS STREAK = 0 (BIENVEILLANCE) :
- L'utilisateur débute ou a perdu sa série.
- Adopte un ton ultra bienveillant, rassurant et dédramatisant.
- Objectif principal : lui redonner confiance et relancer la machine, pas le dégoûter.
- Propose des missions TRÈS faciles pour Sport, Nutrition et Mental.
  Exemples Sport : ""10 pompes en 1 ou plusieurs fois"", ""1 série de 10 squats au poids du corps"", ""5 minutes de marche douce"".
  Exemples Nutrition : ""Boire au moins 1L d'eau"", ""Ajouter un fruit dans la journée"".
  Exemples Mental : ""2 minutes de respiration profonde"", ""1 minute de gratitude le soir"".
- Évite les burpees, les grosses charges ou les contraintes complexes.";
            }

            if (streak is >= 1 and <= 10)
            {
                return @"CAS STREAK 1 À 10 (ROUTINE) :
- L'utilisateur construit sa discipline, il est sur une bonne lancée.
- Adopte un ton fier, enthousiaste et motivant (comme un coach fier de son élève).
- Les missions doivent être de difficulté MODÉRÉE : ni trop faciles, ni extrêmes.
- Conserve une structure claire et répétable (routine) pour ancrer des habitudes.
- Sport : volume standard, charges cohérentes, un peu de surcharge progressive mais sans violence.
- Nutrition : repas équilibrés, macros approximatives mais pédagogiques.
- Mental : méditations courtes, routines de sommeil simples, étirements réguliers.";
            }

            return @"CAS STREAK > 10 (MODE BOSS) :
- L'utilisateur est en série longue : traite-le comme une machine disciplinée.
- Adopte un ton extatique, impressionné, presque ""commentateur e-sport"".
- Applique une VRAIE SURCHARGE PROGRESSIVE sur les exercices répétés :
  - Augmente significativement la charge (2.5kg ou plus) OU le volume (séries / reps).
  - Introduis des exercices plus avancés : burpees, fractionné, supersets, tempo lent, etc.
- Nutrition : propose des missions plus ambitieuses (repas macro-calculés, préparation à l'avance, contrôle précis).
- Mental : séances plus longues (ex : 10–20 minutes de méditation), écritures de journal, défis de discipline (pas d'écran avant le coucher, etc.).
- Garde cependant 1 à 2 missions ""faciles / plaisir"" pour éviter le burn-out psychologique.";
        }

        private static string BuildGoalProfileBlock(string goals)
        {
            var lowerGoals = goals.ToLowerInvariant();
            if (lowerGoals.Contains("perte") || lowerGoals.Contains("gras") || lowerGoals.Contains("poids"))
            {
                return @"PROFIL OBJECTIF PERTE DE POIDS :
- Priorise la satiété, la densité nutritionnelle et le déficit calorique modéré.
- Nutrition : donne des quantités claires (ex: 200g skyr, 40g flocons d'avoine, 1 pomme moyenne).
- Sport : favorise volume modéré + cardio progressif.
- Mental : focus constance (lecture/podcast utile + respiration courte anti-compulsion).";
            }

            if (lowerGoals.Contains("muscle") || lowerGoals.Contains("force") || lowerGoals.Contains("prise de masse"))
            {
                return @"PROFIL OBJECTIF PERFORMANCE / MASSE :
- Priorise protéines, récupération et surcharge progressive.
- Nutrition : donne des portions riches en protéines avec quantités (g/ml) et alternatives.
- Sport : exercices structurés avec volume/charges explicites.
- Mental : focus discipline et concentration (lecture active/podcast de performance).";
            }

            return @"PROFIL OBJECTIF FORME GÉNÉRALE :
- Cherche l'équilibre : mission faisable, claire et utile dès aujourd'hui.
- Nutrition : portions concrètes + aliments simples à trouver.
- Mental : alternance lecture/podcast + respiration/méditation courte.";
        }

        public List<Mission> BuildQualityFallbackMissions(User user)
        {
            var goals = (user.Goals ?? "forme générale").ToLowerInvariant();
            var streak = user.CurrentStreak;

            var nutrition = goals.Contains("perte") || goals.Contains("gras") || goals.Contains("poids")
                ? new List<string>
                {
                    "Petit-déjeuner: 200g de skyr + 40g de flocons d'avoine + 1 pomme (150g)",
                    "Déjeuner: 150g poulet + 200g légumes verts + 120g riz cuit",
                    "Collation: 1 banane (120g) + 20g d'amandes"
                }
                : new List<string>
                {
                    "Petit-déjeuner: 3 oeufs + 2 tranches pain complet (80g) + 1 orange",
                    "Déjeuner: 180g poisson + 200g patate douce + 150g légumes",
                    "Collation: 250ml lait + 30g flocons d'avoine + 1 banane"
                };

            var mental = streak >= 5
                ? new List<string>
                {
                    "Lire 10 pages d'un livre de progression personnelle et noter 1 idée",
                    "Ecouter 20 minutes d'un podcast santé/discipline puis écrire 3 points clés",
                    "Faire 5 minutes de respiration lente (cohérence cardiaque) avant le coucher"
                }
                : new List<string>
                {
                    "Lire 6 pages d'un livre utile (santé ou discipline personnelle)",
                    "Ecouter 12 minutes d'un podcast bien-être et noter 1 action concrète",
                    "Faire 3 minutes de respiration profonde (inspire 4s, expire 6s)"
                };

            return new List<Mission>
            {
                new Mission { Title = "Sport: 20 minutes de marche active + 2 séries de 12 squats poids du corps", Type = "Sport", Points = 15 },
                new Mission { Title = nutrition[0], Type = "Nutrition", Points = 15 },
                new Mission { Title = nutrition[1], Type = "Nutrition", Points = 20 },
                new Mission { Title = mental[0], Type = "Mental", Points = 15 },
                new Mission { Title = mental[1], Type = "Mental", Points = 15 }
            };
        }

        /// Construit le prompt complet envoyé à Groq (utilisé aussi par l'endpoint de debug).
        public string BuildDailyMissionPrompt(User user, List<ExerciseLog> exerciseHistory)
        {
            // 1. Historique pour la surcharge progressive
            string historyText = "Aucun historique d'exercice récent. Propose des charges de départ prudentes pour évaluer son niveau.";
            if (exerciseHistory != null && exerciseHistory.Any())
            {
                var historyLines = exerciseHistory.Select(e =>
                    $"- {e.ExerciseName} : {e.Weight}kg x {e.Reps} reps (le {e.Date:dd/MM})");
                historyText = string.Join("\n", historyLines);
            }

            var goals = user.Goals ?? "Garder la forme";
            var injuries = user.Injuries ?? "Aucune";
            var streak = user.CurrentStreak;

            var streakBlock = BuildStreakBlock(streak);
            var goalProfileBlock = BuildGoalProfileBlock(goals);

            var prompt = $@"Tu es VulpiFit, un coach sportif et nutritionnel virtuel expert.
Aujourd'hui, tu dois générer un programme complet pour cet utilisateur sous forme de multiples missions :
- Objectif : {goals}
- Poids : {user.Weight} kg
- Taille : {user.Height} cm
- Blessures : {injuries}
- Streak actuel (série de jours consécutifs) : {streak} jour(s).

INSTRUCTIONS STREAK (SURCHARGE PROGRESSIVE & PSYCHOLOGIQUE) :
{streakBlock}

INSTRUCTIONS OBJECTIF UTILISATEUR :
{goalProfileBlock}

HISTORIQUE DES PERFORMANCES RÉCENTES (Pour la surcharge progressive) :
{historyText}

CONSIGNES DE GÉNÉRATION :
1. SPORT : Crée une séance de sport logique (ex: Séance Push, Tirage, ou Jambes). 
TRÈS IMPORTANT : Analyse l'historique ci-dessus. Si tu proposes un exercice déjà réalisé, applique le principe de surcharge progressive (augmente la charge de 1 à 2.5kg, ou ajoute 1 à 2 répétitions). 
INCLUS OBLIGATOIREMENT la charge et les répétitions dans le titre (ex: 'Développé couché - 4 séries de 10 à 62.5kg'). Si c'est un nouvel exercice, propose une charge et des répétitions cohérentes avec son profil. Génère 3 à 5 missions de 'Sport'.
2. NUTRITION : Génère 2 à 4 missions de 'Nutrition' réparties sur la journée (Petit-déjeuner, Déjeuner, Dîner, Collation).
   OBLIGATOIRE : chaque mission Nutrition doit inclure au moins 1 quantité explicite (g/ml/unité) + un aliment précis + un contexte repas.
   Exemple valide : 'Petit-déjeuner: 200g skyr + 40g flocons d'avoine + 1 banane (120g)'.
3. MENTAL : Génère 1 ou 2 missions de 'Mental' en priorisant lecture/podcast.
   OBLIGATOIRE : mission Mental = action concrète + durée/pages + mini livrable (ex: noter 1 idée).
   La respiration/méditation courte reste autorisée mais en complément, pas comme unique format quotidien.
   RÈGLE DE TYPE : toute mission lecture, pages de livre, podcast ou audio → Type ""Mental"" uniquement, jamais ""Sport"" (même si le livre parle de sport).
4. INTERDIT : formulations vagues de type 'manger équilibré', 'faire de la gratitude 1 minute', 'manger un fruit' sans détail.";

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
  { ""Title"": ""Petit-déjeuner: 200g skyr + 40g flocons d'avoine + 1 pomme (150g)"", ""Type"": ""Nutrition"", ""Points"": 15 },
  { ""Title"": ""Lire 10 pages d'un livre et noter 1 idée utile"", ""Type"": ""Mental"", ""Points"": 15 }
]";

            return prompt;
        }

        // Génération standard des missions pour l'application
        public async Task<List<Mission>> GenerateDailyMissionsAsync(User user, List<ExerciseLog> exerciseHistory)
        {
            if (string.IsNullOrEmpty(_apiKey) || _apiKey == "TA_CLE_GROQ_GSK_ICI")
            {
                throw new InvalidOperationException("Groq API key missing or placeholder.");
            }

            var prompt = BuildDailyMissionPrompt(user, exerciseHistory);

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
                    throw new InvalidOperationException($"Groq HTTP {(int)response.StatusCode}: {error}");
                }

                var jsonResponse = await response.Content.ReadAsStringAsync();

                using var document = JsonDocument.Parse(jsonResponse);
                var root = document.RootElement;
                var generatedText = root.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString();

                if (!string.IsNullOrEmpty(generatedText))
                {
                    generatedText = generatedText.Replace("```json", "").Replace("```", "").Trim();
                    var missions = JsonSerializer.Deserialize<List<Mission>>(generatedText, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    if (missions == null || !missions.Any())
                    {
                        throw new InvalidOperationException("Groq returned empty mission list.");
                    }
                    return missions;
                }

                throw new InvalidOperationException("Groq returned empty content.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ Erreur pendant le traitement Groq : " + ex.Message);
                throw;
            }
        }
    }
}