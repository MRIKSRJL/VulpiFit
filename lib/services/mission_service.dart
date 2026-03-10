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
      print("🟡 Tentative de connexion pour '$pseudo'...");
      final response = await http.post(
        Uri.parse("$baseUrl/Users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pseudo": pseudo, "password": password}),
      ).timeout(const Duration(seconds: 30));

      print("🔵 Réponse Azure (Login) : Code ${response.statusCode} | Message : ${response.body}");

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
        print("🟢 Connexion réussie ! Token et ID sauvegardés.");
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

  // 2. INSCRIPTION CORRIGÉE 
  static Future<bool> register(String pseudo, String password) async {
    try {
      print("🟡 Tentative de création de compte pour '$pseudo'...");
      final response = await http.post(
        Uri.parse("$baseUrl/Users"), // 👈 C'est ICI qu'était l'erreur (pas de /Auth/register)
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pseudo": pseudo, "password": password}),
      ).timeout(const Duration(seconds: 30));

      print("🔵 Réponse Azure (Register) : Code ${response.statusCode} | Message : ${response.body}");

      if (response.statusCode == 201) {
        print("🟢 Compte créé avec succès ! On lance la connexion automatique...");
        // 🚀 On lance le Login juste après pour récupérer le Token VIP vital
        return await login(pseudo, password);
      } else {
        print("🔴 Échec de l'inscription. Azure a refusé.");
        return false;
      }
    } on SocketException {
      print("📶 Pas de connexion internet");
      return false;
    } on TimeoutException {
      print("🐢 Délai d'attente dépassé");
      return false;
    } catch (e) {
      print("❌ Erreur Register: $e");
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
      ).timeout(const Duration(seconds: 30)); // ⏱️ Bouclier 30 secondes

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

  // 11. SUPPRIMER LE COMPTE DÉFINITIVEMENT
  static Future<bool> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('userId');
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) return false;

      print("🟡 Tentative de suppression du compte ID: $userId");

      final response = await http.delete(
        Uri.parse('$baseUrl/Users/$userId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // On envoie le bracelet VIP par sécurité
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 204 || response.statusCode == 200) {
        print("🟢 Compte désintégré avec succès !");
        return true;
      } else {
        print("🔴 Échec suppression : Code ${response.statusCode} | Erreur : ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Erreur Flutter lors de la suppression : $e");
      return false;
    }
  }
}