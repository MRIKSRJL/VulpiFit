using Microsoft.EntityFrameworkCore;
using FitnessFox.API.Models;

namespace FitnessFox.API.Data
{
    // Cette classe représente votre base de données entière
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        // Voici la table "Missions" qui sera créée dans SQL
        public DbSet<Mission> Missions { get; set; }
    }
}