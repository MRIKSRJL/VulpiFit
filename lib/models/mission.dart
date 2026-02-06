class Mission {
  final int id;
  final String title;
  final String type;
  final int points;
  
  // 👇 J'ai enlevé le mot "final" ici pour qu'on puisse modifier l'état !
  bool isCompleted; 

  Mission({
    required this.id,
    required this.title,
    required this.type,
    required this.points,
    required this.isCompleted,
  });

  // Pour convertir le JSON reçu de l'API en objet Dart
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      points: json['points'],
      isCompleted: json['isCompleted'],
    );
  }
}