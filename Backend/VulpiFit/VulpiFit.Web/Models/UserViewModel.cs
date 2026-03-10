namespace VulpiFit.Models // Attention : vérifie que ce namespace correspond bien à ton projet
{
    public class UserViewModel
    {
        public int Id { get; set; }
        public string Pseudo { get; set; }
        public int Score { get; set; }
        public int CurrentStreak { get; set; }
    }
}