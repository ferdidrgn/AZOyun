import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'soccer_room_screen.dart';

class SoccerLobbyScreen extends StatefulWidget {
  const SoccerLobbyScreen({super.key});

  @override
  State<SoccerLobbyScreen> createState() => _SoccerLobbyScreenState();
}

class _SoccerLobbyScreenState extends State<SoccerLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _rooms   = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();

  String? _playerName;
  bool    _loading = false;

  late final AnimationController _bounceCtrl;
  late final Animation<double>   _bounceY;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _bounceY = Tween(begin: 0.0, end: -14.0).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
    _loadName();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final n = await _storage.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty) {
      setState(() => _playerName = n);
    } else {
      _askName();
    }
  }

  Future<void> _askName() async {
    final name = await showNameDialog(context,
        current: _playerName, accentColor: AZColors.orange);
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
        gamePath: GamePaths.soccer,
        data: {
          'code':          code,
          'status':        'waiting',
          'createdAt':     ServerValue.timestamp,
          'currentRound':  1,
          'totalRounds':   5,
          'currentPlayer': 'p1',
          'players': {
            'p1': {
              'name':   _playerName,
              'isHost': true,
              'score':  0,
            }
          },
        },
      );
      if (!mounted) return;
      _navigate(SoccerRoomScreen(
          roomId: id, myKey: 'p1', myName: _playerName!));
    } catch (e) {
      _snack('Oda oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_playerName == null) { await _askName(); if (_playerName == null) return; }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) { _snack('6 haneli kodu girin'); return; }

    setState(() => _loading = true);
    try {
      final result = await _rooms.findByCode(
          gamePath: GamePaths.soccer, code: code);
      if (result == null)                     { _snack('Oda bulunamadı'); return; }
      if (result.data['status'] != 'waiting') { _snack('Oyun başlamış'); return; }
      final players = Map.from((result.data['players'] as Map?) ?? {});
      if (players.length >= 2)                { _snack('Oda dolu (max 2)'); return; }

      await _rooms.updateRoom(
        gamePath: GamePaths.soccer,
        roomId:   result.id,
        updates: {
          'players/p2': {
            'name': _playerName, 'isHost': false, 'score': 0,
          }
        },
      );
      if (!mounted) return;
      _navigate(SoccerRoomScreen(
          roomId: result.id, myKey: 'p2', myName: _playerName!));
    } catch (e) {
      _snack('Katılınamadı: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradOrange,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _bounceY,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _bounceY.value),
              child: const Text('⚽', style: TextStyle(fontSize: 72)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('SERBEST VURUŞ',
              style: TextStyle(
                  color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 4),
          const Text('2 Oyuncu · 5 Vuruş · En çok gol atan kazanır',
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
            onPressed: _createRoom, color: AZColors.orange,
            loading: _loading, width: 300,
          ),
          const SizedBox(height: 28),
          const Text('— veya —', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 28),

          AZFrostCard(
            child: Column(children: [
              AZCodeField(controller: _codeCtrl),
              const SizedBox(height: 14),
              AZJoinButton(onPressed: _joinRoom, loading: _loading),
            ]),
          ),
          const SizedBox(height: 32),

          AZFrostCard(
            opacity: 0.08,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('⚽  Nasıl oynanır?',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 10),
              Text(
                '• Parmağını sürükle → yön ve güç ayarla → bırak\n'
                '• Kalecin rastgele hareket eder\n'
                '• 5 vuruş sonunda en çok gol atan kazanır\n'
                '• Her tur sıra değişir',
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
