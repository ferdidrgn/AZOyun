import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class VampireGame extends StatefulWidget {
  final String roomId;
  final String playerName;
  final Function(String) onGameEvent;
  final VoidCallback onGameEnd;

  const VampireGame({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.onGameEvent,
    required this.onGameEnd,
  });

  @override
  State<VampireGame> createState() => _VampireGameState();
}

class _VampireGameState extends State<VampireGame> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late DatabaseReference roomRef;
  final Random _random = Random();

  String? myPlayerKey;
  String myRole = '';
  String gamePhase = 'night'; // night, day, vote
  Map<String, dynamic> players = {};
  String? selectedPlayer;

  @override
  void initState() {
    super.initState();
    roomRef = _database.child('vampire_rooms/${widget.roomId}');
    _findMyPlayerKey();
    _listenToRoom();
  }

  Future<void> _findMyPlayerKey() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;
    final playerData = Map<String, dynamic>.from(snapshot.value as Map);
    playerData.forEach((final key, final value) {
      if (value['name'] == widget.playerName) {
        myPlayerKey = key;
        myRole = value['role'] ?? '';
      }
    });
  }

  void _listenToRoom() {
    roomRef.onValue.listen((final event) {
      if (!mounted || event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        gamePhase = data['phase'] ?? 'night';
        players = Map<String, dynamic>.from(data['players'] ?? {});
      });
      if (data['status'] == 'finished') widget.onGameEnd();
    });
  }

  Future<void> _vote(final String targetKey) async {
    if (myPlayerKey == null) return;
    await roomRef.update({'players/$myPlayerKey/vote': targetKey});

    // Tüm oyuncular oy verdi mi kontrol et
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final playerData = Map<String, dynamic>.from(snapshot.value as Map);
    final allVoted = playerData.values.every(
      (final p) => p['vote'] != null && p['vote'] != '',
    );

    if (allVoted) {
      _processVotes();
    }
  }

  Future<void> _processVotes() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final playerData = Map<String, dynamic>.from(snapshot.value as Map);
    final votes = <String, int>{};

    for (var player in playerData.values) {
      final vote = player['vote'] as String?;
      if (vote != null && vote.isNotEmpty) {
        votes[vote] = (votes[vote] ?? 0) + 1;
      }
    }

    // En çok oy alan
    String? eliminated;
    int maxVotes = 0;
    votes.forEach((final key, final count) {
      if (count > maxVotes) {
        maxVotes = count;
        eliminated = key;
      }
    });

    if (eliminated != null) {
      await roomRef.update({
        'players/$eliminated/alive': false,
        'phase': gamePhase == 'night' ? 'day' : 'night',
      });

      // Oyun bitti mi?
      _checkGameEnd();
    }

    // Oyları sıfırla
    for (var key in playerData.keys) {
      await roomRef.update({'players/$key/vote': ''});
    }
  }

  Future<void> _checkGameEnd() async {
    final snapshot = await roomRef.child('players').get();
    if (!snapshot.exists) return;

    final playerData = Map<String, dynamic>.from(snapshot.value as Map);
    final alivePlayers = playerData.values
        .where((final p) => p['alive'] == true)
        .toList();
    final aliveVampires = alivePlayers
        .where((final p) => p['role'] == 'vampire')
        .length;
    final aliveVillagers = alivePlayers
        .where((final p) => p['role'] == 'villager')
        .length;

    if (aliveVampires == 0) {
      widget.onGameEvent('🎉 Köylüler kazandı!');
      await roomRef.update({'status': 'finished', 'winner': 'villagers'});
    } else if (aliveVampires >= aliveVillagers) {
      widget.onGameEvent('🧛 Vampirler kazandı!');
      await roomRef.update({'status': 'finished', 'winner': 'vampires'});
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: myRole == 'vampire' ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Rolün: ${myRole == 'vampire' ? '🧛 VAMPİR' : '👨‍🌾 KÖYLÜ'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gamePhase == 'night' ? Colors.black87 : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              gamePhase == 'night' ? '🌙 GECE' : '☀️ GÜNDÜZ',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 40),

          const Text(
            'Kim elensin?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              children: players.entries.map((final entry) {
                final key = entry.key;
                final player = entry.value;
                final isAlive = player['alive'] == true;
                final isMe = key == myPlayerKey;

                if (!isAlive || isMe) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () => _vote(key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      player['name'] ?? 'Oyuncu',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
