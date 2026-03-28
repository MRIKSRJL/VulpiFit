class Mission {
  final int id;
  final String title;
  final String type;
  final int points;
  bool isCompleted;

  Mission({
    required this.id,
    required this.title,
    required this.type,
    required this.points,
    this.isCompleted = false,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    dynamic v(String camel, String pascal) => json[camel] ?? json[pascal];

    final idVal = v('id', 'Id');
    final pointsVal = v('points', 'Points');
    final completedVal = v('isCompleted', 'IsCompleted');

    return Mission(
      id: idVal is int ? idVal : int.tryParse('$idVal') ?? 0,
      title: '${v('title', 'Title') ?? 'Mission inconnue'}',
      type: '${v('type', 'Type') ?? 'Inconnu'}',
      points: pointsVal is int ? pointsVal : int.tryParse('$pointsVal') ?? 0,
      isCompleted: completedVal == true || completedVal == 1,
    );
  }

  /// Filtre tolérant (casse + sous-chaîne dans le titre si besoin).
  bool matchesCategory(String keyword) {
    final k = keyword.toLowerCase().trim();
    final t = type.toLowerCase();
    if (t.contains(k)) return true;
    return title.toLowerCase().contains(k);
  }
}