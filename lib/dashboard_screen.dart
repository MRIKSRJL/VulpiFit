import 'package:flutter/material.dart';

import 'friends_screen.dart';
import 'mental_screen.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'screens/sport_screen.dart';
import 'services/mission_service.dart';

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

  void _loadUserData() async {
    try {
      var stats = await MissionService.getUserStats();
      if (!mounted) return;
      setState(() {
        score = stats['score'] ?? 0;
        streak = stats['streak'] ?? 0;
      });
    } catch (e) {
      debugPrint('Erreur chargement stats : $e');
    }
  }

  void _showFeedbackDialog() {
    double difficulty = 5;
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Bilan du jour 🦊', textAlign: TextAlign.center),
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
                    hintText: 'Ressenti, fatigue, succès...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Difficulté ressentie : ${difficulty.toInt()}/10',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                Slider(
                  value: difficulty,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  onChanged: (value) => setDialogState(() => difficulty = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ANNULER', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final success = await MissionService.sendDailyFeedback(
                  feedbackController.text,
                  difficulty.toInt(),
                );
                if (!mounted) return;
                if (success) {
                  Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Coach Fox a bien noté ! Tes missions s'adapteront. 🐾"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('ENVOYER', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('VulpiFit', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Visibility(
            visible: false, // TODO: V1.1 - Reactiver Roadmap/Analytics
            child: IconButton(
              icon: const Icon(Icons.trending_up, size: 30),
              tooltip: 'Ma Roadmap',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProgressScreen()),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.groups_rounded, size: 28),
            tooltip: 'Amis & Co-op',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FriendsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              child: Column(
                children: [
                  const Text('Ton Score Actuel', style: TextStyle(fontSize: 18)),
                  Text(
                    '$score Points',
                    style: TextStyle(
                      fontSize: 42,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_fire_department, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 5),
                      Text(
                        'Série : $streak Jours',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    title: 'Sport',
                    icon: Icons.fitness_center,
                    color: Colors.blue.shade100,
                    iconColor: Colors.blue,
                    screen: const SportScreen(),
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryButton(
                    context,
                    title: 'Nutrition',
                    icon: Icons.restaurant,
                    color: Colors.green.shade100,
                    iconColor: Colors.green,
                    screen: const NutritionScreen(),
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryButton(
                    context,
                    title: 'Mental',
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
      floatingActionButton: Visibility(
        visible: false, // TODO: V1.1 - Reactiver Bilan du jour
        child: FloatingActionButton.extended(
          onPressed: _showFeedbackDialog,
          label: const Text('Bilan du jour'),
          icon: const Icon(Icons.psychology_alt),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Widget screen,
  }) {
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
                color: iconColor.withValues(alpha: 0.8),
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
