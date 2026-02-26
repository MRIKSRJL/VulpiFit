import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission.dart';

class MissionService {
  // ⚠️ L'adresse de ton API
  static const String baseUrl = "https://sid-dictational-sensationally.ngrok-free.dev/api"; 

  static int currentUserId = 0; 
  static String currentUserPseudo = "";

  // 1. CONNEXION
  static Future<bool> login(String pseudo, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pseudo": pseudo, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final userData = data['user'] ?? data['User'];
        final tokenString = data['token'] ?? data['Token'];

        currentUserId = userData['id'] ?? userData['Id'];
        currentUserPseudo = userData['pseudo'] ?? userData['Pseudo'];
        
        // 💾 SAUVEGARDE DANS LE TÉLÉPHONE
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', currentUserId);
        
        // 🎟️ On sauvegarde aussi le fameux bracelet VIP !
        if (tokenString != null) {
          await prefs.setString('jwt_token', tokenString);
        }

        return true; 
      }
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['id'];
        currentUserPseudo = data['pseudo'];

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
      final String? token = prefs.getString('jwt_token'); // 🎟️ Le Token
      
      if (userId == null || token == null) return {"pseudo": "Erreur", "score": 0, "streak": 0, "total": 0};

      final response = await http.get(
        Uri.parse("$baseUrl/Users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // 👈 On montre le badge
        },
      );

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
      final String? token = prefs.getString('jwt_token');

      print("🚨 ATTENTION : Le téléphone demande les missions pour l'ID : $userId");

      if (userId == null || token == null) {
        print("🛑 Erreur : Personne n'est connecté ou Token VIP manquant !");
        return [];
      }

      final url = Uri.parse('$baseUrl/Missions/$userId'); 
      
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // 👈
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        print("🟢 SUCCÈS ! ${jsonResponse.length} missions trouvées.");
        return jsonResponse.map((data) => Mission.fromJson(data)).toList();
      } else {
        print("🔴 ERREUR API : ${response.statusCode} - L'accès a été refusé !");
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
      final String? token = prefs.getString('jwt_token');
      
      if (userId == null || token == null) {
        print("🛑 Impossible de valider : aucun utilisateur connecté.");
        return false;
      }

      print("📡 APPEL API VALIDER : POST $baseUrl/Missions/Complete/$missionId?userId=$userId");
      
      final url = Uri.parse('$baseUrl/Missions/Complete/$missionId?userId=$userId');
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token" // 👈
        },
      );

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
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) return false;

      final url = Uri.parse('$baseUrl/Missions/Undo/$missionId?userId=$userId');
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token" // 👈
        },
      ); 

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("💥 ERREUR lors de l'annulation : $e");
      return false;
    }
  }

  // 7. FONCTION ONBOARDING
  static Future<bool> updateOnboarding(double weight, int height, String injuries, String goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); 
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null) {
        print("🛑 Erreur : Aucun ID utilisateur trouvé en mémoire.");
        return false;
      }

      print("📡 Envoi des données d'onboarding pour l'utilisateur $userId...");
      
      final bodyData = jsonEncode({
        'Weight': weight,
        'Height': height,
        'Injuries': injuries,
        'Goals': goals,
      });
      
      final response = await http.put(
        Uri.parse('$baseUrl/Users/$userId/onboarding'),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token" // 👈
        },
        body: bodyData,
      );

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
          "Authorization": "Bearer $token" // 👈
        },
        body: jsonEncode({
          'FeedbackText': feedback,
          'DifficultyLevel': difficulty,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Erreur feedback: $e");
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
      print("📡 DEMANDE ROADMAP : GET $endpoint");

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // 👈
        }
      );
      
      print("📩 RÉPONSE ROADMAP : Code ${response.statusCode}");
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("⚠️ Problème API : ${response.body}");
      }
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
          "Authorization": "Bearer $token" // 👈 Toujours notre vigile !
        },
        body: jsonEncode({
          "UserId": userId,
          "ExerciseName": exerciseName,
          "Weight": weight,
          "Reps": reps
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("💥 ERREUR lors de l'enregistrement de l'exercice : $e");
      return false;
    }
  }
}