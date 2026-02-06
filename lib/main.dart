import 'package:flutter/material.dart';
// On importe vos nouveaux écrans pour que main.dart les connaisse
import 'sport_screen.dart';
import 'profile_screen.dart';
import 'mental_screen.dart';
import 'nutrition_screen.dart';
import 'photo_screen.dart';
import 'steps_screen.dart';
import 'services/mission_service.dart';
import 'models/mission.dart';
void main() async { // <--- 1. Ajoutez 'async' ici
  WidgetsFlutterBinding.ensureInitialized(); // <--- Sécurité pour Flutter

  // --- LE TEST DE CONNEXION ---
  print("🔵 TENTATIVE DE CONNEXION A L'API...");
  try {
    MissionService service = MissionService();
    List<Mission> missions = await MissionService.getMissions();
    
    print("🟢 SUCCÈS ! ${missions.length} missions trouvées :");
    for (var m in missions) {
      print(" - ${m.title} (${m.points} pts)");
    }
  } catch (e) {
    print("🔴 ECHEC : $e");
  }
  // -------------------------

  runApp(const FitnessFoxApp()); // Remplacez par le nom de votre classe principale (ex: MyApp ou FitnessFoxApp)
}

class FitnessFoxApp extends StatelessWidget {
  const FitnessFoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Fox',
      theme: ThemeData(primarySwatch: Colors.orange),
      // 👇 On a bien remis DashboardScreen ici
      home: const DashboardScreen(), 
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Fitness Fox 🦊', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        // 👇 AJOUT DU BOUTON PROFIL ICI
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
            const Text('Prêt pour la mission ?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Série : 0 Jours 🔥', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),

            // --- Zone des Missions (Les Boutons) ---
            
            // Bouton 1 : SPORT
            MissionButton(
              title: "Faire du Sport",
              icon: Icons.fitness_center,
              color: Colors.blue.shade100,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SportScreen()));
              },
            ),
            const SizedBox(height: 15),

            // Bouton 2 : NUTRITION (Modifié)
            MissionButton(
              title: "Nutrition",       // On change le titre
              icon: Icons.restaurant,   // On change l'icône (Fourchette/Couteau)
              color: Colors.green.shade100,
              iconColor: Colors.green,
              onTap: () {
                // 👇 C'est ici qu'on branche ton nouvel écran !
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionScreen()));
              },
            ),

            // Bouton 3 : PAS
            // Bouton 3 : MENTAL
            MissionButton(
              title: "Mental",
              icon: Icons.psychology, // Ou Icons.self_improvement
              color: Colors.purple.shade100,
              iconColor: Colors.purple,
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const MentalScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// J'ai créé un petit composant "MissionButton" pour éviter de répéter le code 3 fois
// C'est ça la puissance de Flutter !
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
                // On garde l'ancienne méthode car elle est plus simple à écrire
                // Ignorez le soulignement jaune, ça marche très bien !
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