import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_online_lobby.dart';
import '../../core/widgets/az_widgets.dart';
import 'golf_room_screen.dart';
import 'golf_match.dart';

class GolfLobbyScreen extends StatefulWidget {
  const GolfLobbyScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<GolfLobbyScreen> createState() => _GolfLobbyScreenState();
}

class _GolfLobbyScreenState extends State<GolfLobbyScreen> {
  final _rooms = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();

  String? _playerName;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    seedRoomCode(_codeCtrl, widget.initialCode);
    _loadName();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final n = await _storage.getPlayerName();
    if (!mounted) return;
    if (n != null && n.isNotEmpty)
      setState(() => _playerName = n);
    else
      await _askName();
    if (mounted &&
        widget.initialCode != null &&
        _playerName != null &&
        !_loading) {
      await _joinRoom();
    }
  }

  Future<void> _askName() async {
    final name = await showNameDialog(context,
        current: _playerName, accentColor: AZColors.green);
    if (name == null || !mounted) return;
    await _storage.setPlayerName(name);
    if (mounted) setState(() => _playerName = name);
  }

  Future<void> _createRoom() async {
    if (_loading) return;
    if (_playerName == null) {
      await _askName();
      if (_playerName == null) return;
    }
    if (!mounted || _loading) return;
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final id = await _rooms.createRoom(
        gamePath: GamePaths.golf,
        data: {
          'code': code,
          'status': 'waiting',
          'createdAt': ServerValue.timestamp,
          'holeCount': 5,
          'currentHole': 1,
          'holeSeed': DateTime.now().millisecondsSinceEpoch,
          'players': {
            'p1': {
              'name': _playerName,
              'isHost': true,
              'totalShots': 0,
              'holeShots': {},
              'done': false,
            }
          },
        },
      );
      if (!mounted) return;
      _navigate(GolfRoomScreen(roomId: id, myKey: 'p1', myName: _playerName!));
    } catch (error) {
      debugPrint('Mini Golf oda oluşturma: $error');
      if (mounted) context.snack('Oda oluşturulamadı. Bağlantını kontrol et.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_loading) return;
    if (_playerName == null) {
      await _askName();
      if (_playerName == null) return;
    }
    if (!mounted || _loading) return;
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      context.snack('6 haneli kodu girin');
      return;
    }

    setState(() => _loading = true);
    try {
      final r = await _rooms.findByCode(gamePath: GamePaths.golf, code: code);
      if (r == null) {
        context.snack('Oda bulunamadı');
        return;
      }
      String? myKey;
      final result = await _rooms.transactRoom(
        gamePath: GamePaths.golf,
        roomId: r.id,
        update: (room) {
          final next = joinGolfRoom(room, _playerName!);
          if (next != null) {
            final before = room['players'] as Map? ?? {};
            myKey = (next['players'] as Map)
                .keys
                .cast<String>()
                .firstWhere((seat) => !before.containsKey(seat));
          }
          return next;
        },
      );
      if (!mounted) return;
      if (!result.committed || !result.snapshot.exists || myKey == null) {
        context.snack('Oda dolu, kapanmış veya maç başlamış.');
        return;
      }
      _navigate(
          GolfRoomScreen(roomId: r.id, myKey: myKey!, myName: _playerName!));
    } catch (error) {
      debugPrint('Mini Golf oda bağlantısı: $error');
      if (mounted) context.snack('Odaya katılınamadı. Bağlantını kontrol et.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(Widget s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) => AZOnlineLobby(
        title: 'Mini Golf',
        icon: Icons.sports_golf,
        summary: '2–4 oyuncu · 5 delik',
        instructions:
            'Topu geriye çekip bırak. Beş deliği en az vuruşla bitiren kazanır.',
        playerName: _playerName,
        codeController: _codeCtrl,
        loading: _loading,
        onRename: _askName,
        onCreate: _createRoom,
        onJoin: _joinRoom,
      );
}
