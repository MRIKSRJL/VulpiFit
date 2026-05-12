using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using VulpiFit.API.Data;
using VulpiFit.API.Models;

namespace VulpiFit.API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class FriendsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public FriendsController(ApplicationDbContext context)
        {
            _context = context;
        }

        private int? GetCurrentUserId()
        {
            var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(claim, out var userId) ? userId : null;
        }

        [HttpGet("search")]
        public async Task<IActionResult> SearchUsers([FromQuery] string pseudo)
        {
            try
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null) return Unauthorized();

                var query = (pseudo ?? string.Empty).Trim();
                if (query.Length < 2)
                {
                    return BadRequest("Le pseudo doit contenir au moins 2 caractères.");
                }

                var users = await _context.Users
                    .Where(u => u.Id != currentUserId.Value && u.Pseudo.Contains(query))
                    .OrderBy(u => u.Pseudo)
                    .Take(20)
                    .Select(u => new
                    {
                        u.Id,
                        u.Pseudo,
                        u.Score,
                        u.CurrentStreak
                    })
                    .ToListAsync();

                return Ok(users);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }

        [HttpPost("request/{receiverId:int}")]
        public async Task<IActionResult> SendFriendRequest(int receiverId)
        {
            try
            {
                var requesterId = GetCurrentUserId();
                if (requesterId == null) return Unauthorized();

                if (requesterId.Value == receiverId)
                    return BadRequest("Tu ne peux pas t'ajouter toi-même.");

                var requesterExists = await _context.Users.AnyAsync(u => u.Id == requesterId.Value);
                if (!requesterExists)
                    return BadRequest("Utilisateur connecté introuvable.");

                var receiverExists = await _context.Users.AnyAsync(u => u.Id == receiverId);
                if (!receiverExists)
                    return BadRequest("Utilisateur introuvable.");

                var existing = await _context.Friendships.FirstOrDefaultAsync(f =>
                    (f.RequesterId == requesterId.Value && f.ReceiverId == receiverId) ||
                    (f.RequesterId == receiverId && f.ReceiverId == requesterId.Value));

                if (existing != null)
                    return BadRequest("Une demande existe déjà avec cet utilisateur.");

                var friendship = new Friendship
                {
                    RequesterId = requesterId.Value,
                    ReceiverId = receiverId,
                    Status = FriendshipStatus.Pending,
                    CoopStreakStatus = CoopStreakStatus.None,
                    CurrentCoopStreak = 0,
                    LastCoopMaintenanceDate = null
                };

                _context.Friendships.Add(friendship);
                await _context.SaveChangesAsync();
                return Ok(friendship);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }

        [HttpPut("accept/{friendshipId:int}")]
        public async Task<IActionResult> AcceptFriendRequest(int friendshipId)
        {
            try
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null) return Unauthorized();

                var friendship = await _context.Friendships.FindAsync(friendshipId);
                if (friendship == null) return NotFound("Demande introuvable.");
                if (friendship.ReceiverId != currentUserId.Value) return Forbid();
                if (friendship.Status != FriendshipStatus.Pending) return BadRequest("Cette demande n'est plus en attente.");

                friendship.Status = FriendshipStatus.Accepted;
                await _context.SaveChangesAsync();
                return Ok(friendship);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }

        [HttpPut("reject/{friendshipId:int}")]
        public async Task<IActionResult> RejectFriendRequest(int friendshipId)
        {
            try
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null) return Unauthorized();

                var friendship = await _context.Friendships.FindAsync(friendshipId);
                if (friendship == null) return NotFound("Demande introuvable.");
                if (friendship.ReceiverId != currentUserId.Value) return Forbid();
                if (friendship.Status != FriendshipStatus.Pending) return BadRequest("Cette demande n'est plus en attente.");

                friendship.Status = FriendshipStatus.Rejected;
                friendship.CoopStreakStatus = CoopStreakStatus.None;
                friendship.CurrentCoopStreak = 0;
                friendship.LastCoopMaintenanceDate = null;
                await _context.SaveChangesAsync();
                return Ok(friendship);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }

        [HttpGet("my-friends")]
        public async Task<IActionResult> MyFriends()
        {
            try
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null) return Unauthorized();

                var accepted = await _context.Friendships
                    .Where(f => f.Status == FriendshipStatus.Accepted &&
                                (f.RequesterId == currentUserId.Value || f.ReceiverId == currentUserId.Value))
                    .Select(f => new
                    {
                        f.Id,
                        FriendId = f.RequesterId == currentUserId.Value ? f.ReceiverId : f.RequesterId,
                        FriendPseudo = f.RequesterId == currentUserId.Value ? f.Receiver.Pseudo : f.Requester.Pseudo,
                        f.CoopStreakStatus,
                        f.CurrentCoopStreak,
                        f.LastCoopMaintenanceDate
                    })
                    .ToListAsync();

                var pendingReceived = await _context.Friendships
                    .Where(f => f.Status == FriendshipStatus.Pending && f.ReceiverId == currentUserId.Value)
                    .Select(f => new
                    {
                        f.Id,
                        FromUserId = f.RequesterId,
                        FromPseudo = f.Requester.Pseudo
                    })
                    .ToListAsync();

                var pendingSent = await _context.Friendships
                    .Where(f => f.Status == FriendshipStatus.Pending && f.RequesterId == currentUserId.Value)
                    .Select(f => new
                    {
                        f.Id,
                        ToUserId = f.ReceiverId,
                        ToPseudo = f.Receiver.Pseudo
                    })
                    .ToListAsync();

                return Ok(new
                {
                    acceptedFriends = accepted,
                    pendingReceived,
                    pendingSent
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }

        [HttpGet("profile/{friendUserId:int}")]
        public async Task<IActionResult> GetFriendProfile(int friendUserId)
        {
            try
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null) return Unauthorized();

                var isAcceptedFriend = await _context.Friendships.AnyAsync(f =>
                    f.Status == FriendshipStatus.Accepted &&
                    ((f.RequesterId == currentUserId.Value && f.ReceiverId == friendUserId) ||
                     (f.ReceiverId == currentUserId.Value && f.RequesterId == friendUserId)));

                if (!isAcceptedFriend)
                    return StatusCode(403, "Profil accessible uniquement pour des amis acceptés.");

                var friend = await _context.Users
                    .Where(u => u.Id == friendUserId)
                    .Select(u => new
                    {
                        u.Id,
                        u.Pseudo,
                        u.Score,
                        u.CurrentStreak,
                        u.TotalMissionsCompleted
                    })
                    .FirstOrDefaultAsync();

                if (friend == null) return NotFound("Ami introuvable.");

                return Ok(friend);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }

        [HttpPost("coop/propose/{friendshipId:int}")]
        public async Task<IActionResult> ProposeCoop(int friendshipId)
        {
            try
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null) return Unauthorized();

                var friendship = await _context.Friendships.FindAsync(friendshipId);
                if (friendship == null) return NotFound("Amitié introuvable.");
                if (friendship.Status != FriendshipStatus.Accepted) return BadRequest("Amitié non acceptée.");
                if (friendship.RequesterId != currentUserId.Value && friendship.ReceiverId != currentUserId.Value)
                    return Forbid();

                friendship.CoopStreakStatus = CoopStreakStatus.Proposed;
                friendship.CurrentCoopStreak = 0;
                friendship.LastCoopMaintenanceDate = null;
                await _context.SaveChangesAsync();
                return Ok(friendship);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }

        [HttpPut("coop/accept/{friendshipId:int}")]
        public async Task<IActionResult> AcceptCoop(int friendshipId)
        {
            try
            {
                var currentUserId = GetCurrentUserId();
                if (currentUserId == null) return Unauthorized();

                var friendship = await _context.Friendships.FindAsync(friendshipId);
                if (friendship == null) return NotFound("Amitié introuvable.");
                if (friendship.Status != FriendshipStatus.Accepted) return BadRequest("Amitié non acceptée.");
                if (friendship.RequesterId != currentUserId.Value && friendship.ReceiverId != currentUserId.Value)
                    return Forbid();
                if (friendship.CoopStreakStatus != CoopStreakStatus.Proposed)
                    return BadRequest("Aucune proposition Co-op en attente.");

                friendship.CoopStreakStatus = CoopStreakStatus.Active;
                friendship.CurrentCoopStreak = 0;
                friendship.LastCoopMaintenanceDate = null;
                await _context.SaveChangesAsync();
                return Ok(friendship);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"{ex.Message} | {ex.InnerException?.Message}");
            }
        }
    }
}
