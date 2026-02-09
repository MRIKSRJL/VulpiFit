import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mission.dart';

class MissionService {
  // ⚠️ ATTENTION : Si tu es en USB, garde bien 127.0.0.1
  // Si tu es en Wifi, remets ton IP (ex: 192.168.x.x)
  static const String baseUrl = "http://127.0.0.1:5045/api/missions";

  // 1. Récupérer les missions (GET)
  static Future<List<Mission>> getMissions() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Mission.fromJson(item)).toList();
    } else {
      throw Exception("Échec du chargement des missions");
    }
  } // <--- C'est souvent cette accolade qui manquait !

  // 2. Mettre à jour une mission (PUT) - C'est la nouvelle partie
  static Future<void> updateMission(Mission mission) async {
    final response = await http.put(
      Uri.parse("$baseUrl/${mission.id}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": mission.id,
        "title": mission.title,
        "type": mission.type,
        "points": mission.points,
        "isCompleted": mission.isCompleted,
      }),
    );

    if (response.statusCode != 204) {
      throw Exception("Impossible de mettre à jour la mission");
    }
  }
  
  static Future<int> undoMission(int missionId) async {
    // Note: Adapte 'baseUrl' si tu l'as défini différemment dans ce fichier
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5045/api/missions/$missionId/undo'), // ou ton URL habituelle
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['newScore'];
    } else {
      throw Exception('Erreur annulation');
    }
  }
}