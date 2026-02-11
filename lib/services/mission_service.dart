import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mission.dart';

class MissionService {
  static const String baseUrl = "http://127.0.0.1:5045/api"; // ⚠️ Sur Android, localhost = 10.0.2.2
  // Si tu es sur un vrai téléphone, mets l'IP de ton PC (ex: 192.168.1.XX)

  // 👇 ICI ON STOCKE L'UTILISATEUR CONNECTÉ
  static int currentUserId = 0; 
  static String currentUserPseudo = "";

  // 1. CONNEXION
  static Future<bool> login(String pseudo, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pseudo": pseudo, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['id'];
        currentUserPseudo = data['pseudo'];
        return true; // Succès
      }
      return false; // Échec
    } catch (e) {
      print("Erreur Login: $e");
      return false;
    }
  }

  // 2. INSCRIPTION
  static Future<bool> register(String pseudo, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pseudo": pseudo, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['id'];
        currentUserPseudo = data['pseudo'];
        return true;
      }
      return false;
    } catch (e) {
      print("Erreur Register: $e");
      return false;
    }
  }

  // 3. Récupérer Stats (Modifié pour utiliser l'ID connecté)
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      // On récupère TOUS les utilisateurs
      final response = await http.get(Uri.parse("$baseUrl/Users"));

      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(response.body);
        
        // 👇 On cherche CELUI qui est connecté (currentUserId)
        var user = users.firstWhere((u) => u['id'] == currentUserId, orElse: () => null);

        if (user != null) {
          return {
            "pseudo": user['pseudo'],
            "score": user['score'],
            "streak": user['currentStreak'] ?? 0,
            "total": user['totalMissionsCompleted'] ?? 0
          };
        }
      }
    } catch (e) { print(e); }
    return {"pseudo": "Erreur", "score": 0, "streak": 0, "total": 0};
  }

  // --- LES AUTRES MÉTHODES (Missions) RESTENT PAREILLES ---
  // (Je te remets juste les signatures pour gagner de la place, garde ton code existant ici)
  static Future<List<Mission>> getMissions() async {
    // Utilise "$baseUrl/Missions"
    final response = await http.get(Uri.parse("$baseUrl/Missions"));
    if (response.statusCode == 200) {
       List<dynamic> body = jsonDecode(response.body);
       return body.map((item) => Mission.fromJson(item)).toList();
    }
    return [];
  }

  static Future<int> completeMission(int missionId) async {
    // ⚠️ IMPORTANT : L'API doit savoir QUI valide. 
    // Pour l'instant ton API UserID est codé en dur à 1 dans le Controller C#.
    // On va laisser comme ça pour l'instant, mais l'idéal serait de passer l'ID.
    final response = await http.post(Uri.parse("$baseUrl/Missions/$missionId/complete"));
    if (response.statusCode == 200) {
       final data = jsonDecode(response.body);
       return data['newScore'];
    }
    throw Exception("Erreur");
  }

  static Future<int> undoMission(int missionId) async {
      final response = await http.post(Uri.parse("$baseUrl/Missions/$missionId/undo"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['newScore'];
      }
      throw Exception("Erreur");
  }
}