using System;

namespace VulpiFit.API.Models 
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
