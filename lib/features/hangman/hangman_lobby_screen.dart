import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/az_online_lobby.dart';
import 'hangman_room_screen.dart';

class HangmanLobbyScreen extends StatefulWidget {
  const HangmanLobbyScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<HangmanLobbyScreen> createState() => _HangmanLobbyScreenState();
}

class _HangmanLobbyScreenState extends State<HangmanLobbyScreen> {
  final _rooms = RoomService.instance;
  final _storage = StorageService.instance;
  final _codeCtrl = TextEditingController();

  String? _playerName;
  bool _loading = false;

  static const _kRed = AZColors.red;

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
    final name =
        await showNameDialog(context, current: _playerName, accentColor: _kRed);
    if (name == null || !mounted) return;
    await _storage.setPlayerName(name);
    setState(() => _playerName = name);
  }

  Future<void> _createRoom() async {
    if (_loading) return;
    if (_playerName == null) {
      await _askName();
      if (_playerName == null) return;
    }
    setState(() => _loading = true);
    try {
      final code = _rooms.generateCode();
      final id = await _rooms.createRoom(
        gamePath: GamePaths.hangman,
        data: {
          'code': code,
          'status': 'waiting',
          'createdAt': ServerValue.timestamp,
          'round': 0,
          'maxRounds': 6,
          'phase': 'lobby',
          'chooser': 'p1',
          'players': {
            'p1': {'name': _playerName, 'score': 0, 'isHost': true}
          },
        },
      );
      if (!mounted) return;
      _navigate(
          HangmanRoomScreen(roomId: id, myKey: 'p1', myName: _playerName!));
    } catch (e) {
      context.snack('Oda oluşturulamadı: $e');
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
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      context.snack('6 haneli kodu girin');
      return;
    }

    setState(() => _loading = true);
    try {
      final r =
          await _rooms.findByCode(gamePath: GamePaths.hangman, code: code);
      if (r == null) {
        context.snack('Oda bulunamadı');
        return;
      }
      if (r.data['status'] != 'waiting') {
        context.snack('Oyun başlamış');
        return;
      }
      final players = Map.from((r.data['players'] as Map?) ?? {});
      if (players.length >= 2) {
        context.snack('Oda dolu');
        return;
      }

      await _rooms.updateRoom(
        gamePath: GamePaths.hangman,
        roomId: r.id,
        updates: {
          'players/p2': {'name': _playerName, 'score': 0, 'isHost': false}
        },
      );
      if (!mounted) return;
      _navigate(
          HangmanRoomScreen(roomId: r.id, myKey: 'p2', myName: _playerName!));
    } catch (e) {
      context.snack('Katılınamadı: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(Widget s) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => s));

  @override
  Widget build(BuildContext context) => AZOnlineLobby(
        title: 'Adam Asmaca',
        icon: Icons.text_fields_rounded,
        summary: '2 Oyuncu · 6 Tur · Kelime Tahmin',
        instructions:
            'P1 kelime seçer, P2 tahmin eder. Her tur roller değişir. '
            'Doğru tahmin +10 puan, her hata −1 puan kazandırır. '
            'Adam asılırsa kelimeyi seçen oyuncu +5 puan alır.',
        playerName: _playerName,
        codeController: _codeCtrl,
        loading: _loading,
        onRename: _askName,
        onCreate: _createRoom,
        onJoin: _joinRoom,
      );
}
