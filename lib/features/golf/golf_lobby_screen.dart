import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'golf_room_screen.dart';

class GolfLobbyScreen extends StatefulWidget {
  const GolfLobbyScreen({super.key});

  @override
  State<GolfLobbyScreen> createState() => _GolfLobbyScreenState();
}

class _GolfLobbyScreenState extends State<GolfLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _rooms   = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();

  String? _playerName;
  bool _loading = false;

  late final AnimationController _bounce;
  late final Animation<double>   _bounceY;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750))
      ..repeat(reverse: true);
    _bounceY = Tween(begin: 0.0, end: -14.0).animate(
        CurvedAnimation(parent: _bounce, curve: Curves.easeInOut));
    _loadName();
  }

  @override
  void dispose() {
    _bounce.dispose();
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
        current: _playerName, accentColor: AZColors.green);
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
        gamePath: GamePaths.golf,
        data: {
          'code':        code,
          'status':      'waiting',
          'createdAt':   ServerValue.timestamp,
          'holeCount':   5,
          'currentHole': 1,
          'holeSeed':    DateTime.now().millisecondsSinceEpoch,
          'players': {
            'p1': {
              'name':       _playerName,
              'isHost':     true,
              'totalShots': 0,
              'holeShots':  {},
              'done':       false,
            }
          },
        },
      );
      if (!mounted) return;
      _navigate(GolfRoomScreen(
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
          gamePath: GamePaths.golf, code: code);
      if (result == null) { _snack('Oda bulunamadı'); return; }
      if (result.data['status'] != 'waiting') { _snack('Oyun zaten başlamış'); return; }

      final players = Map.from((result.data['players'] as Map?) ?? {});
      if (players.length >= 4) { _snack('Oda dolu (max 4)'); return; }

      final myKey = 'p${players.length + 1}';
      await _rooms.updateRoom(
        gamePath: GamePaths.golf,
        roomId:   result.id,
        updates: {
          'players/$myKey': {
            'name':       _playerName,
            'isHost':     false,
            'totalShots': 0,
            'holeShots':  {},
            'done':       false,
          }
        },
      );
      if (!mounted) return;
      _navigate(GolfRoomScreen(
          roomId: result.id, myKey: myKey, myName: _playerName!));
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
      gradient: AZColors.gradGreen,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
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

              // Bouncing ball
              AnimatedBuilder(
                animation: _bounceY,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _bounceY.value),
                  child: const Text('⛳',
                      style: TextStyle(fontSize: 72)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('MİNİ GOLF',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              const Text('2-4 Oyuncu · 5 Delik · En az vuruş kazanır',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 28),

              // Name badge
              GestureDetector(
                onTap: _askName,
                child: AZFrostCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(_playerName ?? 'Ad seç',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_rounded,
                        color: Colors.white60, size: 14),
                  ]),
                ),
              ),
              const SizedBox(height: 36),

              // Create room
              AZButton(
                label: 'YENİ ODA OLUŞTUR',
                icon: Icons.add_circle_outline_rounded,
                onPressed: _createRoom,
                color: AZColors.green,
                loading: _loading,
                width: 300,
              ),
              const SizedBox(height: 28),
              const Text('— veya —',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 28),

              // Join room
              AZFrostCard(
                child: Column(children: [
                  AZCodeField(controller: _codeCtrl),
                  const SizedBox(height: 14),
                  AZJoinButton(
                      onPressed: _joinRoom, loading: _loading),
                ]),
              ),
              const SizedBox(height: 32),

              // How to play
              AZFrostCard(
                opacity: 0.08,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('⛳  Nasıl oynanır?',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      SizedBox(height: 10),
                      Text(
                        '• Parmağını topa sürükle → gücü ayarla → bırak\n'
                        '• Engelleri ve duvarları kullanarak deliğe sok\n'
                        '• Her delik rastgele engel ve konum üretir\n'
                        '• 5 delik sonunda toplam vuruş karşılaştırılır',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.65),
                      ),
                    ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }
}
