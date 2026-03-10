namespace VulpiFit.API.Models
{
    public class MissionLog
    {
        public int Id { get; set; }
        public int UserId { get; set; }      // Qui ?
        public int MissionId { get; set; }   // Quoi ?
        public DateTime DateCompleted { get; set; } // Quand ?

    }
}