import 'package:flutter/material.dart';
import 'services/mission_service.dart';
import 'models/mission.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Mission>> futureMissions;

  @override
  void initState() {
    super.initState();
    futureMissions = MissionService.getMissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil 🦊'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final missions = snapshot.data!;
          
          // --- CALCUL DU SCORE ---
          int totalScore = 0;
          int missionsCount = 0;
          
          for (var mission in missions) {
            if (mission.isCompleted) {
              totalScore += mission.points;
              missionsCount++;
            }
          }

          // --- NIVEAU ---
          String niveau = "Renard Débutant 🐣";
          if (totalScore > 50) niveau = "Renard Rusé 🦊";
          if (totalScore > 100) niveau = "Renard Légendaire 🔥";

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.person, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  "$totalScore points",
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text(
                  niveau,
                  style: const TextStyle(fontSize: 22, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text("$missionsCount missions accomplies"),
              ],
            ),
          );
        },
      ),
    );
  }
}