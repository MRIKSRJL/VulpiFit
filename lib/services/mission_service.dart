import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mission.dart';

class MissionService {
  // ATTENTION : 
  // Si vous êtes sur Android Emulator, utilisez '10.0.2.2'
  // Si vous êtes sur iPhone Simulator, utilisez 'localhost'
  // Le port 5045 est celui qu'on a vu ensemble en HTTP
  static const String baseUrl = "http://10.0.2.2:5045/api/missions";

  // Fonction pour récupérer la liste
  Future<List<Mission>> getMissions() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // Le serveur a répondu OK !
        List<dynamic> body = jsonDecode(response.body);
        
        // On transforme la liste JSON en liste de Missions
        List<Mission> missions = body
            .map((dynamic item) => Mission.fromJson(item))
            .toList();
            
        return missions;
      } else {
        throw Exception("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Impossible de se connecter à l'API : $e");
    }
  }
}