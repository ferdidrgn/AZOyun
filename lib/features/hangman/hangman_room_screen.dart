import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'hangman_game_screen.dart';

class HangmanRoomScreen extends StatefulWidget {
  const HangmanRoomScreen({
    super.key,
    required this.roomId,
    required this.myKey,
    required this.myName,
  });

  final String roomId, myKey, myName;

  @override
  State<HangmanRoomScreen> createState() => _HangmanRoomScreenState();
}

class _HangmanRoomScreenState extends State<HangmanRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _navigating = false;

  static const _kRed = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _sub = _rooms
        .watchRoom(gamePath: GamePaths.hangman, roomId: widget.roomId)
        .listen(_onData);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  void _onData(Map<String, dynamic>? d) {
    if (!mounted || d == null) return;
    setState(() => _room = d);
    if (d['status'] == 'playing' && !_navigating) {
      _navigating = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HangmanGameScreen(
          roomId: widget.roomId,
          myKey:  widget.myKey,
          myName: widget.myName,
        )),
      );
    }
  }

  Map    get _players  => (_room['players'] as Map?) ?? {};
  String get _code     => _room['code'] ?? '------';
  bool   get _isHost   => widget.myKey == 'p1';
  bool   get _canStart => _players.length >= 2;

  Future<void> _startGame() async {
    if (!_canStart) { _snack('Rakip bekleniyor...'); return; }
    await _rooms.updateRoom(
      gamePath: GamePaths.hangman,
      roomId:   widget.roomId,
      updates: {
        'status': 'playing', 'round': 1,
        'phase': 'choose', 'chooser': 'p1',
        'game': null, 'result': null,
      },
    );
  }

  Future<void> _leaveRoom() async {
    if (_isHost) {
      await _rooms.deleteRoom(gamePath: GamePaths.hangman, roomId: widget.roomId);
    } else {
      await _rooms.removePlayer(
          gamePath: GamePaths.hangman, roomId: widget.roomId, playerKey: widget.myKey);
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _leaveRoom(),
      child: AZGradientScaffold(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _leaveRoom),
              const Expanded(child: Text('ADAM ASMACA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 20),

            AZRoomCode(code: _code, accentColor: _kRed),
            const SizedBox(height: 20),

            AZFrostCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Oyuncular (${_players.length}/2)',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 14),
                for (final slot in ['p1', 'p2'])
                  AZPlayerTile(
                    name:    (_players[slot]?['name'] as String?) ?? slot,
                    isMe:    slot == widget.myKey,
                    isHost:  _players[slot]?['isHost'] == true,
                    emoji:   '🎯',
                    present: _players.containsKey(slot),
                  ),
                if (!_canStart)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: const [
                      SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
                      SizedBox(width: 8),
                      Text('Rakip bekleniyor...',
                          style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ]),
                  ),
              ]),
            ),

            const Spacer(),

            if (_isHost)
              AZButton(
                label: 'OYUNU BAŞLAT', icon: Icons.play_arrow_rounded,
                onPressed: _canStart ? _startGame : null,
                color: _kRed, width: double.infinity,
              )
            else
              const AZWaitingCard(message: 'Host oyunu başlatacak...'),
          ]),
        ),
      ),
    );
  }
}
