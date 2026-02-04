class Mission {
  final int id;
  final String title;
  final String type;
  final int points;
  final bool isCompleted;

  Mission({
    required this.id,
    required this.title,
    required this.type,
    required this.points,
    required this.isCompleted,
  });

  // Cette fonction magique transforme le JSON reçu de l'API en Objet Flutter
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Sans titre',
      type: json['type'] ?? 'Général',
      points: json['points'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}