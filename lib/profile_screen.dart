import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'services/mission_service.dart';
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
  int? userId; // 👈 On ajoute l'ID de l'utilisateur pour la suppression



  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() async {
    // 1. On charge les stats
    var stats = await MissionService.getUserStats();
    
    // 2. On récupère l'ID du joueur stocké sur le téléphone (pour pouvoir le supprimer)
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      pseudo = stats['pseudo'] ?? "Inconnu";
      score = stats['score'] ?? 0;
      streak = stats['streak'] ?? 0;
      totalMissions = stats['total'] ?? 0;
      userId = prefs.getInt('userId'); // Assure-toi que tu sauves bien 'userId' au login !
    });
  }

  // 🚪 FONCTION DE DÉCONNEXION
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // On efface le token et les données locales

    if (mounted) {
      // 🔄 NOUVELLE FAÇON DE NAVIGUER (Directe et infaillible)
      Navigator.pushAndRemoveUntil(
        context,
        // Remplace "LoginScreen()" par le vrai nom de ta classe (ex: LoginPage(), AuthScreen()...)
        MaterialPageRoute(builder: (context) => const AuthScreen()), 
        (Route<dynamic> route) => false,
      );
    }
  }




  // 🚨 BOÎTE DE DIALOGUE DE SÉCURITÉ
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Supprimer mon compte", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text("Attention, cette action est irréversible. Toutes tes missions, tes scores et ton historique seront effacés à jamais. Es-tu sûr ?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Ferme la boîte de dialogue
                
                // 👇 ON UTILISE MAINTENANT LE MISSION SERVICE !
                bool success = await MissionService.deleteAccount();
                
                if (success) {
                  _logout(); // Si ça a marché, on déconnecte et on renvoie au login
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Erreur lors de la suppression. 🦊🔧"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Supprimer définitivement", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 🧠 LA LOGIQUE DES NIVEAUX !
  Map<String, dynamic> _getLevelInfo(int currentScore) {
    if (currentScore < 100) return {"level": 1, "title": "Jeune Renardeau 🐾", "min": 0, "max": 100};
    if (currentScore < 300) return {"level": 2, "title": "Renard Agile 🦊", "min": 100, "max": 300};
    if (currentScore < 600) return {"level": 3, "title": "Renard Alpha 👑", "min": 300, "max": 600};
    if (currentScore < 1000) return {"level": 4, "title": "Maître Renard 🌟", "min": 600, "max": 1000};
    
    return {"level": 5, "title": "Légende du Fitness 🔥", "min": 1000, "max": 9999};
  }

  @override
  Widget build(BuildContext context) {
    var levelInfo = _getLevelInfo(score);
    int minXp = levelInfo['min'];
    int maxXp = levelInfo['max'];
    
    double progress = (score - minXp) / (maxXp - minXp);
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // 🟧 EN-TÊTE ORANGE (CARTE DE JOUEUR)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Mon Profil",
                        style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      // 👇 Le bouton de déconnexion est maintenant branché !
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                        onPressed: _logout, 
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Colors.orange),
                ),
                const SizedBox(height: 15),
                Text(
                  pseudo,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  "Niveau ${levelInfo['level']} : ${levelInfo['title']}",
                  style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.black.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$score / $maxXp XP",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ⬜ LES CARTES DE STATISTIQUES ET LE BOUTON ROUGE
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard(Icons.star, Colors.amber, "$score pts", "Score Total")),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatCard(Icons.local_fire_department, Colors.redAccent, "$streak jours", "Série")),
                  ],
                ),
                const SizedBox(height: 15),
                _buildStatCard(Icons.check_circle, Colors.green, "$totalMissions", "Missions Terminées"),
                
                const SizedBox(height: 40), // Espace avant le bouton de suppression
                
                // 👇 LE NOUVEAU BOUTON DE SUPPRESSION
                OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text("Supprimer mon compte", style: TextStyle(color: Colors.red, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, Color iconColor, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}