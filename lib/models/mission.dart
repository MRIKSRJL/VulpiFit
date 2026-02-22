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
    // 🛡️ On ajoute des valeurs par défaut (fallback) si l'API renvoie du vide ou du null
    return Mission(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Mission inconnue',
      type: json['type'] ?? 'Inconnu', // 👈 Le filet de sécurité est ici !
      points: json['points'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}