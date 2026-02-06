import 'package:flutter/material.dart';
import 'services/mission_service.dart';
import 'models/mission.dart';

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
    futureMissions = MissionService.getMissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions Nutrition 🍎'), // Titre changé
        backgroundColor: Colors.green, // Couleur verte pour la nutrition
      ),
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune mission trouvée !"));
          }

          final missions = snapshot.data!;
          
          return ListView.builder(
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];

              // 👇 LE FILTRE MAGIQUE : On ne garde que "Nutrition"
              if (mission.type != "Nutrition") return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(
                    mission.isCompleted ? Icons.check_circle : Icons.restaurant, // Icône restaurant
                    color: mission.isCompleted ? Colors.green : Colors.orange,
                  ),
                  title: Text(mission.title),
                  subtitle: Text("${mission.points} points"),
                  trailing: mission.isCompleted 
                    ? const Text("Validé ✅") 
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                        child: const Text("Manger !"),
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