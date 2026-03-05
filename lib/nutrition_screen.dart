import 'package:flutter/material.dart';
import '../services/mission_service.dart';
import '../models/mission.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  List<Mission> _missionsNutrition = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _chargerMissions();
  }

  // 🛡️ NOUVELLE FONCTION ULTRA ROBUSTE POUR CHARGER ET FILTRER
  Future<void> _chargerMissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      List<dynamic> missionsBrutes = await MissionService.getMissions();
      List<Mission> toutesLesMissions = missionsBrutes.cast<Mission>();

      List<Mission> missionsFiltrees = toutesLesMissions.where((mission) {
        return mission.type.toLowerCase().contains("nutrition");
      }).toList();

      setState(() {
        _missionsNutrition = missionsFiltrees;
        _isLoading = false;
      });
    } catch (e) {
      print("💥 ERREUR LORS DU CHARGEMENT : $e");
      setState(() {
        _errorMessage = "Impossible de charger les missions.";
        _isLoading = false;
      });
    }
  }

  void _toggleMission(Mission mission) async {
    bool etaitDejaFaite = mission.isCompleted;

    setState(() {
      mission.isCompleted = !mission.isCompleted;
    });

    try {
      if (!etaitDejaFaite) {
        bool success = await MissionService.completeMission(mission.id);

        // 🛡️ LE BOUCLIER : Si on a quitté la page, on arrête tout
        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Miam ! ${mission.title} validée ! (+${mission.points} pts) 🍏",
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          setState(() {
            mission.isCompleted = etaitDejaFaite;
          });
        }
      } else {
        bool success = await MissionService.undoMission(mission.id);

        // 🛡️ LE BOUCLIER
        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Annulé. On ne triche pas sur le régime ! 👀"),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          setState(() {
            mission.isCompleted = etaitDejaFaite;
          });
        }
      }
    } catch (e) {
      // 🛡️ LE BOUCLIER ICI AUSSI
      if (!mounted) return;

      setState(() {
        mission.isCompleted = etaitDejaFaite;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
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
              Expanded(child: _buildBody()),
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
                  colors: [Color(0xFF39FF14), Color(0xFF2EE010)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39FF14).withOpacity(0.5),
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
                colors: [Color(0xFF39FF14), Color(0xFF2EE010)],
              ).createShader(bounds),
              child: const Text(
                'MISSIONS NUTRITION 🍎',
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39FF14)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    if (_missionsNutrition.isEmpty) {
      return const Center(
        child: Text(
          "Pas de missions Nutrition pour l'instant.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _missionsNutrition.length,
      itemBuilder: (context, index) {
        final mission = _missionsNutrition[index];
        return _buildMissionCard(mission);
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
                const Color(0xFF39FF14).withOpacity(0.6),
                const Color(0xFF39FF14).withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF39FF14,
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
                color: const Color(0xFF39FF14).withOpacity(0.5),
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
                        const Color(0xFF39FF14).withOpacity(0.3),
                        const Color(0xFF39FF14).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF39FF14).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    mission.isCompleted ? Icons.check_circle : Icons.restaurant,
                    color: const Color(0xFF39FF14),
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
                          ? const Color(0xFF39FF14)
                          : Colors.grey.shade700,
                      width: 2,
                    ),
                    color: mission.isCompleted
                        ? const Color(0xFF39FF14)
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
