using Microsoft.EntityFrameworkCore;
using VulpiFit.Web.Models;
using VulpiFit.API.Models; // Pour accéder à User, Mission, MissionLog

namespace VulpiFit.Web.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // On liste les tables de la base de données
        public DbSet<User> Users { get; set; }
        public DbSet<Mission> Missions { get; set; }

        // ⚠️ Si 'MissionLog' s'affiche en rouge, vérifie l'étape 3 ci-dessous
        public DbSet<MissionLog> MissionLogs { get; set; }
    }
}