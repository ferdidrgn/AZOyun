import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/widgets/az_online_lobby.dart';
import '../../core/widgets/az_widgets.dart';
import 'soccer_game_screen.dart';
import 'soccer_match.dart';

class SoccerRoomScreen extends StatefulWidget {
  const SoccerRoomScreen({
    super.key,
    required this.roomId,
    required this.myKey,
    required this.myName,
  });

  final String roomId, myKey, myName;

  @override
  State<SoccerRoomScreen> createState() => _SoccerRoomScreenState();
}

class _SoccerRoomScreenState extends State<SoccerRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _navigating = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms
        .watchRoom(gamePath: GamePaths.soccer, roomId: widget.roomId)
        .listen(_onData, onError: (Object _) {
      if (mounted) context.snack('Oda bağlantısı kurulamadı.');
    });
    _rooms.registerPresence(
        gamePath: GamePaths.soccer,
        roomId: widget.roomId,
        playerKey: widget.myKey,
        isHost: widget.myKey == 'p1');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || _navigating) return;
    if (d == null) {
      _navigating = true;
      context.snack('Oda kapandı.');
      Navigator.of(context).pop();
      return;
    }
    setState(() => _room = d);
    if (d['status'] == 'playing' && !_navigating) {
      _navigating = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => SoccerGameScreen(
                  roomId: widget.roomId,
                  myKey: widget.myKey,
                  myName: widget.myName,
                )),
      );
    }
  }

  Map get _players => (_room['players'] as Map?) ?? {};
  String get _code => _room['code'] ?? '------';
  bool get _isHost => widget.myKey == 'p1';
  bool get _canStart => _players.length >= 2;

  Future<void> _startGame() async {
    if (!_isHost || !_canStart || _starting) return;
    setState(() => _starting = true);
    try {
      final result = await _rooms.transactRoom(
          gamePath: GamePaths.soccer,
          roomId: widget.roomId,
          update: startSoccerRoom);
      if (!result.committed && mounted)
        context.snack('Maç için iki oyuncu gerekli.');
    } catch (error) {
      debugPrint('Serbest Vuruş maç başlangıcı: $error');
      if (mounted) context.snack('Maç başlatılamadı.');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _leaveRoom() async {
    if (_navigating) return;
    _navigating = true;
    try {
      await _rooms.leaveRoom(
          gamePath: GamePaths.soccer,
          roomId: widget.roomId,
          playerKey: widget.myKey,
          isHost: _isHost);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _navigating = false;
      if (mounted) context.snack('Odadan çıkılamadı. Tekrar dene.');
    }
  }

  @override
  Widget build(BuildContext context) => AZOnlineWaitingRoom(
        title: 'Serbest Vuruş odası',
        game: 'soccer',
        code: _code,
        capacity: 2,
        players: _players,
        myKey: widget.myKey,
        isHost: _isHost,
        canStart: _canStart,
        starting: _starting,
        onStart: _startGame,
        onLeave: _leaveRoom,
      );
}
