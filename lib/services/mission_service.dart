import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mission.dart';

class MissionService {
  // ✅ On garde l'adresse qui marche avec ton câble USB
  static const String baseUrl = "http://127.0.0.1:5045/api/missions";

  // 1. GET : Récupérer les missions
  static Future<List<Mission>> getMissions() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Mission.fromJson(item)).toList();
      } else {
        throw Exception("Échec du chargement des missions");
      }
    } catch (e) {
      throw Exception("Erreur connexion (As-tu fait 'adb reverse' ?) : $e");
    }
  }

  // 2. POST : VALIDER une mission (Gagner des points 🏆)
// 👇 REMPLACE TA FONCTION completeMission PAR CELLE-CI
  static Future<int> completeMission(int missionId) async {
    final String url = "$baseUrl/$missionId/complete";
    print("📢 CLICK : Tentative de validation vers $url"); // <--- MOUCHARD 1

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      print("📢 RÉPONSE SERVEUR : ${response.statusCode}"); // <--- MOUCHARD 2

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

  // 3. POST : ANNULER une mission (Perdre des points ↩️)
static Future<int> undoMission(int missionId) async {
    final String url = "$baseUrl/$missionId/undo";
    print("📢 APPEL API : $url"); // <--- LE MOUCHARD

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    print("📢 RÉPONSE CODE : ${response.statusCode}"); // <--- LE DEUXIÈME MOUCHARD
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['newScore'];
    } else {
      print("❌ ERREUR CORPS : ${response.body}");
      throw Exception('Erreur annulation');
    }
  }
  
  // (Optionnel) updateMission peut rester si tu t'en sers ailleurs, 
  // mais pour le score, utilise completeMission.
  static Future<void> updateMission(Mission mission) async {
    // ... ton ancien code PUT ...
  }
  // 👇 AJOUTE CETTE FONCTION à la fin de MissionService
  
static Future<int> getScore() async {
    try {
      final response = await http.get(Uri.parse("http://127.0.0.1:5045/api/Users"));

      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(response.body);
        
        // 👀 MOUCHARD : On affiche tout ce qu'on trouve pour comprendre
        print("🔍 LISTE UTILISATEURS REÇUE : $users");

        // 👇 ON CHERCHE L'UTILISATEUR N°1 (C'est lui le vrai FoxWarrior)
        // firstWhere cherche l'élément qui a l'id 1.
        var monUtilisateur = users.firstWhere(
          (user) => user['id'] == 1, 
          orElse: () => null // Si on ne le trouve pas
        );

        if (monUtilisateur != null) {
          print("✅ Utilisateur 1 trouvé avec score : ${monUtilisateur['score']}");
          return monUtilisateur['score'];
        } else {
          // Si l'ID 1 n'existe pas, on prend le premier de la liste par défaut
          print("⚠️ Utilisateur 1 introuvable ! On prend le premier de la liste.");
          if (users.isNotEmpty) return users[0]['score'];
        }
        
        return 0;
      } else {
        throw Exception("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      print("🔴 Erreur récupération score : $e");
      return 0; // En cas d'erreur, on affiche 0 pour ne pas faire planter l'app
    }
  }
}