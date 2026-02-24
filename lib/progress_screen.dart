import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/mission_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<dynamic> progressData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() async {
    var data = await MissionService.getUserProgress();
    
    // 💡 L'ASTUCE MAGIQUE : 
    // Si l'utilisateur n'a fait qu'un seul bilan, on lui invente un "Point de départ"
    // pour que la ligne puisse se dessiner du Score 0 jusqu'à son Score actuel !
    if (data.isNotEmpty && data.length == 1) {
      data.insert(0, {
        'totalScore': 0, // Point de départ à 0 XP
        'weight': data[0]['weight'] ?? data[0]['Weight'],
      });
    }

    setState(() {
      progressData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ma Roadmap 🦊", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : progressData.isEmpty
              ? const Center(
                  child: Text(
                    "Fais ton premier bilan de fin de journée\npour voir ton évolution !",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Évolution de ton Score (XP)", 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange)
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Chaque jour où tu valides tes missions, tu deviens plus fort !", 
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600)
                      ),
                      const SizedBox(height: 40),
                      
                      // LE MAGNIFIQUE GRAPHIQUE
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false), // On cache la grille pour faire plus propre
                            titlesData: const FlTitlesData(
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                            ),
                            borderData: FlBorderData(show: false), // Pas de bordures
                            lineBarsData: [
                              LineChartBarData(
                                // On transforme nos données API en points (X = index du jour, Y = Score)
                                spots: progressData.asMap().entries.map((e) {
                                  // Attention: C# renvoie souvent en camelCase 'totalScore'
                                  double score = (e.value['totalScore'] ?? e.value['TotalScore'] ?? 0).toDouble();
                                  return FlSpot(e.key.toDouble(), score);
                                }).toList(),
                                isCurved: true, // Courbe adoucie
                                color: Colors.orange,
                                barWidth: 5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true), // Affiche les points des jours
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.orange.withOpacity(0.2), // Dégradé sous la courbe
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}