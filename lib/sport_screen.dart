import 'package:flutter/material.dart';
import '../services/mission_service.dart'; // 👈 On importe le service
import '../models/mission.dart';

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
    _chargerMissions();
  }

  void _chargerMissions() {
    setState(() {
      futureMissions = MissionService.getMissions().then((list) => list.cast<Mission>());
    });
  }

  // 👇 C'EST ICI QUE LA MAGIE OPÈRE
  void _toggleMission(Mission mission) async {
    print("👉 CLIC DÉTECTÉ SUR : ${mission.title}"); // Mouchard 1

    bool etaitDejaFaite = mission.isCompleted;

    // 1. On change visuellement tout de suite pour que ce soit réactif
    setState(() {
      mission.isCompleted = !mission.isCompleted;
    });

    try {
      if (!etaitDejaFaite) {
        // ✅ CAS 1 : On VALIDE la mission
        print("🚀 Envoi ordre VALIDER au service...");
        await MissionService.completeMission(mission.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${mission.title} validée ! (+${mission.points} pts) 🔥"), duration: const Duration(seconds: 1)),
        );
      } else {
        // ↩️ CAS 2 : On ANNULE la mission
        print("↩️ Envoi ordre ANNULER au service...");
        await MissionService.undoMission(mission.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action annulée. Points retirés."), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      // ❌ En cas d'erreur, on remet comme avant
      print("💥 ERREUR DANS L'ÉCRAN : $e");
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
          final sportMissions = missions.where((m) => m.type.contains("Sport")).toList();

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
                    // 👇 On appelle bien notre fonction connectée
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