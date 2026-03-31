using Microsoft.EntityFrameworkCore;
using VulpiFit.API.Models; 

namespace VulpiFit.API.Data
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
        public DbSet<Friendship> Friendships { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Friendship>()
                .HasOne(f => f.Requester)
                .WithMany(u => u.SentFriendships)
                .HasForeignKey(f => f.RequesterId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Friendship>()
                .HasOne(f => f.Receiver)
                .WithMany(u => u.ReceivedFriendships)
                .HasForeignKey(f => f.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Friendship>()
                .HasIndex(f => new { f.RequesterId, f.ReceiverId });
        }
    }
}
