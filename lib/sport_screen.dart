import 'package:flutter/material.dart';
import 'services/mission_service.dart';
import 'models/mission.dart';

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  // Cette liste va contenir les missions reçues de l'API
  late Future<List<Mission>> futureMissions;

  @override
  void initState() {
    super.initState();
    // Au démarrage de l'écran, on lance le chargement des missions
    futureMissions = MissionService.getMissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions Sport'),
        backgroundColor: Colors.orange,
      ),
      // FutureBuilder est un widget magique qui attend que les données arrivent
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          // 1. Si ça charge encore, on affiche un rond qui tourne
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // 2. S'il y a une erreur (ex: API éteinte)
          else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } 
          // 3. Si on a des données mais que la liste est vide
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune mission de sport trouvée !"));
          }

          // 4. Si tout est bon, on affiche la liste
          final missions = snapshot.data!;
          
          return ListView.builder(
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              // On n'affiche que les missions de type "Sport"
              if (mission.type != "Sport") return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(
                    mission.isCompleted ? Icons.check_circle : Icons.fitness_center,
                    color: mission.isCompleted ? Colors.green : Colors.orange,
                  ),
                  title: Text(mission.title),
                  subtitle: Text("${mission.points} points"),
                  trailing: mission.isCompleted 
                    ? const Text("Validé ✅") 
                    : ElevatedButton(
                        onPressed: () async {
                          // 1. On change l'état localement pour que ce soit réactif
                        setState(() {
                          mission.isCompleted = true;
                      });

                      // 2. On envoie l'info au serveur
                      try {
                        await MissionService.updateMission(mission);
                        print("Mission ${mission.title} validée en base de données !");
                      } catch (e) {
                        // Si ça plante, on remet comme avant et on affiche une erreur
                      setState(() {
                        mission.isCompleted = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erreur de connexion : $e")),
                      );
                    }
                  }, 
                        child: const Text("Valider"),
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