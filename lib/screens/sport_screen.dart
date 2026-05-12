import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../mission_success_feedback.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../widgets/satisfying_mission_button.dart';

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  late Future<List<Mission>> futureMissions;
  late ConfettiController _confettiController;
  final AudioPlayer _victoryPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1500),
    );
    _chargerMissions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _victoryPlayer.dispose();
    super.dispose();
  }

  void _chargerMissions() {
    setState(() {
      futureMissions = MissionService.getMissions();
    });
  }

  Future<void> _celebrateVictory() async {
    if (!mounted) return;
    MissionSuccessFeedback.schedulePlay(_victoryPlayer);
    if (!mounted) return;
    _confettiController.play();
  }

  Future<void> _showPerformanceDialog(Mission mission) async {
    final weightController = TextEditingController();
    final repsController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final primary = Theme.of(context).colorScheme.primary;
        return AlertDialog(
          backgroundColor: const Color(0xFF12182A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: primary.withValues(alpha: 0.45), width: 0.5),
          ),
          title: Text(
            'Enregistrer la performance',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Poids (kg)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Icon(Icons.monitor_weight, color: Theme.of(context).colorScheme.primary),
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
                          prefixIcon: Icon(Icons.repeat, color: Theme.of(context).colorScheme.primary),
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
              onPressed: () {
                Navigator.of(context).pop();
                _processMissionValidation(mission);
              },
              child: const Text('Ignorer'),
            ),
            FilledButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text) ?? 0;
                final reps = int.tryParse(repsController.text) ?? 0;
                final exerciseName = mission.title.split('-').first.trim();
                if (weight > 0 || reps > 0) {
                  await MissionService.logExercise(exerciseName, weight, reps);
                }
                if (context.mounted) Navigator.of(context).pop();
                _processMissionValidation(mission);
              },
              child: const Text('Enregistrer et valider'),
            ),
          ],
        );
      },
    );
  }

  void _toggleMission(Mission mission) {
    final wasDone = mission.isCompleted;
    if (!wasDone) {
      // TODO: V1.1 - Reactiver saisie performance (poids/reps)
      _processMissionValidation(mission);
    } else {
      _processMissionValidation(mission);
    }
  }

  Future<void> _processMissionValidation(Mission mission) async {
    final wasDone = mission.isCompleted;

    setState(() {
      mission.isCompleted = !mission.isCompleted;
    });

    try {
      if (!wasDone) {
        await MissionService.completeMission(mission.id);
        await _celebrateVictory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${mission.title} validée ! (+${mission.points} pts)'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        await MissionService.undoMission(mission.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Action annulée. Points retirés.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        mission.isCompleted = wasDone;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  static const _neonBg = Color(0xFF060814);
  static const _neonAppBar = Color(0xFF0F1628);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: _neonBg,
      appBar: AppBar(
        backgroundColor: _neonAppBar,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, color: primary, size: 22),
            const SizedBox(width: 8),
            const Text('Missions Sport'),
            const SizedBox(width: 6),
            Text('·', style: TextStyle(color: secondary.withValues(alpha: 0.9))),
            const SizedBox(width: 6),
            Text(
              'Sport',
              style: TextStyle(
                color: secondary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Mission>>(
            future: futureMissions,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primary));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: TextStyle(color: secondary.withValues(alpha: 0.9)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'Aucune mission sport.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                  ),
                );
              }

              final sportMissions =
                  snapshot.data!.where((m) => m.matchesCategory('sport')).toList();
              if (sportMissions.isEmpty) {
                return Center(
                  child: Text(
                    'Aucune mission de sport trouvée.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                  ),
                );
              }

              return RefreshIndicator(
                color: primary,
                onRefresh: () async => _chargerMissions(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 120),
                  itemCount: sportMissions.length,
                  itemBuilder: (context, index) {
                    final mission = sportMissions[index];
                    return SatisfyingMissionButton(
                      title: mission.title,
                      points: mission.points,
                      isCompleted: mission.isCompleted,
                      icon: Icons.fitness_center,
                      onTap: () => _toggleMission(mission),
                    );
                  },
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.08,
              numberOfParticles: 55,
              maxBlastForce: 120,
              minBlastForce: 25,
              gravity: 0.12,
              colors: const [
                Color(0xFF00FFD1),
                Color(0xFFFF2D95),
                Color(0xFFFFC400),
                Color(0xFF7C4DFF),
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
