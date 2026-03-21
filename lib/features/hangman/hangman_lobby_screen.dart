import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/az_widgets.dart';
import 'hangman_room_screen.dart';

class HangmanLobbyScreen extends StatefulWidget {
  const HangmanLobbyScreen({super.key});

  @override
  State<HangmanLobbyScreen> createState() => _HangmanLobbyScreenState();
}

class _HangmanLobbyScreenState extends State<HangmanLobbyScreen> {
  final _rooms    = RoomService.instance;
  final _storage  = StorageService.instance;
  final _codeCtrl = TextEditingController();

  String? _playerName;
  bool    _loading = false;

  static const _kRed = Color(0xFFD32F2F);

  @override
  void initState() { super.initState(); _loadName(); }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _loadName() async {
    final n = await _storage.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty) setState(() => _playerName = n);
    else                           _askName();
  }

  Future<void> _askName() async {
    final name = await showNameDialog(context,
        current: _playerName, accentColor: _kRed);
    if (name == null || !mounted) return;
    await _storage.setPlayerName(name);
    setState(() => _playerName = name);
  }

  Future<void> _createRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final id   = await _rooms.createRoom(
        gamePath: GamePaths.hangman,
        data: {
          'code':      code,
          'status':    'waiting',
          'createdAt': ServerValue.timestamp,
          'round':     0,
          'maxRounds': 6,
          'phase':     'lobby',
          'chooser':   'p1',
          'players': {
            'p1': {'name': _playerName, 'score': 0, 'isHost': true}
          },
        },
      );
      if (!mounted) return;
      _navigate(HangmanRoomScreen(roomId: id, myKey: 'p1', myName: _playerName!));
    } catch (e) { _snack('Oda oluşturulamadı: $e'); }
    finally     { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _joinRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kodu girin'); return; }

    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.hangman, code: code);
      if (r == null)                     { _snack('Oda bulunamadı'); return; }
      if (r.data['status'] != 'waiting') { _snack('Oyun başlamış'); return; }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 2)           { _snack('Oda dolu'); return; }

      await _rooms.updateRoom(
        gamePath: GamePaths.hangman,
        roomId:   r.id,
        updates:  {'players/p2': {'name': _playerName, 'score': 0, 'isHost': false}},
      );
      if (!mounted) return;
      _navigate(HangmanRoomScreen(roomId: r.id, myKey: 'p2', myName: _playerName!));
    } catch (e) { _snack('Katılınamadı: $e'); }
    finally     { if (mounted) setState(() => _loading = false); }
  }

  void _navigate(Widget s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),
          const Text('🎯', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          const Text('ADAM ASMACA',
              style: TextStyle(color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          const Text('2 Oyuncu · 6 Tur · Kelime Tahmin',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 28),

          GestureDetector(
            onTap: _askName,
            child: AZFrostCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(_playerName ?? 'Ad seç',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                const Icon(Icons.edit_rounded, color: Colors.white60, size: 14),
              ]),
            ),
          ),
          const SizedBox(height: 36),

          AZButton(
            label: 'YENİ ODA OLUŞTUR', icon: Icons.add_circle_outline_rounded,
            onPressed: _createRoom, color: _kRed, loading: _loading, width: 300,
          ),
          const SizedBox(height: 28),
          const Text('— veya —', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 28),

          AZFrostCard(child: Column(children: [
            AZCodeField(controller: _codeCtrl),
            const SizedBox(height: 14),
            AZJoinButton(onPressed: _joinRoom, loading: _loading),
          ])),
          const SizedBox(height: 32),

          AZFrostCard(
            opacity: 0.08,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('🎯  Nasıl oynanır?',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 10),
              Text(
                '• P1 kelime seçer, P2 tahmin eder\n'
                '• Her tur roller değişir (6 tur toplam)\n'
                '• Doğru tahmin → +10 puan (hata başına −1)\n'
                '• Adam asılırsa kelimeyi seçen +5 puan alır',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.65),
              ),
            ]),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
