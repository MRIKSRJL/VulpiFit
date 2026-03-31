namespace VulpiFit.API.Models
{
    public enum FriendshipStatus
    {
        Pending = 0,
        Accepted = 1,
        Rejected = 2
    }

    public enum CoopStreakStatus
    {
        None = 0,
        Proposed = 1,
        Active = 2
    }

    public class Friendship
    {
        public int Id { get; set; }

        public int RequesterId { get; set; }
        public User Requester { get; set; } = null!;

        public int ReceiverId { get; set; }
        public User Receiver { get; set; } = null!;

        public FriendshipStatus Status { get; set; } = FriendshipStatus.Pending;

        // Mode Co-op
        public CoopStreakStatus CoopStreakStatus { get; set; } = CoopStreakStatus.None;
        public int CurrentCoopStreak { get; set; } = 0;
        public DateTime? LastCoopMaintenanceDate { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}
