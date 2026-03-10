namespace VulpiFit.Models // Vérifie ton namespace
{
    public class MissionViewModel
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public int Points { get; set; }
        // Ajoute ici les autres propriétés de tes missions si tu en as (ex: Type, Difficulte...)
    }
}