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
import 'auth_screen.dart' ;
void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 

  // --- LE TEST DE CONNEXION (Tu peux le garder ou l'enlever) ---
  print("🔵 TENTATIVE DE CONNEXION A L'API...");
  try {
    List<dynamic> missions = await MissionService.getMissions();
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
      home: const AuthScreen(), 
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 1. 👇 ON AJOUTE LA VARIABLE STREAK
  int score = 0;
  int streak = 0; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 2. 👇 ON UTILISE LA NOUVELLE FONCTION QUI RÉCUPÈRE TOUT (Score + Streak)
  void _loadUserData() async {
    try {
      // On appelle la fonction qu'on a créée dans l'étape 3
      var stats = await MissionService.getUserStats();
      
      setState(() {
        score = stats['score']!;
        streak = stats['streak']!; // On met à jour la flamme
      });
      
      print("Données mises à jour : Score=$score, Streak=$streak");
    } catch (e) {
      print("Erreur lors du chargement des données : $e");
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
            
            Text(
              '$score Points', 
              style: const TextStyle(fontSize: 40, color: Colors.orange, fontWeight: FontWeight.bold) // J'ai grossi un peu le score
            ),

            // 3. 👇 L'AFFICHAGE DE LA FLAMME 🔥
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 30),
                const SizedBox(width: 5),
                Text(
                  'Série : $streak Jours', 
                  style: const TextStyle(fontSize: 18, color: Colors.deepOrange, fontWeight: FontWeight.bold)
                ),
              ],
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SportScreen()),
                );
                _loadUserData(); // On recharge au retour
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
                 _loadUserData(); 
              },
            ),
            const SizedBox(height: 15),

            // Bouton 3 : MENTAL
            MissionButton(
              title: "Mental",
              icon: Icons.self_improvement, 
              color: Colors.purple.shade100,
              iconColor: Colors.purple,
              onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const MentalScreen()));
                  _loadUserData(); 
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