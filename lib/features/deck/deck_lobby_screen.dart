import 'package:flutter/material.dart';

import '../../core/services/storage_service.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';
import 'deck_repository.dart';
import 'deck_room_screen.dart';

class DeckLobbyScreen extends StatefulWidget {
  const DeckLobbyScreen({super.key, this.initialCode});

  final String? initialCode;

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
    _asTable = size.width >= 840;
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
  }

  Future<void> _askName() async {
    final name = await showNameDialog(context, current: _name, accentColor: FeltColors.felt);
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
      final joined = await _repo.join(code: code, name: _name!, asTable: _asTable);
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
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    return Scaffold(
      body: FeltBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: palette.ink),
                    ),
                  ),
                  const Center(child: FeltMark(size: 120)),
                  const SizedBox(height: 12),
                  Text('Pişti', textAlign: TextAlign.center, style: feltDisplay(palette.ink, 40)),
                  const SizedBox(height: 8),
                  Text(
                    'Bir ekran masanın ortasında açık kartları gösterir. Telefonlar sadece kendi elini görür. QR kodu TV, bilgisayar veya başka bir telefonda aç.',
                    textAlign: TextAlign.center,
                    style: feltUi(palette.muted, 15),
                  ),
                  const SizedBox(height: 24),
                  AZNameChip(name: _name, onTap: _askName),
                  const SizedBox(height: 16),
                  Text('Bu cihaz', style: feltUi(palette.ink, 14, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleButton(
                          label: 'Oyuncu',
                          detail: 'Elimi gör',
                          selected: !_asTable,
                          onTap: () => setState(() {
                            _roleTouched = true;
                            _asTable = false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RoleButton(
                          label: 'Masa',
                          detail: 'TV veya bilgisayar',
                          selected: _asTable,
                          onTap: () => setState(() {
                            _roleTouched = true;
                            _asTable = true;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _create,
                      style: FilledButton.styleFrom(
                        backgroundColor: FeltColors.felt,
                        foregroundColor: FeltColors.ivory,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: FeltColors.ivory),
                            )
                          : Text('Masa kur', style: feltUi(FeltColors.ivory, 16, weight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Koda katıl', style: feltUi(palette.ink, 14, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  AZCodeField(controller: _codeCtrl),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _join,
                      child: Text('Odaya katıl', style: feltUi(palette.ink, 15, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FeltPalette.of(context);
    return Material(
      color: selected ? FeltColors.felt : palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: feltUi(
                    selected ? FeltColors.ivory : palette.ink,
                    16,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: feltUi(selected ? FeltColors.mist : palette.muted, 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
