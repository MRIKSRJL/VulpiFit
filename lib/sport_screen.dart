import 'package:flutter/material.dart';
import '../services/mission_service.dart'; // 👈 On importe le bon fichier
import '../models/mission.dart'; // Vérifie que le chemin est bon

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  late Future<List<Mission>> futureMissions;

  @override
  void initState() {
    super.initState();
    // 👇 On utilise le nom de ta classe réelle
    futureMissions = MissionService.getMissions(); 
  }

  void _toggleMission(Mission mission) async {
    bool etaitValidee = mission.isCompleted;

    // Mise à jour visuelle immédiate
    setState(() {
      mission.isCompleted = !mission.isCompleted;
    });

    try {
      if (mission.isCompleted) {
        // ✅ Validation via MissionService
        // Note: Assure-toi que updateMission ou completeMission existe dans ton service
        await MissionService.updateMission(mission); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${mission.title} validée ! 🔥"), duration: const Duration(seconds: 1)),
        );
      } else {
        // ↩️ Annulation via MissionService
        // 👇 C'est ici qu'on appelle la nouvelle méthode
        await MissionService.undoMission(mission.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action annulée ↩️"), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      // En cas d'erreur, on annule le changement visuel
      setState(() {
        mission.isCompleted = etaitValidee;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion (Vérifie ADB) : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions Sport 🏋️'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune mission de sport trouvée !"));
          }

          final missions = snapshot.data!;
          // Filtre pour ne garder que le sport
          final sportMissions = missions.where((m) => m.type == "Sport").toList();

          return ListView.builder(
            itemCount: sportMissions.length,
            itemBuilder: (context, index) {
              final mission = sportMissions[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: mission.isCompleted ? Colors.green.shade100 : Colors.white,
                child: ListTile(
                  leading: Icon(
                    mission.isCompleted ? Icons.check_circle : Icons.fitness_center,
                    color: mission.isCompleted ? Colors.green : Colors.orange,
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