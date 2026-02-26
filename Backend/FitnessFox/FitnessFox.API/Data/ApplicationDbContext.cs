using Microsoft.EntityFrameworkCore;
using FitnessFox.API.Models; // 👈 Très important, sinon il ne trouve pas "User"

namespace FitnessFox.API.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }
        public DbSet<ExerciseLog> ExerciseLogs { get; set; }
        public DbSet<Mission> Missions { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<MissionLog> MissionLogs { get; set; }
        public DbSet<UserProgressLog> UserProgressLogs { get; set; }
    }
}