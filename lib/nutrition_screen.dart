import 'package:flutter/material.dart';
import '../services/mission_service.dart'; // On réutilise le même service !
import '../models/mission.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late Future<List<Mission>> futureMissions;

  @override
  void initState() {
    super.initState();
    _chargerMissions();
  }

  void _chargerMissions() {
    setState(() {
      futureMissions = MissionService.getMissions().then((data) => 
        List<Mission>.from(data.map((item) => Mission.fromJson(item as Map<String, dynamic>)))
      );
    });
  }

  // 👇 Exactement la même logique que pour le Sport
  void _toggleMission(Mission mission) async {
    bool etaitDejaFaite = mission.isCompleted;

    setState(() {
      mission.isCompleted = !mission.isCompleted;
    });

    try {
      if (!etaitDejaFaite) {
        // ✅ On VALIDE
        await MissionService.completeMission(mission.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Miam ! ${mission.title} validée ! (+${mission.points} pts) 🍏"), 
            backgroundColor: Colors.green, // On met du vert pour la nutrition
            duration: const Duration(seconds: 1)
          ),
        );
      } else {
        // ↩️ On ANNULE
        await MissionService.undoMission(mission.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Annulé. On ne triche pas sur le régime ! 👀"), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      setState(() {
        mission.isCompleted = etaitDejaFaite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions Nutrition 🥗'),
        backgroundColor: Colors.green, // Thème Vert
      ),
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune mission trouvée !"));
          }

          final missions = snapshot.data!;
          
          // 👇 LE FILTRE MAGIQUE : On ne garde que "Nutrition"
          final nutritionMissions = missions.where((m) => m.type == "Nutrition").toList();

          if (nutritionMissions.isEmpty) {
            return const Center(
              child: Text("Pas de missions Nutrition pour l'instant.\nAjoutes-en via Swagger !", textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            itemCount: nutritionMissions.length,
            itemBuilder: (context, index) {
              final mission = nutritionMissions[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                // Couleur vert clair si validé
                color: mission.isCompleted ? Colors.green.shade100 : Colors.white,
                child: ListTile(
                  leading: Icon(
                    // Icône différente selon l'état
                    mission.isCompleted ? Icons.check_circle : Icons.restaurant_menu,
                    color: mission.isCompleted ? Colors.green : Colors.green.shade300,
                    size: 30,
                  ),
                  title: Text(
                    mission.title,
                    style: TextStyle(
                      decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text("${mission.points} points"),
                  trailing: Icon(
                    mission.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                    color: mission.isCompleted ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    _toggleMission(mission);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}