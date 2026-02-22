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
      // On sait maintenant que ce sont de vrais objets 'Mission'
      List<dynamic> missionsBrutes = await MissionService.getMissions();
      
      // On les transforme en une liste typée List<Mission>
      List<Mission> toutesLesMissions = missionsBrutes.cast<Mission>();

      // 👇 Le filtre magique corrigé : On regarde la propriété .type
      List<Mission> missionsFiltrees = toutesLesMissions.where((mission) {
        // On s'assure que le type existe, on le met en minuscule et on vérifie s'il contient "nutrition"
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
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Miam ! ${mission.title} validée ! (+${mission.points} pts) 🍏"), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
          );
        } else {
           setState(() { mission.isCompleted = etaitDejaFaite; });
        }
      } else {
        bool success = await MissionService.undoMission(mission.id);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Annulé. On ne triche pas sur le régime ! 👀"), duration: Duration(seconds: 1)),
          );
        } else {
           setState(() { mission.isCompleted = etaitDejaFaite; });
        }
      }
    } catch (e) {
      setState(() { mission.isCompleted = etaitDejaFaite; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions Nutrition 🥗'),
        backgroundColor: Colors.green,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)));
    }

    if (_missionsNutrition.isEmpty) {
      return const Center(
        child: Text("Pas de missions Nutrition pour l'instant.\nAssure-toi que le type contient 'Nutrition'.", textAlign: TextAlign.center),
      );
    }

    return ListView.builder(
      itemCount: _missionsNutrition.length,
      itemBuilder: (context, index) {
        final mission = _missionsNutrition[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: mission.isCompleted ? Colors.green.shade100 : Colors.white,
          child: ListTile(
            leading: Icon(
              mission.isCompleted ? Icons.check_circle : Icons.restaurant_menu,
              color: mission.isCompleted ? Colors.green : Colors.green.shade300,
              size: 30,
            ),
            title: Text(
              mission.title,
              style: TextStyle(
                decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text("${mission.points} points"),
            trailing: Icon(
              mission.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
              color: mission.isCompleted ? Colors.green : Colors.grey,
            ),
            onTap: () => _toggleMission(mission),
          ),
        );
      },
    );
  }
}