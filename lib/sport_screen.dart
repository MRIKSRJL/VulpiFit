import 'package:flutter/material.dart';
import '../services/mission_service.dart'; 
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

  // 🏋️‍♂️ NOUVELLE FONCTION : La Popup de Surcharge Progressive
  Future<void> _showPerformanceDialog(Mission mission) async {
    final TextEditingController weightController = TextEditingController();
    final TextEditingController repsController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit choisir
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Enregistrer la performance 🏋️‍♂️', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Mission :\n${mission.title}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text("Pour que ton IA adapte tes prochaines séances, dis-nous ce que tu as soulevé :", style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Poids (kg)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.monitor_weight, color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Répétitions',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.repeat, color: Colors.orange),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ignorer', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
                // S'il ignore, on valide juste la mission normalement
                _processMissionValidation(mission); 
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Text('Enregistrer et Valider'),
              onPressed: () async {
                // On récupère les valeurs saisies
                double weight = double.tryParse(weightController.text) ?? 0;
                int reps = int.tryParse(repsController.text) ?? 0;

                // On extrait le nom de l'exercice (on enlève les infos de séries/reps du titre de la mission)
                String exerciseName = mission.title.split('-').first.trim();

                // 1. On envoie la performance à la base de données (Surcharge progressive)
                if (weight > 0 || reps > 0) {
                   await MissionService.logExercise(exerciseName, weight, reps);
                }

                Navigator.of(context).pop();
                
                // 2. On valide la mission
                _processMissionValidation(mission);
              },
            ),
          ],
        );
      },
    );
  }

  // ⚙️ L'ancienne fonction coupée en deux pour intégrer la popup
  void _toggleMission(Mission mission) async {
    bool etaitDejaFaite = mission.isCompleted;

    if (!etaitDejaFaite) {
      // Si la mission N'EST PAS FAITE, on affiche la popup d'enregistrement
      _showPerformanceDialog(mission);
    } else {
      // Si elle ÉTAIT DÉJÀ FAITE (Annulation), on annule directement
      _processMissionValidation(mission);
    }
  }

  // 🚀 LA VALIDATION RÉELLE (Appel API)
  void _processMissionValidation(Mission mission) async {
    bool etaitDejaFaite = mission.isCompleted;

    setState(() {
      mission.isCompleted = !mission.isCompleted;
    });

    try {
      if (!etaitDejaFaite) {
        // ✅ CAS 1 : On VALIDE la mission
        await MissionService.completeMission(mission.id);
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${mission.title} validée ! (+${mission.points} pts) 🔥"), duration: const Duration(seconds: 2)),
            );
        }
      } else {
        // ↩️ CAS 2 : On ANNULE la mission
        await MissionService.undoMission(mission.id);
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Action annulée. Points retirés."), duration: Duration(seconds: 2)),
            );
        }
      }
    } catch (e) {
      print("💥 ERREUR DANS L'ÉCRAN : $e");
      setState(() {
        mission.isCompleted = etaitDejaFaite;
      });
      if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur de connexion : $e")),
          );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions Sport 🏋️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune mission de sport trouvée !"));
          }

          final missions = snapshot.data!;
          final sportMissions = missions.where((m) => m.type.contains("Sport")).toList();

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            itemCount: sportMissions.length,
            itemBuilder: (context, index) {
              final mission = sportMissions[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: mission.isCompleted ? 1 : 3,
                color: mission.isCompleted ? Colors.green.shade50 : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mission.isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      mission.isCompleted ? Icons.check_circle : Icons.fitness_center,
                      color: mission.isCompleted ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    mission.title,
                    style: TextStyle(
                      decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("${mission.points} points", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ),
                  trailing: Icon(
                    mission.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                    color: mission.isCompleted ? Colors.green : Colors.grey.shade400,
                    size: 30,
                  ),
                  onTap: () => _toggleMission(mission),
                ),
              );
            },
          );
        },
      ),
    );
  }
}