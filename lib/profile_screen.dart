import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'services/mission_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _bg = Color(0xFF060814);
  static const _card = Color(0xFF12182A);
  static const _cyan = Color(0xFF00FFD1);
  static const _magenta = Color(0xFFFF2D95);
  static const _appBarFill = Color(0xFF0F1628);

  String pseudo = 'Chargement...';
  int score = 0;
  int streak = 0;
  int totalMissions = 0;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    var stats = await MissionService.getUserStats();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      pseudo = stats['pseudo'] ?? 'Inconnu';
      score = stats['score'] ?? 0;
      streak = stats['streak'] ?? 0;
      totalMissions = stats['total'] ?? 0;
      userId = prefs.getInt('userId');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Supprimer mon compte',
            style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Attention, cette action est irréversible. Toutes tes missions, tes scores et ton historique seront effacés à jamais. Es-tu sûr ?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _cyan.withValues(alpha: 0.35)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Annuler', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                bool success = await MissionService.deleteAccount();
                if (success) {
                  _logout();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la suppression.'),
                        backgroundColor: Color(0xFFFF5252),
                      ),
                    );
                  }
                }
              },
              child: const Text('Supprimer définitivement', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _getLevelInfo(int currentScore) {
    if (currentScore < 100) {
      return {'level': 1, 'title': 'Jeune Renardeau 🐾', 'min': 0, 'max': 100};
    }
    if (currentScore < 300) {
      return {'level': 2, 'title': 'Renard Agile 🦊', 'min': 100, 'max': 300};
    }
    if (currentScore < 600) {
      return {'level': 3, 'title': 'Renard Alpha 👑', 'min': 300, 'max': 600};
    }
    if (currentScore < 1000) {
      return {'level': 4, 'title': 'Maître Renard 🌟', 'min': 600, 'max': 1000};
    }
    return {'level': 5, 'title': 'Légende du Fitness 🔥', 'min': 1000, 'max': 9999};
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = _getLevelInfo(score);
    final minXp = levelInfo['min'] as int;
    final maxXp = levelInfo['max'] as int;

    double progress = (score - minXp) / (maxXp - minXp);
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, bottom: 28),
            decoration: BoxDecoration(
              color: _appBarFill,
              border: Border(
                bottom: BorderSide(color: _cyan.withValues(alpha: 0.25), width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: _magenta.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Mon Profil',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Supprimer mon compte',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.withValues(alpha: 0.45),
                          size: 22,
                        ),
                        onPressed: () => _showDeleteConfirmation(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white, size: 26),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_cyan.withValues(alpha: 0.9), _magenta.withValues(alpha: 0.85)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: _card,
                    child: Icon(Icons.person, size: 52, color: _cyan.withValues(alpha: 0.9)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  pseudo,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Niveau ${levelInfo['level']} : ${levelInfo['title']}',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(_cyan),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$score / $maxXp XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.star_rounded,
                        _cyan,
                        '$score pts',
                        'Score total',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.local_fire_department_rounded,
                        _magenta,
                        '$streak jours',
                        'Série',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  Icons.check_circle_outline_rounded,
                  _cyan,
                  '$totalMissions',
                  'Missions terminées',
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    Color accent,
    String value,
    String label, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cyan.withValues(alpha: 0.35), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
