import 'package:flutter/material.dart';
import 'services/mission_service.dart';
import 'models/mission.dart';

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
    futureMissions = MissionService.getMissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions Mental 🧠'),
        backgroundColor: Colors.deepPurple, // Couleur violette
        foregroundColor: Colors.white, // Texte blanc
      ),
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune mission mentale trouvée !"));
          }

          final missions = snapshot.data!;
          
          return ListView.builder(
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];

              // 👇 FILTRE : On ne garde que "Mental"
              if (mission.type != "Mental") return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(
                    mission.isCompleted ? Icons.check_circle : Icons.self_improvement, // Icône méditation/yoga
                    color: mission.isCompleted ? Colors.green : Colors.deepPurple,
                  ),
                  title: Text(mission.title),
                  subtitle: Text("${mission.points} points"),
                  trailing: mission.isCompleted 
                    ? const Text("Validé ✅") 
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                        onPressed: () async {
                          setState(() {
                             mission.isCompleted = true;
                          });
                          try {
                            await MissionService.updateMission(mission);
                          } catch (e) {
                            setState(() {
                              mission.isCompleted = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erreur : $e")),
                            );
                          }
                        }, 
                        child: const Text("Fait !"),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}