import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'mission_success_feedback.dart';
import 'models/mission.dart';
import 'services/mission_service.dart';
import 'widgets/satisfying_mission_button.dart';

class MentalScreen extends StatefulWidget {
  const MentalScreen({super.key});

  @override
  State<MentalScreen> createState() => _MentalScreenState();
}

class _MentalScreenState extends State<MentalScreen> {
  late Future<List<Mission>> futureMissions;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _chargerMissions();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _chargerMissions() {
    setState(() {
      futureMissions = MissionService.getMissions();
    });
  }

  Future<void> _toggleMission(Mission mission) async {
    final etaitDejaFaite = mission.isCompleted;

    setState(() {
      mission.isCompleted = !mission.isCompleted;
    });

    try {
      if (!etaitDejaFaite) {
        final ok = await MissionService.completeMission(mission.id);
        if (!mounted) return;
        if (ok) {
          MissionSuccessFeedback.schedulePlay(_player);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zen… ${mission.title} validée ! (+${mission.points} pts) 🧘'),
              backgroundColor: Colors.deepPurple.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => mission.isCompleted = etaitDejaFaite);
        }
      } else {
        final ok = await MissionService.undoMission(mission.id);
        if (!mounted) return;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Annulé. Respire un bon coup…'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => mission.isCompleted = etaitDejaFaite);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => mission.isCompleted = etaitDejaFaite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion : $e')),
      );
    }
  }

  static const _bg = Color(0xFF060814);
  static const _appBar = Color(0xFF0F1628);
  static const _cyan = Color(0xFF00FFD1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Missions Mental 🧠'),
        backgroundColor: _appBar,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Mission>>(
        future: futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _cyan));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFFFF5252)),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Aucune mission trouvée !',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
            );
          }

          final missions = snapshot.data!;
          final mentalMissions =
              missions.where((m) => m.matchesCategory('mental')).toList();

          if (mentalMissions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Pas de missions Mental pour l'instant.\n"
                  'Vérifie que l’API renvoie le champ Type (ex. Mental).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.4),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: _cyan,
            onRefresh: () async {
              _chargerMissions();
              await futureMissions;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: mentalMissions.length,
              itemBuilder: (context, index) {
                final mission = mentalMissions[index];
                return SatisfyingMissionButton(
                  title: mission.title,
                  points: mission.points,
                  isCompleted: mission.isCompleted,
                  icon: Icons.self_improvement,
                  onTap: () => _toggleMission(mission),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
