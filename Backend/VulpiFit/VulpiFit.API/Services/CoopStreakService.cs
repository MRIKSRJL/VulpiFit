using Microsoft.EntityFrameworkCore;
using VulpiFit.API.Data;
using VulpiFit.API.Models;

namespace VulpiFit.API.Services
{
    public class CoopStreakService
    {
        private readonly ApplicationDbContext _context;

        public CoopStreakService(ApplicationDbContext context)
        {
            _context = context;
        }

        private static DateTime UtcDate(DateTime value) =>
            value.Kind == DateTimeKind.Utc ? value.Date : value.ToUniversalTime().Date;

        private async Task<bool> HasCompletedAllMissionsTodayAsync(int userId, DateTime todayLocal)
        {
            var missions = await _context.Missions
                .Where(m => m.UserId == userId && m.AssignedDate.Date == todayLocal)
                .ToListAsync();

            // Aucune mission aujourd'hui => pas de maintenance co-op.
            if (!missions.Any()) return false;
            return missions.All(m => m.IsCompleted);
        }

        /// <summary>
        /// Maintient le streak duo pour toutes les amitiés actives de l'utilisateur.
        /// Appeler cette méthode quand l'utilisateur valide ses missions du jour.
        /// </summary>
        public async Task UpdateCoopStreakAsync(int userId)
        {
            var todayLocal = DateTime.Today;
            var nowUtc = DateTime.UtcNow;

            var activeFriendships = await _context.Friendships
                .Where(f =>
                    f.Status == FriendshipStatus.Accepted &&
                    f.CoopStreakStatus == CoopStreakStatus.Active &&
                    (f.RequesterId == userId || f.ReceiverId == userId))
                .ToListAsync();

            if (!activeFriendships.Any()) return;

            var currentUserDone = await HasCompletedAllMissionsTodayAsync(userId, todayLocal);
            bool hasChanges = false;

            foreach (var friendship in activeFriendships)
            {
                var friendId = friendship.RequesterId == userId
                    ? friendship.ReceiverId
                    : friendship.RequesterId;

                // Reset si on a un trou > 1 jour depuis la dernière maintenance.
                if (friendship.LastCoopMaintenanceDate.HasValue)
                {
                    var lastUtcDate = UtcDate(friendship.LastCoopMaintenanceDate.Value);
                    var todayUtcDate = UtcDate(nowUtc);
                    if (lastUtcDate < todayUtcDate.AddDays(-1) && friendship.CurrentCoopStreak != 0)
                    {
                        friendship.CurrentCoopStreak = 0;
                        hasChanges = true;
                    }
                }

                var friendDone = await HasCompletedAllMissionsTodayAsync(friendId, todayLocal);

                // La progression du duo n'avance que si les 2 ont réellement fini aujourd'hui.
                if (!currentUserDone || !friendDone) continue;

                var alreadyMaintainedToday = friendship.LastCoopMaintenanceDate.HasValue &&
                    UtcDate(friendship.LastCoopMaintenanceDate.Value) == UtcDate(nowUtc);
                if (alreadyMaintainedToday) continue;

                if (!friendship.LastCoopMaintenanceDate.HasValue)
                {
                    friendship.CurrentCoopStreak = 1;
                }
                else
                {
                    var lastUtcDate = UtcDate(friendship.LastCoopMaintenanceDate.Value);
                    var todayUtcDate = UtcDate(nowUtc);
                    friendship.CurrentCoopStreak = lastUtcDate == todayUtcDate.AddDays(-1)
                        ? friendship.CurrentCoopStreak + 1
                        : 1;
                }

                friendship.LastCoopMaintenanceDate = nowUtc;
                hasChanges = true;
            }

            if (hasChanges)
            {
                await _context.SaveChangesAsync();
            }
        }
    }
}
