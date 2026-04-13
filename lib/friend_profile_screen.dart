import 'package:flutter/material.dart';

import 'models/friendship.dart';
import 'services/mission_service.dart';

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({
    super.key,
    required this.friendUserId,
    required this.fallbackPseudo,
  });

  final int friendUserId;
  final String fallbackPseudo;

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  static const _bg = Color(0xFF060814);
  static const _card = Color(0xFF12182A);
  static const _cyan = Color(0xFF00FFD1);
  static const _appBar = Color(0xFF0F1628);

  FriendPublicStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await MissionService.getFriendPublicStats(widget.friendUserId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _levelFromScore(int score) {
    if (score < 100) return 1;
    if (score < 300) return 2;
    if (score < 600) return 3;
    if (score < 1000) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _appBar,
        title: Text('Profil de ${widget.fallbackPseudo}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: _cyan)),
              )
            else if (_error != null)
              Card(
                color: _card,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              )
            else if (_stats != null) ...[
              Card(
                color: _card,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _cyan.withValues(alpha: 0.15),
                    child: Text(
                      _stats!.pseudo.isNotEmpty ? _stats!.pseudo[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    _stats!.pseudo,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Niveau ${_levelFromScore(_stats!.score)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _statCard('Score', '${_stats!.score}'),
              _statCard('Streak actuel', '${_stats!.currentStreak} jours'),
              _statCard('Missions terminées', '${_stats!.totalMissionsCompleted}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
