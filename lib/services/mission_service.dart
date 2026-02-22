import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission.dart';

class MissionService {
  // ⚠️ L'adresse de ton API
  static const String baseUrl = "http://10.210.25.217:5045/api"; 

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
        
        // 👇 CORRECTION MAJEURE : On sauvegarde l'ID dans le téléphone !
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', currentUserId);

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

        // 👇 On sauvegarde aussi à l'inscription
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', currentUserId);

        return true;
      }
      return false;
    } catch (e) {
      print("Erreur Register: $e");
      return false;
    }
  }

  // 3. STATISTIQUES UTILISATEUR
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      
      if (userId == null) return {"pseudo": "Erreur", "score": 0, "streak": 0, "total": 0};

      final response = await http.get(Uri.parse("$baseUrl/Users"));

      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(response.body);
        var user = users.firstWhere((u) => u['id'] == userId, orElse: () => null);

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

  // 4. RÉCUPÉRER LES MISSIONS
  static Future<List<Mission>> getMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');

      print("🚨 ATTENTION : Le téléphone demande les missions pour l'ID : $userId");

      if (userId == null) {
        print("🛑 Erreur : Personne n'est connecté !");
        return [];
      }

      final url = Uri.parse('$baseUrl/Missions/$userId'); 
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        print("🟢 SUCCÈS ! ${jsonResponse.length} missions trouvées.");
        return jsonResponse.map((data) => Mission.fromJson(data)).toList();
      } else {
        print("🔴 ERREUR API : ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("💥 ERREUR CRITIQUE DANS GETMISSIONS : $e");
      return [];
    }
  }

  // 5. VALIDER UNE MISSION
  static Future<bool> completeMission(int missionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      
      if (userId == null) {
        print("🛑 Impossible de valider : aucun utilisateur connecté.");
        return false;
      }

      print("📡 APPEL API VALIDER : POST $baseUrl/Missions/Complete/$missionId?userId=$userId");
      
      final url = Uri.parse('$baseUrl/Missions/Complete/$missionId?userId=$userId');
      final response = await http.post(url);

      print("📩 RÉPONSE API VALIDER (Code ${response.statusCode}) : ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("💥 ERREUR CRITIQUE lors de la validation : $e");
      return false;
    }
  }

  // 6. ANNULER UNE MISSION
  static Future<bool> undoMission(int missionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');

      if (userId == null) return false;

      final url = Uri.parse('$baseUrl/Missions/Undo/$missionId?userId=$userId');
      final response = await http.post(url); 

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("💥 ERREUR lors de l'annulation : $e");
      return false;
    }
  }

  // 👇 FONCTION ONBOARDING CORRIGÉE ET BAVARDE
  static Future<bool> updateOnboarding(double weight, int height, String injuries, String goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); 

      if (userId == null) {
        print("🛑 Erreur : Aucun ID utilisateur trouvé en mémoire.");
        return false;
      }

      print("📡 Envoi des données d'onboarding pour l'utilisateur $userId...");
      
      final bodyData = jsonEncode({
        'Weight': weight,      // Majuscules pour s'aligner parfaitement avec l'API C#
        'Height': height,
        'Injuries': injuries,
        'Goals': goals,
      });
      
      print("📦 Body envoyé : $bodyData");

      final response = await http.put(
        Uri.parse('$baseUrl/Users/$userId/onboarding'),
        headers: {'Content-Type': 'application/json'},
        body: bodyData,
      );

      print("📨 Réponse de l'API - Code : ${response.statusCode}");
      
      // 200 = OK, 204 = No Content (succès mais sans texte en retour, très commun en C#)
      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ Onboarding mis à jour avec succès !");
        return true;
      } else {
        print("❌ Erreur API Onboarding : ${response.body}");
        return false;
      }
    } catch (e) {
      print("💥 Erreur de connexion : $e");
      return false;
    }
  }
}