import 'package:flutter/material.dart';
// On importe vos nouveaux écrans pour que main.dart les connaisse
import 'sport_screen.dart';
import 'profile_screen.dart';
import 'mental_screen.dart';
import 'nutrition_screen.dart';
import 'services/mission_service.dart';
import 'models/mission.dart';
import 'services/streak_service.dart';
import 'models/user_streak.dart';

void main() async {
  // <--- 1. Ajoutez 'async' ici
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

  runApp(
    const FitnessFoxApp(),
  ); // Remplacez par le nom de votre classe principale (ex: MyApp ou FitnessFoxApp)
}

class FitnessFoxApp extends StatelessWidget {
  const FitnessFoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Fox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.orange,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.black,
      ),
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
  int currentStreak = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      // On suppose que l'userId = 1 pour l'instant (vous pouvez changer)
      UserStreak streak = await StreakService.getStreak(1);
      setState(() {
        currentStreak = streak.currentStreak;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement streak: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              // Header SPECTACULAIRE
              _buildHeader(context),

              // Stats Hero Section
              _buildStatsSection(),

              const SizedBox(height: 20),

              // Contenu principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre avec effet néon
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFF6B35),
                            Color(0xFFFF8C42),
                            Color(0xFFFFA94D),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'MISSIONS DU JOUR',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Grid de missions
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              // Bouton 1 : SPORT (Design néon)
                              _MissionCardNeon(
                                title: "SPORT",
                                subtitle: "Défie tes limites",
                                icon: Icons.fitness_center,
                                accentColor: const Color(0xFF00F5FF),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SportScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // Bouton 2 : NUTRITION
                              _MissionCardNeon(
                                title: "NUTRITION",
                                subtitle: "Nourris ton corps",
                                icon: Icons.restaurant,
                                accentColor: const Color(0xFF39FF14),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NutritionScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // Bouton 3 : MENTAL
                              _MissionCardNeon(
                                title: "MENTAL",
                                subtitle: "Fortifie ton esprit",
                                icon: Icons.psychology,
                                accentColor: const Color(0xFFBF00FF),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MentalScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section des statistiques
  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade900.withOpacity(0.3),
            Colors.orange.shade700.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('🔥', isLoading ? '...' : '$currentStreak', 'Jours'),
          Container(
            width: 1,
            height: 40,
            color: Colors.orange.withOpacity(0.3),
          ),
          _buildStatItem('⭐', '1250', 'Points'),
          Container(
            width: 1,
            height: 40,
            color: Colors.orange.withOpacity(0.3),
          ),
          _buildStatItem('🏆', '85%', 'Succès'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo avec effet glow
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.deepOrange.shade700],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text('🦊', style: TextStyle(fontSize: 28)),
          ),

          // Titre central
          Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ).createShader(bounds),
                child: const Text(
                  'FITNESS FOX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Text(
                'Deviens la meilleure version de toi',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          // Bouton profil avec glow
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade800],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de carte mission avec effet néon cyberpunk
class _MissionCardNeon extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _MissionCardNeon({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_MissionCardNeon> createState() => _MissionCardNeonState();
}

class _MissionCardNeonState extends State<_MissionCardNeon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  widget.accentColor.withOpacity(0.6),
                  widget.accentColor.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(_isHovered ? 0.6 : 0.3),
                  blurRadius: _isHovered ? 30 : 20,
                  spreadRadius: _isHovered ? 5 : 0,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.accentColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icône avec effet glow
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
                        color: widget.accentColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 40,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: widget.accentColor,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: widget.accentColor.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flèche avec effet
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor.withOpacity(0.3),
                          widget.accentColor.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: widget.accentColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: widget.accentColor,
                      size: 18,
                    ),
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
