namespace FitnessFox.API.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Pseudo { get; set; } = "FoxWarrior";
        public int Score { get; set; } = 0;
        public int TotalMissionsCompleted { get; set; } = 0;
        public string Password { get; set; } = string.Empty; //Pour gérer les Flammes 🔥
        public int CurrentStreak { get; set; } = 0; // La série actuelle
        public DateTime? LastActivityDate { get; set; } // La date de la dernière mission validée
        public float? Weight { get; set; } // Poids en kg
        public int? Height { get; set; } // Taille en cm
        public string? Injuries { get; set; } // ex: "Douleur au genou droit"
        public string? Goals { get; set; } // ex: "Perte de poids", "Prise de masse"
        public string? LastFeedback { get; set; } // Le texte de son ressenti
        public int? LastDifficulty { get; set; }  // La note de 1 à 10
    }
}
