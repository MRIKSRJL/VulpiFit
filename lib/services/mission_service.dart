import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mission.dart';

class MissionService {
  // L'adresse de base de ton API
  static const String baseUrl = "http://127.0.0.1:5045/api/missions";
  static const String userUrl = "http://127.0.0.1:5045/api/Users";

  // 1. 👇 CELLE QUI TE MANQUAIT : Récupérer la liste des missions
  static Future<List<Mission>> getMissions() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Mission.fromJson(item)).toList();
      } else {
        throw Exception("Erreur chargement missions");
      }
    } catch (e) {
      throw Exception("Erreur connexion : $e");
    }
  }

  // 2. Valider une mission (et récupérer le score)
  static Future<int> completeMission(int missionId) async {
    final String url = "$baseUrl/$missionId/complete";
    print("📢 CLICK : Tentative de validation vers $url"); 

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      print("📢 RÉPONSE SERVEUR : ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ POINTS AJOUTÉS ! Nouveau score : ${data['newScore']}");
        return data['newScore']; 
      } else {
        print("❌ ERREUR API : ${response.body}");
        throw Exception("Impossible de valider la mission");
      }
    } catch (e) {
      print("❌ ERREUR CONNEXION : $e");
      throw Exception("Erreur technique : $e");
    }
  }

  // 3. Annuler une mission (Undo)
  static Future<int> undoMission(int missionId) async {
    final String url = "$baseUrl/$missionId/undo";
    print("📢 ANNULATION vers $url");

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['newScore'];
    } else {
      throw Exception('Erreur annulation');
    }
  }

  // 4. 👇 Récupérer les Stats complètes (Score + Streak)
// 👇 On change <String, int> par <String, dynamic> pour pouvoir renvoyer du texte ET des chiffres
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await http.get(Uri.parse(userUrl));

      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(response.body);
        
        var user = users.firstWhere((u) => u['id'] == 1, orElse: () => null);

        if (user != null) {
          return {
            "pseudo": user['pseudo'], // ✅ On récupère le pseudo
            "score": user['score'],
            "streak": user['currentStreak'] ?? 0,
            "total": user['totalMissionsCompleted'] ?? 0 // ✅ On récupère le total
          };
        }
      }
    } catch (e) {
      print("Erreur stats : $e");
    }
    // Valeurs par défaut
    return {"pseudo": "Inconnu", "score": 0, "streak": 0, "total": 0};
  }

  // (Optionnel) Une petite fonction pour garder la compatibilité si du vieux code appelle encore getScore()
  static Future<int> getScore() async {
    var stats = await getUserStats();
    return stats['score']!;
  }
}