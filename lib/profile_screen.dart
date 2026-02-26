import 'package:flutter/material.dart';
import 'services/mission_service.dart';

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
    _loadProfileData();
  }

  void _loadProfileData() async {
    var stats = await MissionService.getUserStats();
    setState(() {
      pseudo = stats['pseudo'] ?? "Inconnu";
      score = stats['score'] ?? 0;
      streak = stats['streak'] ?? 0;
      totalMissions = stats['total'] ?? 0;
    });
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
    // On calcule les infos du niveau actuel
    var levelInfo = _getLevelInfo(score);
    int minXp = levelInfo['min'];
    int maxXp = levelInfo['max'];
    
    // Calcul du pourcentage de la barre (entre 0.0 et 1.0)
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
                // Boutons d'action en haut
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
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                        onPressed: () {
                          // TODO: Ajouter la fonction de déconnexion ici plus tard
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Avatar
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Colors.orange),
                ),
                const SizedBox(height: 15),
                
                // Pseudo
                Text(
                  pseudo,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                
                const SizedBox(height: 5),
                
                // Titre du Niveau
                Text(
                  "Niveau ${levelInfo['level']} : ${levelInfo['title']}",
                  style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 15),

                // 📊 LA BARRE D'EXPÉRIENCE
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

          // ⬜ LES CARTES DE STATISTIQUES
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ WIDGET RÉUTILISABLE POUR LES CARTES
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