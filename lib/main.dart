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

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int score = 0;
  int streak = 0;
  int totalMissions = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    try {
      var stats = await MissionService.getUserStats();
      if (mounted) {
        setState(() {
          score = stats['score'] ?? 0;
          streak = stats['streak'] ?? 0;
          totalMissions = stats['total'] ?? 0;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildStatsSection(),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Text(
                      "Tes Missions",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _MissionCardNeon(
                      title: "Sport",
                      icon: Icons.fitness_center,
                      accentColor: const Color(0xFF00F5FF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SportScreen()),
                      ).then((_) => _loadUserData()),
                    ),
                    const SizedBox(height: 16),
                    _MissionCardNeon(
                      title: "Nutrition",
                      icon: Icons.restaurant,
                      accentColor: const Color(0xFF39FF14),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NutritionScreen()),
                      ).then((_) => _loadUserData()),
                    ),
                    const SizedBox(height: 16),
                    _MissionCardNeon(
                      title: "Mental",
                      icon: Icons.psychology,
                      accentColor: const Color(0xFFBF00FF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MentalScreen()),
                      ).then((_) => _loadUserData()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showFeedbackDialog,
          label: const Text("Bilan du jour"),
          icon: const Icon(Icons.psychology_alt),
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B35).withOpacity(0.3),
                  const Color(0xFFFF6B35).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFFF6B35).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              "🦊",
              style: TextStyle(fontSize: 32),
            ),
          ),
          const Text(
            "Fitness Fox",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.trending_up, color: Color(0xFF00F5FF), size: 28),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBF00FF).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.account_circle, color: Color(0xFFBF00FF), size: 28),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  ).then((_) => _loadUserData()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    double successRate = totalMissions > 0 ? (score / (totalMissions * 10) * 100) : 0;
    if (successRate > 100) successRate = 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("🔥", "$streak", "Série"),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildStatItem("⭐", "$score", "Points"),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildStatItem("🏆", "${successRate.toInt()}%", "Réussite"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

}

class _MissionCardNeon extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _MissionCardNeon({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_MissionCardNeon> createState() => _MissionCardNeonState();
}

class _MissionCardNeonState extends State<_MissionCardNeon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  widget.accentColor.withOpacity(0.6),
                  widget.accentColor.withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(_isHovered ? 0.6 : 0.3),
                  blurRadius: _isHovered ? 25 : 15,
                  spreadRadius: _isHovered ? 3 : 0,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: widget.accentColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          widget.accentColor.withOpacity(0.3),
                          widget.accentColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.accentColor.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [widget.accentColor, widget.accentColor.withOpacity(0.7)],
                      ).createShader(bounds),
                      child: Icon(widget.icon, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: widget.accentColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}