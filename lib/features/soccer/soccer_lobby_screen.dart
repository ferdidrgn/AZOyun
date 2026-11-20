import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_online_lobby.dart';
import '../../core/widgets/az_widgets.dart';
import 'soccer_room_screen.dart';
import 'soccer_match.dart';

class SoccerLobbyScreen extends StatefulWidget {
  const SoccerLobbyScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<SoccerLobbyScreen> createState() => _SoccerLobbyScreenState();
}

class _SoccerLobbyScreenState extends State<SoccerLobbyScreen> {
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
        current: _playerName, accentColor: AZColors.orange);
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
        gamePath: GamePaths.soccer,
        data: {
          'code': code,
          'status': 'waiting',
          'createdAt': ServerValue.timestamp,
          'currentRound': 1,
          'totalRounds': 5,
          'currentPlayer': 'p1',
          'players': {
            'p1': {'name': _playerName, 'isHost': true, 'score': 0}
          },
        },
      );
      if (!mounted) return;
      _navigate(
          SoccerRoomScreen(roomId: id, myKey: 'p1', myName: _playerName!));
    } catch (error) {
      debugPrint('Serbest Vuruş oda oluşturma: $error');
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
      final r = await _rooms.findByCode(gamePath: GamePaths.soccer, code: code);
      if (!mounted) return;
      if (r == null) {
        context.snack('Oda bulunamadı');
        return;
      }
      final joined = await _rooms.transactRoom(
        gamePath: GamePaths.soccer,
        roomId: r.id,
        update: (room) => joinSoccerRoom(room, _playerName!),
      );
      if (!mounted) return;
      if (!joined.committed || !joined.snapshot.exists) {
        context.snack('Oda dolu, kapanmış veya maç başlamış.');
        return;
      }
      _navigate(
          SoccerRoomScreen(roomId: r.id, myKey: 'p2', myName: _playerName!));
    } catch (error) {
      debugPrint('Serbest Vuruş oda katılımı: $error');
      if (mounted) context.snack('Odaya katılınamadı. Bağlantını kontrol et.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(Widget s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) => AZOnlineLobby(
        title: 'Serbest Vuruş',
        icon: Icons.sports_soccer,
        summary: '2 oyuncu · Kişi başı 5 vuruş',
        instructions:
            'Topa dokunup geriye çek. Bıraktığında şut çekersin. Kaleyi ve kalecinin hareketini takip et.',
        playerName: _playerName,
        codeController: _codeCtrl,
        loading: _loading,
        onRename: _askName,
        onCreate: _createRoom,
        onJoin: _joinRoom,
      );
}
