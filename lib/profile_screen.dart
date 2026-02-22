import 'package:flutter/material.dart';
import '../services/mission_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'auth_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String pseudo = "Chargement...";
  int score = 0;
  int streak = 0;
  int totalMissions = 0;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  void _chargerProfil() async {
    var stats = await MissionService.getUserStats();
    if (!mounted) return; 

    setState(() {
      pseudo = stats['pseudo']?.toString() ?? "Inconnu";
      score = int.tryParse(stats['score'].toString()) ?? 0;
      streak = int.tryParse(stats['streak'].toString()) ?? 0;
      totalMissions = int.tryParse(stats['total'].toString()) ?? 0;
    });
  }

  // FONCTION DE DÉCONNEXION
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  int _calculerNiveau() {
    return (score / 100).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    int niveau = _calculerNiveau();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: Colors.orange,
        elevation: 0,
        // 👇 C'est ici qu'on ajoute le bouton en haut à droite !
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion', // Petit texte au survol si besoin
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- EN-TÊTE ---
            Container(
              padding: const EdgeInsets.only(bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 60, color: Colors.orange),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pseudo,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      "Niveau $niveau",
                      style: const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- STATS ---
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard("Score Total", "$score pts", Icons.star, Colors.amber),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard("Série", "$streak jours", Icons.local_fire_department, Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard("Missions Terminées", "$totalMissions", Icons.check_circle, Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bouton Retour
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Retour"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // CETTE MÉTHODE DOIT BIEN ÊTRE À L'INTÉRIEUR DE LA CLASSE _ProfileScreenState
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}