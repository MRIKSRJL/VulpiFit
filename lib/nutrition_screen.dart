import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'mission_success_feedback.dart';
import 'models/mission.dart';
import 'services/mission_service.dart';
import 'widgets/satisfying_mission_button.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  List<Mission> _missionsNutrition = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _chargerMissions();
  }

  Future<void> _chargerMissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final toutesLesMissions = await MissionService.getMissions();
      final missionsFiltrees =
          toutesLesMissions.where((m) => m.matchesCategory('nutrition')).toList();

      setState(() {
        _missionsNutrition = missionsFiltrees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les missions.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMission(Mission mission) async {
    final etaitDejaFaite = mission.isCompleted;

    setState(() {
      mission.isCompleted = !mission.isCompleted;
    });

    try {
      if (!etaitDejaFaite) {
        final success = await MissionService.completeMission(mission.id);
        if (!mounted) return;

        if (success) {
          MissionSuccessFeedback.schedulePlay(_player);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Miam ! ${mission.title} validée ! (+${mission.points} pts) 🍏'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => mission.isCompleted = etaitDejaFaite);
        }
      } else {
        final success = await MissionService.undoMission(mission.id);
        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Annulé. On ne triche pas sur le régime ! 👀'),
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
        SnackBar(content: Text('Erreur : $e')),
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
        title: const Text('Missions Nutrition 🥗'),
        backgroundColor: _appBar,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _cyan));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFF5252), fontSize: 16),
          ),
        ),
      );
    }

    if (_missionsNutrition.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "Pas de missions Nutrition pour l'instant.\n"
            'Vérifie que l’API renvoie le champ Type (ex. Nutrition).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.4),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _cyan,
      onRefresh: _chargerMissions,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: _missionsNutrition.length,
        itemBuilder: (context, index) {
          final mission = _missionsNutrition[index];
          return SatisfyingMissionButton(
            title: mission.title,
            points: mission.points,
            isCompleted: mission.isCompleted,
            icon: Icons.restaurant_menu,
            onTap: () => _toggleMission(mission),
          );
        },
      ),
    );
  }
}
