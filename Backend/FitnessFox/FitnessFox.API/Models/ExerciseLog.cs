using System.ComponentModel.DataAnnotations;

namespace FitnessFox.API.Models
{
    public class ExerciseLog
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        public string ExerciseName { get; set; } = string.Empty; // Ex: "Développé couché"
        public float Weight { get; set; } // Charge en kg
        public int Reps { get; set; } // Nombre de répétitions
        public DateTime Date { get; set; } = DateTime.UtcNow; // Date de la performance
    }
}