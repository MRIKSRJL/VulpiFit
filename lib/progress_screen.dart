import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'services/mission_service.dart';

/// Orange type Strava (activité / graphique).
const Color _stravaOrange = Color(0xFFFC4C02);

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<dynamic> progressData = [];
  bool isLoading = true;

  /// Score profil (API Users) — mis à jour après missions / bilan.
  int _profileScore = 0;

  /// 0 = XP gagnés chaque jour, 1 = score cumulé dans le temps.
  int _chartMode = 0;

  void _onRoadmapTick() {
    if (mounted) _loadProgress();
  }

  @override
  void initState() {
    super.initState();
    MissionService.roadmapRefreshTick.addListener(_onRoadmapTick);
    _loadProgress();
  }

  @override
  void dispose() {
    MissionService.roadmapRefreshTick.removeListener(_onRoadmapTick);
    super.dispose();
  }

  /// Plusieurs bilans le même jour = plusieurs lignes API avec la même date.
  /// On ne garde qu’**un point par jour calendaire** : le snapshot au **score cumulé le plus élevé** (fin de journée logique).
  List<dynamic> _aggregateLogsByCalendarDay(List<dynamic> raw) {
    final maps = <Map<String, dynamic>>[];
    for (final r in raw) {
      if (r is Map) maps.add(Map<String, dynamic>.from(r));
    }
    if (maps.length <= 1) return raw;

    maps.sort((a, b) {
      final da = _readDate(a);
      final db = _readDate(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    final bestByDay = <String, Map<String, dynamic>>{};
    for (final row in maps) {
      final d = _readDate(row);
      if (d == null) continue;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final t = _readTotal(row);
      final prev = bestByDay[key];
      if (prev == null || t >= _readTotal(prev)) {
        final copy = Map<String, dynamic>.from(row);
        copy['date'] = DateTime(d.year, d.month, d.day).toIso8601String();
        bestByDay[key] = copy;
      }
    }

    final keys = bestByDay.keys.toList()..sort();
    return keys.map((k) => bestByDay[k]!).toList();
  }

  Future<void> _loadProgress() async {
    try {
      final results = await Future.wait<Object?>([
        MissionService.getUserProgress(),
        MissionService.getUserStats(),
      ]);

      var data = results[0]! as List<dynamic>;
      data = _aggregateLogsByCalendarDay(data);
      final stats = results[1]! as Map<String, dynamic>;
      final score = (stats['score'] as num?)?.toInt() ?? 0;

      if (data.isNotEmpty && data.length == 1) {
        try {
          final raw = data[0]['date'];
          final currentDate =
              raw != null ? DateTime.parse(raw.toString()) : DateTime.now();
          final fakeDate = currentDate.subtract(const Duration(days: 1));
          data.insert(0, {
            'totalScore': 0,
            'date': fakeDate.toIso8601String(),
            'weight': data[0]['weight'] ?? data[0]['Weight'],
          });
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        progressData = data;
        _profileScore = score;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        progressData = [];
        _profileScore = 0;
        isLoading = false;
      });
    }
  }

  double _readTotal(Map<String, dynamic> row) {
    final v = row['totalScore'] ?? row['TotalScore'] ?? 0;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  DateTime? _readDate(dynamic row) {
    final raw = row is Map ? row['date'] : null;
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  /// Prépare spots, labels d’axe X, stats et index du pic (mode XP jour).
  ({
    List<FlSpot> spots,
    List<String> bottomLabels,
    double maxY,
    double sumXp,
    double maxDay,
    double avgXp,
    int? peakIndex,
    String periodLabel,
  })
      _computeSeries(List<dynamic> logs, int mode) {
    if (logs.isEmpty) {
      return (
        spots: <FlSpot>[],
        bottomLabels: <String>[],
        maxY: 10,
        sumXp: 0,
        maxDay: 0,
        avgXp: 0,
        peakIndex: null,
        periodLabel: '',
      );
    }

    final dates = <DateTime>[];
    final totals = <double>[];
    for (final row in logs) {
      if (row is! Map) continue;
      final m = Map<String, dynamic>.from(row);
      final d = _readDate(m);
      if (d != null) dates.add(d);
      totals.add(_readTotal(m));
    }

    if (totals.isEmpty) {
      return (
        spots: <FlSpot>[],
        bottomLabels: <String>[],
        maxY: 10,
        sumXp: 0,
        maxDay: 0,
        avgXp: 0,
        peakIndex: null,
        periodLabel: '',
      );
    }

    String monthShort(DateTime d) =>
        DateFormat('MMM', 'fr_FR').format(d).replaceAll('.', '');

    final spots = <FlSpot>[];
    final labels = <String>[];
    double prevForGain = 0;
    int? peakIdx;
    double peakVal = 0;
    double sumDaily = 0;

    for (var i = 0; i < totals.length; i++) {
      final total = totals[i];
      var gain = total - prevForGain;
      if (gain < 0) gain = 0;
      sumDaily += gain;
      prevForGain = total;

      double y;
      if (mode == 0) {
        y = gain;
        if (gain >= peakVal) {
          peakVal = gain;
          peakIdx = i;
        }
      } else {
        y = total;
      }

      spots.add(FlSpot(i.toDouble(), y));

      DateTime? d = i < dates.length ? dates[i] : null;
      String label;
      if (d == null) {
        label = 'J${i + 1}';
      } else {
        if (i == 0) {
          label = monthShort(d);
        } else {
          final prevD = i > 0 && i - 1 < dates.length ? dates[i - 1] : null;
          label = (prevD != null && d.month != prevD.month)
              ? monthShort(d)
              : '${d.day}';
        }
      }
      labels.add(label);
    }

    final maxSpotY = spots.isEmpty
        ? 10.0
        : spots.map((s) => s.y).reduce(math.max);
    final maxY = maxSpotY <= 0 ? 10.0 : maxSpotY * 1.15;

    final first = dates.isNotEmpty ? dates.reduce((a, b) => a.isBefore(b) ? a : b) : null;
    final last = dates.isNotEmpty ? dates.reduce((a, b) => a.isAfter(b) ? a : b) : null;
    final periodLabel = (first != null && last != null)
        ? '${DateFormat('d MMM', 'fr_FR').format(first)} – ${DateFormat('d MMM yyyy', 'fr_FR').format(last)}'
        : '';

    final avgDaily = spots.isEmpty ? 0.0 : sumDaily / math.max(1, spots.length);

    return (
      spots: spots,
      bottomLabels: labels,
      maxY: maxY,
      sumXp: mode == 0 ? sumDaily : (totals.isNotEmpty ? totals.last : 0),
      maxDay: mode == 0 ? peakVal : (totals.isNotEmpty ? totals.reduce(math.max) : 0),
      avgXp: avgDaily,
      peakIndex: mode == 0 ? peakIdx : null,
      periodLabel: periodLabel,
    );
  }

  Widget _stravaChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? _stravaOrange : const Color(0xFFE0E0E0),
                width: selected ? 1.5 : 1,
              ),
              color: selected ? _stravaOrange.withValues(alpha: 0.06) : Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? _stravaOrange : const Color(0xFF9E9E9E),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? _stravaOrange : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.4,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStravaCard(List<dynamic> logs) {
    final series = _computeSeries(logs, _chartMode);
    if (series.spots.isEmpty) {
      return const Center(
        child: Text(
          'Pas assez de données pour tracer le graphique.',
          style: TextStyle(color: Color(0xFF757575)),
        ),
      );
    }

    final spots = series.spots;
    final maxY = series.maxY;
    final horizontalInterval = maxY <= 50 ? 10.0 : (maxY / 5).ceilToDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _stravaChip(
                  label: 'XP du jour',
                  icon: Icons.bolt_rounded,
                  selected: _chartMode == 0,
                  onTap: () => setState(() => _chartMode = 0),
                ),
                _stravaChip(
                  label: 'Score cumulé',
                  icon: Icons.trending_up_rounded,
                  selected: _chartMode == 1,
                  onTap: () => setState(() => _chartMode = 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            series.periodLabel.isEmpty ? 'Ta progression' : series.periodLabel,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCell(
                _chartMode == 0 ? 'XP total' : 'Score actuel',
                _chartMode == 0
                    ? '${series.sumXp.toStringAsFixed(0)} XP'
                    : '${series.sumXp.toStringAsFixed(0)} pts',
              ),
              Container(
                width: 1,
                height: 44,
                color: const Color(0xFFE0E0E0),
              ),
              _statCell(
                'Record',
                _chartMode == 0
                    ? '${series.maxDay.toStringAsFixed(0)} XP'
                    : '${series.maxDay.toStringAsFixed(0)} pts',
              ),
              Container(
                width: 1,
                height: 44,
                color: const Color(0xFFE0E0E0),
              ),
              _statCell('Moyenne', series.avgXp.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: horizontalInterval,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: const Color(0xFFE0E0E0),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (v) => FlLine(
                    color: const Color(0xFFE8E8E8),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: horizontalInterval,
                      getTitlesWidget: (value, meta) {
                        if (value > maxY) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= series.bottomLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            series.bottomLabels[i],
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _stravaOrange,
                    getTooltipItems: (List<LineBarSpot> touched) {
                      return touched.map((s) {
                        final unit = _chartMode == 0 ? 'XP' : 'pts';
                        return LineTooltipItem(
                          '${s.y.toStringAsFixed(0)} $unit',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  verticalLines: series.peakIndex != null
                      ? [
                          VerticalLine(
                            x: series.peakIndex!.toDouble(),
                            color: _stravaOrange.withValues(alpha: 0.45),
                            strokeWidth: 1.2,
                            dashArray: [4, 4],
                          ),
                        ]
                      : [],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: _stravaOrange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4.5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: _stravaOrange,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _stravaOrange.withValues(alpha: 0.35),
                          _stravaOrange.withValues(alpha: 0.0),
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
    );
  }

  static const _neonBg = Color(0xFF060814);
  static const _neonAppBar = Color(0xFF0F1628);
  static const _neonCyan = Color(0xFF00FFD1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neonBg,
      appBar: AppBar(
        title: const Text(
          'Ma Roadmap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _neonAppBar,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _neonCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12182A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _neonCyan.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded, color: _neonCyan.withValues(alpha: 0.95)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Score actuel (profil)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_profileScore pts',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _neonCyan.withValues(alpha: 0.98),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Activité',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: _neonCyan.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Un point par jour : si tu fais plusieurs bilans le même jour, on garde le total le plus récent. '
                    'Le score profil suit tes missions tout de suite.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (progressData.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucune entrée d’historique pour le graphique pour l’instant.\n'
                        'Envoie un bilan du jour pour voir la courbe ; ton score se met à jour dès une mission validée.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  else
                    _buildStravaCard(progressData),
                ],
              ),
            ),
    );
  }
}
