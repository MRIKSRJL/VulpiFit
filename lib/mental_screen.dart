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
      futureMissions = MissionService.getMissions().then(
        (list) => list.cast<Mission>(),
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

        // 🛡️ LE BOUCLIER
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Zen... ${mission.title} validée ! (+${mission.points} pts) 🧘",
            ),
            backgroundColor: Colors.purple, // Thème Violet
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        // ↩️ On ANNULE
        await MissionService.undoMission(mission.id);

        // 🛡️ LE BOUCLIER
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Annulé. Respire un bon coup..."),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // 🛡️ LE BOUCLIER ICI AUSSI
      if (!mounted) return;

      setState(() {
        mission.isCompleted = etaitDejaFaite;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de connexion : $e")));
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
                  colors: [Color(0xFFBF00FF), Color(0xFFA000E0)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBF00FF).withOpacity(0.5),
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
                colors: [Color(0xFFBF00FF), Color(0xFFA000E0)],
              ).createShader(bounds),
              child: const Text(
                'MISSIONS MENTAL 🧠',
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
            child: CircularProgressIndicator(color: Color(0xFFBF00FF)),
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
              "Aucune mission trouvée !",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final missions = snapshot.data!;
        final mentalMissions = missions
            .where((m) => m.type.contains("Mental"))
            .toList();

        if (mentalMissions.isEmpty) {
          return const Center(
            child: Text(
              "Pas de missions Mental pour l'instant.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: mentalMissions.length,
          itemBuilder: (context, index) {
            final mission = mentalMissions[index];
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
                const Color(0xFFBF00FF).withOpacity(0.6),
                const Color(0xFFBF00FF).withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFBF00FF,
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
                color: const Color(0xFFBF00FF).withOpacity(0.5),
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
                        const Color(0xFFBF00FF).withOpacity(0.3),
                        const Color(0xFFBF00FF).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFBF00FF).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    mission.isCompleted ? Icons.check_circle : Icons.psychology,
                    color: const Color(0xFFBF00FF),
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
                          ? const Color(0xFFBF00FF)
                          : Colors.grey.shade700,
                      width: 2,
                    ),
                    color: mission.isCompleted
                        ? const Color(0xFFBF00FF)
                        : Colors.transparent,
                  ),
                  child: mission.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
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
