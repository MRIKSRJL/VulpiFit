namespace FitnessFox.Web.Models
{
    public class Mission
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public int Points { get; set; }
        public bool IsCompleted { get; set; }
        public int? UserId { get; set; }
    }
}