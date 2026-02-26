import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Utile pour formater les dates proprement
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
    
    // 💡 L'ASTUCE MAGIQUE ADAPTÉE : 
    // S'il n'y a qu'un jour, on crée un faux "jour précédent" à 0 XP
    // pour pouvoir tracer la ligne du gain de ce premier jour !
    if (data.isNotEmpty && data.length == 1) {
      DateTime currentDate = DateTime.parse(data[0]['date'] ?? DateTime.now().toIso8601String());
      DateTime fakeDate = currentDate.subtract(const Duration(days: 1));
      
      data.insert(0, {
        'totalScore': 0, 
        'date': fakeDate.toIso8601String(),
        'weight': data[0]['weight'] ?? data[0]['Weight'],
      });
    }

    setState(() {
      progressData = data;
      isLoading = false;
    });
  }

  // 🎨 LA NOUVELLE MÉTHODE FAÇON STRAVA / DUOLINGO
  Widget _buildStravaChart(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text("Aucune donnée pour le moment.", style: TextStyle(color: Colors.white)));
    }

    List<FlSpot> spots = [];
    List<String> dates = [];
    
    // 🧮 Le calcul mathématique des pics d'effort (Daily XP)
    double previousTotal = 0;
    
    for (int i = 0; i < logs.length; i++) {
      double currentTotal = (logs[i]['totalScore'] ?? logs[i]['TotalScore'] ?? 0).toDouble();
      
      // On calcule l'effort du jour (Score actuel - Score précédent)
      double dailyGain = currentTotal - previousTotal;
      if (dailyGain < 0) dailyGain = 0; 
      
      spots.add(FlSpot(i.toDouble(), dailyGain));
      
      // On formate la date (ex: "26 Fév")
      if (logs[i]['date'] != null) {
        DateTime date = DateTime.parse(logs[i]['date']);
        dates.add(DateFormat('dd MMM', 'fr_FR').format(date));
      } else {
        dates.add("Jour ${i+1}");
      }
      
      previousTotal = currentTotal; // On sauvegarde pour le tour suivant
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Fond gris très sombre
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false, // Pas de lignes verticales
            horizontalInterval: 20, // Une ligne tous les 20 XP
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < dates.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dates[index],
                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false, // Lignes droites agressives pour l'intensité !
              color: Colors.deepOrangeAccent, 
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true), // Petits points d'intersection
              belowBarData: BarAreaData(
                show: true,
                color: Colors.deepOrangeAccent.withOpacity(0.15), // Dégradé en dessous
              ),
            ),
          ],
        ),
      ),
    );
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
                        "Effort Quotidien (XP)", 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange)
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Visualise les points gagnés chaque jour. Bats ton record !", 
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600)
                      ),
                      const SizedBox(height: 40),
                      
                      // 👇 APPEL DE LA NOUVELLE FONCTION
                      Expanded(
                        child: _buildStravaChart(progressData),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}