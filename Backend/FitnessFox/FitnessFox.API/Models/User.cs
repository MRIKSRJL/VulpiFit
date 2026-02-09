namespace FitnessFox.API.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Pseudo { get; set; } = "FoxWarrior";
        public int Score { get; set; } = 0;
        public int TotalMissionsCompleted { get; set; } = 0;
    }
}
