import 'package:flutter/material.dart';
import '../services/mission_service.dart';
import '../models/mission.dart';

class MentalScreen extends StatefulWidget {
  const MentalScreen({super.key});

  @override
  State<MentalScreen> createState() => _MentalScreenState();
}

class _MentalScreenState extends State<MentalScreen> {
  late Future<List<Mission>> futureMissions;

  @override
  void initState() {
    super.initState();
    _chargerMissions();
  }

  void _chargerMissions() {
    setState(() {
      futureMissions = MissionService.getMissions().then((list) => 
        list.cast<Mission>()
      );
    });
  }

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
            content: Text("Zen... ${mission.title} validée ! (+${mission.points} pts) 🧘"), 
            backgroundColor: Colors.purple, // Thème Violet
            duration: const Duration(seconds: 1)
          ),
        );
      } else {
        // ↩️ On ANNULE
        await MissionService.undoMission(mission.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Annulé. Respire un bon coup..."), duration: Duration(seconds: 1)),
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
        title: const Text('Missions Mental 🧠'),
        backgroundColor: Colors.purple, // Thème Violet
      ),
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purple));
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune mission trouvée !"));
          }

          final missions = snapshot.data!;
          
          // 👇 LE FILTRE MAGIQUE : On ne garde que "Mental"
          final mentalMissions = missions.where((m) => m.type == "Mental").toList();

          if (mentalMissions.isEmpty) {
            return const Center(
              child: Text("Pas de missions Mental pour l'instant.\nAjoutes-en via Swagger !", textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            itemCount: mentalMissions.length,
            itemBuilder: (context, index) {
              final mission = mentalMissions[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: mission.isCompleted ? Colors.purple.shade100 : Colors.white,
                child: ListTile(
                  leading: Icon(
                    mission.isCompleted ? Icons.check_circle : Icons.self_improvement, // Icône Zen
                    color: mission.isCompleted ? Colors.purple : Colors.purple.shade300,
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
                    color: mission.isCompleted ? Colors.purple : Colors.grey,
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