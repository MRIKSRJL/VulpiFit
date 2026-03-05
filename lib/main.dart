import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 IMPORT IMPORTANT
import 'package:intl/date_symbol_data_local.dart';

import 'sport_screen.dart';
import 'profile_screen.dart';
import 'mental_screen.dart';
import 'nutrition_screen.dart';
import 'services/mission_service.dart';
import 'auth_screen.dart';
import 'progress_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🇫🇷 CHARGEMENT DU DICTIONNAIRE FRANÇAIS POUR LES DATES
  await initializeDateFormatting('fr_FR', null);

  // 🛑 J'ai supprimé l'appel réseau ici. On ne dérange pas l'API tant qu'on ne sait pas si on a un token !

  runApp(const FitnessFoxApp());
}

class FitnessFoxApp extends StatelessWidget {
  const FitnessFoxApp({super.key});

  // 🕵️‍♂️ VÉRIFICATION SILENCIEUSE : A-t-on un token enregistré dans le téléphone ?
  Future<bool> _checkIfLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false; // En cas de doute, on dit qu'on n'est pas connecté
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Fox',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      // 🚦 L'AIGUILLEUR : Décide quelle page afficher au démarrage
      home: FutureBuilder<bool>(
        future: _checkIfLoggedIn(),
        builder: (context, snapshot) {
          // 1. Pendant qu'on cherche dans la mémoire (ça prend quelques millisecondes)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.orange,
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          
          // 2. Si on a trouvé un token (l'utilisateur est déjà connecté)
          if (snapshot.data == true) {
            return const DashboardScreen();
          } 
          // 3. Sinon (nouvel utilisateur ou compte supprimé)
          else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int score = 0;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- LOGIQUE DE DONNÉES ---

  void _loadUserData() async {
    try {
      var stats = await MissionService.getUserStats();
      setState(() {
        score = stats['score'] ?? 0;
        streak = stats['streak'] ?? 0;
      });
    } catch (e) {
      print("Erreur chargement stats : $e");
    }
  }

  // --- LOGIQUE DU BILAN IA (FEEDBACK) ---

  void _showFeedbackDialog() {
    double difficulty = 5;
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Bilan du jour 🦊", textAlign: TextAlign.center),
          
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Comment s'est passée ta journée ?"),
                const SizedBox(height: 15),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Ressenti, fatigue, succès...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Difficulté ressentie : ${difficulty.toInt()}/10",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Slider(
                  value: difficulty,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: Colors.orange,
                  inactiveColor: Colors.orange.shade100,
                  onChanged: (value) => setDialogState(() => difficulty = value),
                ),
              ],
            ),
          ), 
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ANNULER", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                bool success = await MissionService.sendDailyFeedback(
                  feedbackController.text,
                  difficulty.toInt(),
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Coach Fox a bien noté ! Tes missions s'adapteront. 🐾"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("ENVOYER", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- INTERFACE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text('Fitness Fox 🦊',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up, color: Colors.white, size: 30),
            tooltip: "Ma Roadmap",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProgressScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) => _loadUserData()),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.orange.withOpacity(0.1),
              child: Column(
                children: [
                  const Text('Ton Score Actuel', style: TextStyle(fontSize: 18)),
                  Text(
                    '$score Points',
                    style: const TextStyle(
                        fontSize: 42, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                      const SizedBox(width: 5),
                      Text('Série : $streak Jours',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildCategoryButton(
                    context,
                    title: "Sport",
                    icon: Icons.fitness_center,
                    color: Colors.blue.shade100,
                    iconColor: Colors.blue,
                    screen: const SportScreen(),
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryButton(
                    context,
                    title: "Nutrition",
                    icon: Icons.restaurant,
                    color: Colors.green.shade100,
                    iconColor: Colors.green,
                    screen: const NutritionScreen(),
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryButton(
                    context,
                    title: "Mental",
                    icon: Icons.self_improvement,
                    color: Colors.purple.shade100,
                    iconColor: Colors.purple,
                    screen: const MentalScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFeedbackDialog,
        label: const Text("Bilan du jour"),
        icon: const Icon(Icons.psychology_alt),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required Color iconColor,
      required Widget screen}) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ).then((_) => _loadUserData()),
      borderRadius: BorderRadius.circular(20),
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
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }
}