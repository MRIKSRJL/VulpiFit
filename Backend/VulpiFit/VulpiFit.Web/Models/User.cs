namespace VulpiFit.Web.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Pseudo { get; set; } = "FoxWarrior";
        public string Password { get; set; } = string.Empty; // 👈 NOUVEAU
        public int Score { get; set; }
        public int TotalMissionsCompleted { get; set; }
        public int CurrentStreak { get; set; }
        public DateTime? LastActivityDate { get; set; }
    }
}