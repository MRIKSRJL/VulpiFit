import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

  Widget _buildStravaChart(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text("Aucune donnée pour le moment.", style: TextStyle(color: Colors.white)));
    }

    List<FlSpot> spots = [];
    List<String> dates = [];
    double previousTotal = 0;
    
    for (int i = 0; i < logs.length; i++) {
      double currentTotal = (logs[i]['totalScore'] ?? logs[i]['TotalScore'] ?? 0).toDouble();
      double dailyGain = currentTotal - previousTotal;
      if (dailyGain < 0) dailyGain = 0; 
      
      spots.add(FlSpot(i.toDouble(), dailyGain));
      
      if (logs[i]['date'] != null) {
        DateTime date = DateTime.parse(logs[i]['date']);
        dates.add(DateFormat('dd MMM', 'fr_FR').format(date));
      } else {
        dates.add("Jour ${i+1}");
      }
      
      previousTotal = currentTotal;
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ]
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
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
              isCurved: false,
              color: const Color(0xFFFF6B35),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.3),
                    const Color(0xFFFF6B35).withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
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
              Expanded(
                child: isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                    : progressData.isEmpty
                        ? const Center(
                            child: Text(
                              "Fais ton premier bilan de fin de journée\npour voir ton évolution !",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Effort Quotidien (XP)", 
                                  style: TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold, 
                                    color: Color(0xFFFF6B35),
                                  )
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Visualise les points gagnés chaque jour. Bats ton record !", 
                                  style: TextStyle(
                                    fontSize: 14, 
                                    color: Colors.white.withOpacity(0.7),
                                  )
                                ),
                                const SizedBox(height: 40),
                                Expanded(
                                  child: _buildStravaChart(progressData),
                                ),
                                const SizedBox(height: 40),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            "Ma Roadmap 🦊",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color(0xFFFF6B35),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
