import 'package:flutter/material.dart';
// On importe vos nouveaux écrans
import 'sport_screen.dart';
import 'profile_screen.dart';
import 'mental_screen.dart';
import 'nutrition_screen.dart';
import 'photo_screen.dart';
import 'steps_screen.dart';
import 'services/mission_service.dart'; // 👈 Important pour récupérer le score
import 'models/mission.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 

  // --- LE TEST DE CONNEXION (Tu peux le garder ou l'enlever) ---
  print("🔵 TENTATIVE DE CONNEXION A L'API...");
  try {
    List<Mission> missions = await MissionService.getMissions();
    print("🟢 SUCCÈS ! ${missions.length} missions trouvées.");
  } catch (e) {
    print("🔴 ECHEC : $e");
  }
  // -------------------------

  runApp(const FitnessFoxApp()); 
}

class FitnessFoxApp extends StatelessWidget {
  const FitnessFoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Fox',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const DashboardScreen(), 
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 1. 👇 LA VARIABLE QUI STOCKE LE SCORE
  int score = 0;

  @override
  void initState() {
    super.initState();
    // 2. 👇 ON CHARGE LE SCORE DÈS LE DÉMARRAGE
    _loadUserData();
  }

  // 3. 👇 LA FONCTION QUI VA CHERCHER LES DONNÉES
  void _loadUserData() async {
    try {
      int nouveauScore = await MissionService.getScore();
      setState(() {
        score = nouveauScore;
      });
      print("Score mis à jour : $score");
    } catch (e) {
      print("Erreur lors du chargement du score : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Fitness Fox 🦊', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- Zone du haut (Statut) ---
            const SizedBox(height: 20),
            const Text('Ton Score Actuel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            
            // 4. 👇 ICI ON AFFICHE LE VRAI SCORE !
            Text(
              '$score Points 🔥', 
              style: const TextStyle(fontSize: 24, color: Colors.orange, fontWeight: FontWeight.bold)
            ),
            
            const SizedBox(height: 40),

            // --- Zone des Missions (Les Boutons) ---
            
            // Bouton 1 : SPORT
            MissionButton(
              title: "Sport",
              icon: Icons.fitness_center,
              color: Colors.blue.shade100,
              iconColor: Colors.blue,
              onTap: () async { 
                // On attend que l'utilisateur revienne de l'écran Sport
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SportScreen()),
                );
                
                // 5. 👇 QUAND IL REVIENT, ON RECHARGE LE SCORE !
                _loadUserData(); 
              },
            ),
            const SizedBox(height: 15),

            // Bouton 2 : NUTRITION
            MissionButton(
              title: "Nutrition",
              icon: Icons.restaurant,
              color: Colors.green.shade100,
              iconColor: Colors.green,
              onTap: () async {
                 await Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionScreen()));
                 _loadUserData(); // On recharge aussi ici au cas où
              },
            ),
            const SizedBox(height: 20),

            // Bouton 3 : MENTAL
            MissionButton(
              title: "Mental",
              icon: Icons.psychology, 
              color: Colors.purple.shade100,
              iconColor: Colors.purple,
              onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const MentalScreen()));
                  _loadUserData(); // On recharge aussi ici au cas où
              },
            ),
          ],
        ),
      ),
    );
  }
}

// LE COMPOSANT BOUTON (Pas changé, il est parfait)
class MissionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const MissionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: iconColor.withOpacity(0.8), 
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: iconColor),
          ],
        ),
      ),
    );
  }
}