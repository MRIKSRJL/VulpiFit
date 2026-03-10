using System;

namespace VulpiFit.API.Models // Remplace par ton vrai namespace si différent
{
    public class UserProgressLog
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public DateTime Date { get; set; }
        public float Weight { get; set; } // Pour la courbe de poids
        public int TotalScore { get; set; } // Pour la courbe d'XP/Progression
    }
}