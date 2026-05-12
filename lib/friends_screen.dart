import 'package:flutter/material.dart';

import 'models/friendship.dart';
import 'services/mission_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  static const _bg = Color(0xFF060814);
  static const _appBar = Color(0xFF0F1628);
  static const _card = Color(0xFF12182A);
  static const _cyan = Color(0xFF00FFD1);
  static const _magenta = Color(0xFFFF2D95);

  final TextEditingController _searchController = TextEditingController();
  MyFriendsData _friendsData = MyFriendsData.empty();
  List<FriendSearchResult> _results = [];

  bool _loadingFriends = true;
  bool _searching = false;
  final Set<int> _busyFriendshipIds = <int>{};
  final Set<int> _busyUserIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    try {
      final data = await MissionService.getMyFriends();
      if (!mounted) return;
      setState(() {
        _friendsData = data;
        _loadingFriends = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFriends = false);
      _showSnack('Erreur chargement amis: $e', success: false);
    }
  }

  Future<void> _search() async {
    final text = _searchController.text.trim();
    if (text.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final users = await MissionService.searchUsers(text);
      if (!mounted) return;
      setState(() {
        _results = users;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      _showSnack('$e', success: false);
    }
  }

  Future<void> _withFriendshipAction(
    int friendshipId,
    Future<bool> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyFriendshipIds.add(friendshipId));
    try {
      final ok = await action();
      if (!mounted) return;
      if (ok) {
        _showSnack(successMessage);
        await _loadFriends();
      } else {
        _showSnack("Action impossible pour l'instant.", success: false);
      }
    } catch (e) {
      _showSnack(e.toString(), success: false);
    } finally {
      if (mounted) {
        setState(() => _busyFriendshipIds.remove(friendshipId));
      }
    }
  }

  Future<void> _sendRequest(FriendSearchResult user) async {
    print("Bouton Ajouter cliqué pour l'ID: ${user.id}");
    if (_busyUserIds.contains(user.id)) {
      print("Clic ignoré: requête déjà en cours pour l'ID ${user.id}");
      return;
    }

    setState(() => _busyUserIds.add(user.id));
    try {
      print("Appel MissionService.sendFriendRequest(${user.id})");
      final ok = await MissionService.sendFriendRequest(user.id);
      print("Résultat sendFriendRequest(${user.id}): $ok");
      if (!mounted) return;
      if (ok) {
        _showSnack('Demande envoyée à ${user.pseudo} !');
        await _loadFriends();
      } else {
        _showSnack('Impossible d’envoyer la demande.', success: false);
      }
    } catch (e) {
      print("Erreur sendFriendRequest(${user.id}): $e");
      _showSnack(e.toString(), success: false);
    } finally {
      if (mounted) {
        setState(() => _busyUserIds.remove(user.id));
      }
    }
  }

  Widget _buildCoopBadge(FriendItem friend) {
    // TODO: V1.1 - Reactiver systeme Co-op (proposer/accepter)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4), width: 0.7),
      ),
      child: Text(
        'Co-op indisponible (V1)',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _friendsTab() {
    final friends = _friendsData.acceptedFriends;
    if (_loadingFriends) {
      return const Center(child: CircularProgressIndicator(color: _cyan));
    }
    if (friends.isEmpty) {
      return _empty("Aucun ami accepté pour l'instant.");
    }
    return RefreshIndicator(
      color: _cyan,
      onRefresh: _loadFriends,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: friends.length,
        itemBuilder: (context, i) {
          final f = friends[i];
          return Card(
            color: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: _cyan.withValues(alpha: 0.35), width: 0.5),
            ),
            child: ListTile(
              onTap: null, // TODO: V1.1 - Reactiver profil detaille ami
              leading: CircleAvatar(
                backgroundColor: _magenta.withValues(alpha: 0.2),
                child: Text(
                  f.friendPseudo.isNotEmpty ? f.friendPseudo[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(
                f.friendPseudo,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                f.coopStatus == CoopStatus.active
                    ? 'Co-op actif'
                    : f.coopStatus == CoopStatus.proposed
                        ? 'Proposition Co-op en attente'
                        : 'Pas de Co-op actif',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              trailing: _busyFriendshipIds.contains(f.friendshipId)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _buildCoopBadge(f),
            ),
          );
        },
      ),
    );
  }

  Widget _pendingTab() {
    final pending = _friendsData.pendingReceived;
    if (_loadingFriends) {
      return const Center(child: CircularProgressIndicator(color: _cyan));
    }
    if (pending.isEmpty) {
      return _empty('Aucune demande reçue.');
    }
    return RefreshIndicator(
      color: _cyan,
      onRefresh: _loadFriends,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: pending.length,
        itemBuilder: (context, i) {
          final p = pending[i];
          return Card(
            color: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: _magenta.withValues(alpha: 0.45), width: 0.5),
            ),
            child: ListTile(
              leading: const Icon(Icons.mail_outline_rounded, color: _magenta),
              title: Text(
                p.friendPseudo,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'souhaite devenir ton ami',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
              trailing: _busyFriendshipIds.contains(p.friendshipId)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Accepter',
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                          onPressed: () => _withFriendshipAction(
                            p.friendshipId,
                            () => MissionService.acceptFriendRequest(p.friendshipId),
                            'Demande acceptée ✅',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refuser',
                          icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                          onPressed: () => _withFriendshipAction(
                            p.friendshipId,
                            () => MissionService.rejectFriendRequest(p.friendshipId),
                            'Demande refusée ❌',
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _searchTab() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Chercher un pseudo...',
              filled: true,
              fillColor: _card,
              prefixIcon: const Icon(Icons.search_rounded, color: _cyan),
              suffixIcon: _searching
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _results = []);
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _cyan.withValues(alpha: 0.5), width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _results.isEmpty
                ? _empty('Tape au moins 2 lettres pour rechercher un ami.')
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final u = _results[i];
                      final busy = _busyUserIds.contains(u.id);
                      return Card(
                        color: _card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: _cyan.withValues(alpha: 0.35), width: 0.5),
                        ),
                        child: ListTile(
                          title: Text(
                            u.pseudo,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Score ${u.score} · Streak ${u.currentStreak}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                          ),
                          trailing: busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : FilledButton(
                                  onPressed: () {
                                    print(
                                      "Tap bouton Ajouter détecté pour ${u.pseudo} (ID: ${u.id})",
                                    );
                                    _sendRequest(u);
                                  },
                                  child: const Text('Ajouter'),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Amis & Co-op'),
          backgroundColor: _appBar,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mes Amis'),
              Tab(text: 'Demandes'),
              Tab(text: 'Ajouter'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _friendsTab(),
            _pendingTab(),
            _searchTab(),
          ],
        ),
      ),
    );
  }
}
