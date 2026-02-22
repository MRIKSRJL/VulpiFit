namespace FitnessFox.API.Models
{
    public class Mission
    {
        public int Id { get; set; }             // L'identifiant unique
        public string Title { get; set; }       // Ex: "10 Pompes"
        public string Type { get; set; }        // Ex: "Sport" ou "Nutrition"
        public int Points { get; set; }         // Ex: 50 XP
        public bool IsCompleted { get; set; } = false;   // Fait ou pas fait ?
        public int? UserId { get; set; }
        public DateTime AssignedDate { get; set; } // Pour quel jour a-t-elle été générée ?

    }
}