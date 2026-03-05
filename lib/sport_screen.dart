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
      futureMissions = MissionService.getMissions().then(
        (list) => list.cast<Mission>(),
      );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Enregistrer la performance 🏋️‍♂️',
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Mission :\n${mission.title}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Pour que ton IA adapte tes prochaines séances, dis-nous ce que tu as soulevé :",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Poids (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                            Icons.monitor_weight,
                            color: Colors.orange,
                          ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                            Icons.repeat,
                            color: Colors.orange,
                          ),
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
              child: const Text(
                'Ignorer',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // S'il ignore, on valide juste la mission normalement
                _processMissionValidation(mission);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${mission.title} validée ! (+${mission.points} pts) 🔥",
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // ↩️ CAS 2 : On ANNULE la mission
        await MissionService.undoMission(mission.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Action annulée. Points retirés."),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print("💥 ERREUR DANS L'ÉCRAN : $e");
      setState(() {
        mission.isCompleted = etaitDejaFaite;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de connexion : $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildMissionsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F5FF), Color(0xFF00D4FF)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F5FF).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00F5FF), Color(0xFF00D4FF)],
              ).createShader(bounds),
              child: const Text(
                'MISSIONS SPORT 🏋️',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsList() {
    return FutureBuilder<List<Mission>>(
      future: futureMissions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00F5FF)),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Erreur: ${snapshot.error}",
              style: const TextStyle(color: Colors.white),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "Aucune mission de sport trouvée !",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final missions = snapshot.data!;
        final sportMissions = missions
            .where((m) => m.type.contains("Sport"))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: sportMissions.length,
          itemBuilder: (context, index) {
            final mission = sportMissions[index];
            return _buildMissionCard(mission);
          },
        );
      },
    );
  }

  Widget _buildMissionCard(Mission mission) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _toggleMission(mission),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00F5FF).withOpacity(0.6),
                const Color(0xFF00F5FF).withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00F5FF,
                ).withOpacity(mission.isCompleted ? 0.4 : 0.2),
                blurRadius: 20,
                spreadRadius: mission.isCompleted ? 3 : 0,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF00F5FF).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00F5FF).withOpacity(0.3),
                        const Color(0xFF00F5FF).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00F5FF).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    mission.isCompleted
                        ? Icons.check_circle
                        : Icons.fitness_center,
                    color: const Color(0xFF00F5FF),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: mission.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFFA94D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${mission.points} points",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: mission.isCompleted
                          ? const Color(0xFF00F5FF)
                          : Colors.grey.shade700,
                      width: 2,
                    ),
                    color: mission.isCompleted
                        ? const Color(0xFF00F5FF)
                        : Colors.transparent,
                  ),
                  child: mission.isCompleted
                      ? const Icon(Icons.check, color: Colors.black, size: 20)
                      : const SizedBox(width: 20, height: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
