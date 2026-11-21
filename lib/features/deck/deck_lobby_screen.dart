import 'package:flutter/material.dart';

import '../../core/services/storage_service.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/az_online_lobby.dart';
import 'deck_repository.dart';
import 'deck_room_screen.dart';

class DeckLobbyScreen extends StatefulWidget {
  const DeckLobbyScreen({super.key, this.initialCode, this.table = false});

  final String? initialCode;
  final bool table;

  @override
  State<DeckLobbyScreen> createState() => _DeckLobbyScreenState();
}

class _DeckLobbyScreenState extends State<DeckLobbyScreen> {
  final DeckRepository _repo = DeckRepository.instance;
  final StorageService _storage = StorageService.instance;
  final TextEditingController _codeCtrl = TextEditingController();

  String? _name;
  bool _loading = false;
  bool _asTable = false;
  bool _roleTouched = false;

  @override
  void initState() {
    super.initState();
    if (widget.table) {
      _name = 'Ortak ekran';
      return;
    }
    final code = widget.initialCode;
    if (code != null && code.isNotEmpty) {
      _codeCtrl.text = code.toUpperCase();
    }
    _loadName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roleTouched) {
      return;
    }
    final size = MediaQuery.sizeOf(context);
    _asTable =
        widget.table || (widget.initialCode == null && size.width >= 840);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final stored = await _storage.getPlayerName();
    if (!mounted) {
      return;
    }
    if (stored != null && stored.isNotEmpty) {
      setState(() => _name = stored);
    } else {
      await _askName();
    }
    if (mounted && widget.initialCode != null && _name != null && !_loading) {
      await _join();
    }
  }

  Future<void> _askName() async {
    final name = await showNameDialog(context,
        current: _name, accentColor: FeltColors.felt);
    if (name == null || !mounted) {
      return;
    }
    await _storage.setPlayerName(name);
    setState(() => _name = name);
  }

  Future<void> _ensureName() async {
    if (_name == null) {
      await _askName();
    }
  }

  Future<void> _create() async {
    await _ensureName();
    if (_name == null || _loading) {
      return;
    }
    setState(() => _loading = true);
    try {
      final created = await _repo.create(name: _name!, asTable: _asTable);
      if (!mounted) {
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DeckRoomScreen(
            roomId: created.roomId,
            myKey: created.myKey,
            myName: _name!,
          ),
        ),
      );
    } on DeckRoomException catch (error) {
      if (mounted) {
        context.snack(error.message);
      }
    } on Object {
      if (mounted) {
        context.snack('Masa kurulamadı. Bağlantını kontrol edip tekrar dene.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _join() async {
    await _ensureName();
    if (_name == null || _loading) {
      return;
    }
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      context.snack('6 haneli kodu gir');
      return;
    }
    setState(() => _loading = true);
    try {
      final joined =
          await _repo.join(code: code, name: _name!, asTable: _asTable);
      if (!mounted) {
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DeckRoomScreen(
            roomId: joined.roomId,
            myKey: joined.myKey,
            myName: _name!,
          ),
        ),
      );
    } on DeckRoomException catch (error) {
      if (mounted) {
        context.snack(error.message);
      }
    } on Object {
      if (mounted) {
        context.snack('Odaya katılınamadı. Kodu ve bağlantını kontrol et.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AZOnlineLobby(
        title: 'Pişti',
        icon: Icons.style_rounded,
        summary: 'Telefonlarda gizli el · ortak masada açık oyun',
        instructions:
            'Telefonlar yalnızca kendi elini gösterir. Ortak ekran açık kartları ve masayı gösterir. '
            'QR kodunu TV, bilgisayar veya başka bir telefonda okut.',
        playerName: _name,
        codeController: _codeCtrl,
        loading: _loading,
        onRename: _askName,
        onCreate: _create,
        onJoin: _join,
        setupOptions: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bu cihazın rolü',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.person_rounded),
                      label: Text('Oyuncu'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.tv_rounded),
                      label: Text('Ortak masa'),
                    ),
                  ],
                  selected: {_asTable},
                  onSelectionChanged: _loading
                      ? null
                      : (selection) => setState(() {
                            _roleTouched = true;
                            _asTable = selection.first;
                          }),
                ),
              ],
            ),
          ),
        ),
      );
}
