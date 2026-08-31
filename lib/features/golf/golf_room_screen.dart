import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'golf_game_screen.dart';

class GolfRoomScreen extends StatefulWidget {
  const GolfRoomScreen({
    super.key,
    required this.roomId,
    required this.myKey,
    required this.myName,
  });

  final String roomId, myKey, myName;

  @override
  State<GolfRoomScreen> createState() => _GolfRoomScreenState();
}

class _GolfRoomScreenState extends State<GolfRoomScreen> {
  final _rooms = RoomService.instance;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _sub = _rooms
        .watchRoom(gamePath: GamePaths.golf, roomId: widget.roomId)
        .listen(_onData);
    _rooms.registerPresence(gamePath: GamePaths.golf, roomId: widget.roomId,
        playerKey: widget.myKey, isHost: widget.myKey == 'p1');
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
        MaterialPageRoute(builder: (_) => GolfGameScreen(
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
    if (!_canStart) { context.snack('En az 2 oyuncu gerekli'); return; }
    await _rooms.updateRoom(
      gamePath: GamePaths.golf,
      roomId:   widget.roomId,
      updates:  {'status': 'playing', 'currentHole': 1},
    );
  }

  Future<void> _leaveRoom() async {
    await _rooms.leaveRoom(
        gamePath:  GamePaths.golf,
        roomId:    widget.roomId,
        playerKey: widget.myKey,
        isHost:    _isHost);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AZLeaveGuard(
      onLeave: _leaveRoom,
      child: AZGradientScaffold(
        gradient: AZColors.gradGreen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            AZRoomHeader(title: 'MİNİ GOLF', onClose: _leaveRoom),
            const SizedBox(height: 20),

            AZRoomCode(code: _code, accentColor: AZColors.green),
            const SizedBox(height: 20),

            AZFrostCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Oyuncular (${_players.length}/4)',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 14),
                for (final slot in ['p1', 'p2', 'p3', 'p4'])
                  AZPlayerTile(
                    name:    (_players[slot]?['name'] as String?) ?? slot,
                    isMe:    slot == widget.myKey,
                    isHost:  _players[slot]?['isHost'] == true,
                    emoji:   '🏌️',
                    present: _players.containsKey(slot),
                  ),
                if (!_canStart)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: const [
                      SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white38)),
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
                color: AZColors.green, width: double.infinity,
              )
            else
              const AZWaitingCard(message: 'Host oyunu başlatacak...'),
          ]),
        ),
      ),
    );
  }
}
