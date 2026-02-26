import 'package:flutter/material.dart';
import 'sport_screen.dart';
import 'profile_screen.dart';
import 'mental_screen.dart';
import 'nutrition_screen.dart';
import 'services/mission_service.dart';
import 'auth_screen.dart';
import 'progress_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🇫🇷 CHARGEMENT DU DICTIONNAIRE FRANÇAIS POUR LES DATES
  await initializeDateFormatting('fr_FR', null);

  // --- TEST DE CONNEXION ---
  print("🔵 TENTATIVE DE CONNEXION A L'API...");
  try {
    await MissionService.getMissions();
    print("🟢 API ACCESSIBLE");
  } catch (e) {
    print("🔴 ECHEC CONNEXION API : $e");
  }

  runApp(const FitnessFoxApp());
}

class FitnessFoxApp extends StatelessWidget {
  const FitnessFoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Fox',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
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
      barrierDismissible: false, // L'utilisateur doit cliquer sur un bouton pour fermer
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.all(20), // Donne de l'air quand le clavier monte
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Bilan du jour 🦊", textAlign: TextAlign.center),
          
          // LE CONTENU QUI PEUT SCROLLER EST ICI 👇
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
          // FIN DU CONTENU SCROLLABLE 👆

          // LES BOUTONS SONT BIEN DANS L'ALERTDIALOG 👇
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
          // BOUTON ROADMAP / STATISTIQUES
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
          // BOUTON EXISTANT : PROFIL
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
            // Header Stats
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
            
            // Liste des catégories
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
      // Bouton pour le bilan quotidien
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