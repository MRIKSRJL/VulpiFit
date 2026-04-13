enum FriendRequestStatus {
  accepted,
  pendingReceived,
  pendingSent,
}

enum CoopStatus {
  none,
  proposed,
  active,
  unknown,
}

class FriendItem {
  FriendItem({
    required this.friendshipId,
    required this.friendUserId,
    required this.friendPseudo,
    required this.status,
    this.coopStatus = CoopStatus.none,
    this.currentCoopStreak = 0,
  });

  final int friendshipId;
  final int friendUserId;
  final String friendPseudo;
  final FriendRequestStatus status;
  final CoopStatus coopStatus;
  final int currentCoopStreak;

  static CoopStatus _parseCoopStatus(dynamic raw) {
    final value = (raw ?? '').toString().toLowerCase();
    switch (value) {
      case 'none':
      case '0':
        return CoopStatus.none;
      case 'proposed':
      case '1':
        return CoopStatus.proposed;
      case 'active':
      case '2':
        return CoopStatus.active;
      default:
        return CoopStatus.unknown;
    }
  }

  factory FriendItem.fromAccepted(Map<String, dynamic> json) {
    final streakRaw = json['currentCoopStreak'] ?? json['CurrentCoopStreak'] ?? 0;
    return FriendItem(
      friendshipId: (json['id'] ?? json['Id'] ?? 0) as int,
      friendUserId: (json['friendId'] ?? json['FriendId'] ?? 0) as int,
      friendPseudo: (json['friendPseudo'] ?? json['FriendPseudo'] ?? 'Inconnu').toString(),
      status: FriendRequestStatus.accepted,
      coopStatus: _parseCoopStatus(json['coopStreakStatus'] ?? json['CoopStreakStatus']),
      currentCoopStreak: streakRaw is int ? streakRaw : int.tryParse('$streakRaw') ?? 0,
    );
  }

  factory FriendItem.fromPendingReceived(Map<String, dynamic> json) {
    return FriendItem(
      friendshipId: (json['id'] ?? json['Id'] ?? 0) as int,
      friendUserId: (json['fromUserId'] ?? json['FromUserId'] ?? 0) as int,
      friendPseudo: (json['fromPseudo'] ?? json['FromPseudo'] ?? 'Inconnu').toString(),
      status: FriendRequestStatus.pendingReceived,
    );
  }

  factory FriendItem.fromPendingSent(Map<String, dynamic> json) {
    return FriendItem(
      friendshipId: (json['id'] ?? json['Id'] ?? 0) as int,
      friendUserId: (json['toUserId'] ?? json['ToUserId'] ?? 0) as int,
      friendPseudo: (json['toPseudo'] ?? json['ToPseudo'] ?? 'Inconnu').toString(),
      status: FriendRequestStatus.pendingSent,
    );
  }
}

class FriendSearchResult {
  FriendSearchResult({
    required this.id,
    required this.pseudo,
    required this.score,
    required this.currentStreak,
  });

  final int id;
  final String pseudo;
  final int score;
  final int currentStreak;

  factory FriendSearchResult.fromJson(Map<String, dynamic> json) {
    final scoreRaw = json['score'] ?? json['Score'] ?? 0;
    final streakRaw = json['currentStreak'] ?? json['CurrentStreak'] ?? 0;
    return FriendSearchResult(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      pseudo: (json['pseudo'] ?? json['Pseudo'] ?? 'Inconnu').toString(),
      score: scoreRaw is int ? scoreRaw : int.tryParse('$scoreRaw') ?? 0,
      currentStreak: streakRaw is int ? streakRaw : int.tryParse('$streakRaw') ?? 0,
    );
  }
}

class FriendPublicStats {
  FriendPublicStats({
    required this.id,
    required this.pseudo,
    required this.score,
    required this.currentStreak,
    required this.totalMissionsCompleted,
  });

  final int id;
  final String pseudo;
  final int score;
  final int currentStreak;
  final int totalMissionsCompleted;

  factory FriendPublicStats.fromJson(Map<String, dynamic> json) {
    final scoreRaw = json['score'] ?? json['Score'] ?? 0;
    final streakRaw = json['currentStreak'] ?? json['CurrentStreak'] ?? 0;
    final missionsRaw =
        json['totalMissionsCompleted'] ?? json['TotalMissionsCompleted'] ?? 0;

    return FriendPublicStats(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      pseudo: (json['pseudo'] ?? json['Pseudo'] ?? 'Inconnu').toString(),
      score: scoreRaw is int ? scoreRaw : int.tryParse('$scoreRaw') ?? 0,
      currentStreak: streakRaw is int ? streakRaw : int.tryParse('$streakRaw') ?? 0,
      totalMissionsCompleted: missionsRaw is int
          ? missionsRaw
          : int.tryParse('$missionsRaw') ?? 0,
    );
  }
}

class MyFriendsData {
  MyFriendsData({
    required this.acceptedFriends,
    required this.pendingReceived,
    required this.pendingSent,
  });

  final List<FriendItem> acceptedFriends;
  final List<FriendItem> pendingReceived;
  final List<FriendItem> pendingSent;

  factory MyFriendsData.empty() =>
      MyFriendsData(acceptedFriends: [], pendingReceived: [], pendingSent: []);

  factory MyFriendsData.fromJson(Map<String, dynamic> json) {
    final acceptedRaw = (json['acceptedFriends'] ?? json['AcceptedFriends'] ?? []) as List<dynamic>;
    final pendingReceivedRaw =
        (json['pendingReceived'] ?? json['PendingReceived'] ?? []) as List<dynamic>;
    final pendingSentRaw = (json['pendingSent'] ?? json['PendingSent'] ?? []) as List<dynamic>;

    return MyFriendsData(
      acceptedFriends: acceptedRaw
          .map((e) => FriendItem.fromAccepted(Map<String, dynamic>.from(e as Map)))
          .toList(),
      pendingReceived: pendingReceivedRaw
          .map((e) => FriendItem.fromPendingReceived(Map<String, dynamic>.from(e as Map)))
          .toList(),
      pendingSent: pendingSentRaw
          .map((e) => FriendItem.fromPendingSent(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
