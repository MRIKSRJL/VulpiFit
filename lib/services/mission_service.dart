import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission.dart';
import 'dart:io';    // 🛡️ Pour détecter les coupures réseau (SocketException)
import 'dart:async'; // ⏱️ Pour gérer le chronomètre (TimeoutException)

class MissionService {
  static const String baseUrl = "https://fitnessfoxapi20260301200033-agegbhcpfqdvhaep.canadacentral-01.azurewebsites.net/api"; 

  static int currentUserId = 0; 
  static String currentUserPseudo = "";

  // 1. CONNEXION
  static Future<bool> login(String pseudo, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pseudo": pseudo, "password": password}),
      ).timeout(const Duration(seconds: 30)); // ⏱️ Bouclier chrono

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['user'] ?? data['User'];
        final tokenString = data['token'] ?? data['Token'];

        currentUserId = userData['id'] ?? userData['Id'];
        currentUserPseudo = userData['pseudo'] ?? userData['Pseudo'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', currentUserId);
        
        if (tokenString != null) {
          await prefs.setString('jwt_token', tokenString);
        }
        return true; 
      }
      return false; 
    } on SocketException {
      print("📶 Pas de connexion internet");
      return false;
    } on TimeoutException {
      print("🐢 Délai d'attente dépassé");
      return false;
    } catch (e) {
      print("❌ Erreur Login: $e");
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
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['id'];
        currentUserPseudo = data['pseudo'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', currentUserId);
        return true;
      }
      return false;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }

  // 3. STATISTIQUES UTILISATEUR
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      final String? token = prefs.getString('jwt_token'); 
      
      if (userId == null || token == null) return {"pseudo": "Erreur", "score": 0, "streak": 0, "total": 0};

      final response = await http.get(
        Uri.parse("$baseUrl/Users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      ).timeout(const Duration(seconds: 30));

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

  // 4. RÉCUPÉRER LES MISSIONS (AVEC RENVOI D'ERREURS AU FUTUR BUILDER)
  static Future<List<Mission>> getMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) {
        throw "Personne n'est connecté ou Token VIP manquant !";
      }

      final url = Uri.parse('$baseUrl/Missions/$userId'); 
      
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      ).timeout(const Duration(seconds: 30)); // ⏱️ Bouclier 10 secondes

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Mission.fromJson(data)).toList();
      } else {
        throw "Erreur serveur : ${response.statusCode}";
      }
    } on SocketException {
      throw "Pas de connexion internet 📶. Vérifie ton réseau !";
    } on TimeoutException {
      throw "Le coach IA met trop de temps à répondre 🐢.";
    } catch (e) {
      throw "Une erreur est survenue : $e";
    }
  }

  // 5. VALIDER UNE MISSION (ROBUSTE)
  static Future<bool> completeMission(int missionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      final String? token = prefs.getString('jwt_token');
      
      if (userId == null || token == null) throw "Aucun utilisateur connecté.";

      final url = Uri.parse('$baseUrl/Missions/Complete/$missionId?userId=$userId');
      final response = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw "Erreur serveur : ${response.statusCode}";
      }
    } on SocketException {
      throw "Pas de connexion internet 📶. Impossible de valider.";
    } on TimeoutException {
      throw "Délai d'attente dépassé 🐢.";
    } catch (e) {
      throw e.toString();
    }
  }

  // 6. ANNULER UNE MISSION (ROBUSTE)
  static Future<bool> undoMission(int missionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) throw "Erreur d'authentification";

      final url = Uri.parse('$baseUrl/Missions/Undo/$missionId?userId=$userId');
      final response = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
      ).timeout(const Duration(seconds: 30)); 

      if (response.statusCode == 200 || response.statusCode == 204) return true;
      throw "Erreur serveur";
    } on SocketException {
      throw "Pas de connexion internet 📶.";
    } on TimeoutException {
      throw "Délai d'attente dépassé 🐢.";
    } catch (e) {
      throw e.toString();
    }
  }

  // 7. FONCTION ONBOARDING
  static Future<bool> updateOnboarding(double weight, int height, String injuries, String goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); 
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) return false;
      
      final response = await http.put(
        Uri.parse('$baseUrl/Users/$userId/onboarding'),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({'Weight': weight, 'Height': height, 'Injuries': injuries, 'Goals': goals}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // 8. ENVOYER LE BILAN
  static Future<bool> sendDailyFeedback(String feedback, int difficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/Users/$userId/feedback'),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({'FeedbackText': feedback, 'DifficultyLevel': difficulty}),
      ).timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 9. RÉCUPÉRER LA PROGRESSION (ROADMAP)
  static Future<List<dynamic>> getUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) return [];

      final String endpoint = '$baseUrl/Users/$userId/progress'; 

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("❌ ERREUR FLUTTER (Roadmap) : $e");
    }
    return [];
  }

  // 10. ENREGISTRER UNE PERFORMANCE (SURCHARGE PROGRESSIVE)
  static Future<bool> logExercise(String exerciseName, double weight, int reps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) return false;

      final url = Uri.parse('$baseUrl/Exercises/log');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "UserId": userId,
          "ExerciseName": exerciseName,
          "Weight": weight,
          "Reps": reps
        }),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("💥 ERREUR lors de l'enregistrement de l'exercice : $e");
      return false;
    }
  }
}