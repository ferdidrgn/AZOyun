import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/deep_link_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/felt.dart';
import '../../core/widgets/az_widgets.dart';
import 'deck_engine.dart';
import 'deck_repository.dart';
import 'widgets/felt_table_view.dart';
import 'widgets/playing_card_view.dart';

class DeckRoomScreen extends StatefulWidget {
  const DeckRoomScreen({
    super.key,
    required this.roomId,
    required this.myKey,
    required this.myName,
  });

  final String roomId;
  final String myKey;
  final String myName;

  @override
  State<DeckRoomScreen> createState() => _DeckRoomScreenState();
}

class _DeckRoomScreenState extends State<DeckRoomScreen> {
  final DeckRepository _repo = DeckRepository.instance;
  StreamSubscription<Map<String, dynamic>?>? _sub;

  Map<String, dynamic>? _room;
  String? _selected;
  bool _busy = false;
  bool _leaving = false;
  bool _rewarded = false;
  bool _presenceSet = false;

  @override
  void initState() {
    super.initState();
    _sub = _repo.watch(widget.roomId).listen(_onRoom);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  void _onRoom(Map<String, dynamic>? room) {
    if (!mounted || _leaving) {
      return;
    }
    if (room == null) {
      _leaving = true;
      Navigator.pop(context);
      return;
    }
    setState(() => _room = room);
    if (!_presenceSet) {
      _presenceSet = true;
      unawaited(_repo.presence(
        roomId: widget.roomId,
        playerKey: widget.myKey,
        isHost: room['hostKey']?.toString() == widget.myKey,
      ));
    }
    final game = room['game'];
    if (game is Map && game['phase'] == 'scored') {
      _reward();
    } else {
      _rewarded = false;
    }
  }

  void _reward() {
    if (_rewarded || widget.myKey == 'table') {
      return;
    }
    final gameRaw = _room?['game'];
    if (gameRaw is! Map) {
      return;
    }
    final game = PistiGame.fromMap(gameRaw);
    final mine = game.scores[widget.myKey] ?? 0;
    var best = 0;
    var leaders = 0;
    for (final score in game.scores.values) {
      if (score > best) {
        best = score;
        leaders = 1;
      } else if (score == best) {
        leaders += 1;
      }
    }
    _rewarded = true;
    unawaited(ProfileService.instance.reportGameResult(
      gameId: 'pisti',
      won: leaders == 1 && mine == best && best > 0,
    ));
  }

  Future<void> _leave() async {
    if (_leaving) {
      return;
    }
    _leaving = true;
    final room = _room;
    final host = room?['hostKey']?.toString() == widget.myKey;
    try {
      await _repo.leave(
        roomId: widget.roomId,
        playerKey: widget.myKey,
        isHost: host,
        isTable: widget.myKey == 'table',
      );
    } on Object {
      // Oda zaten kapanmış olabilir.
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _start() async {
    final room = _room;
    if (room == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    final error = await _repo.start(widget.roomId, room);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      context.snack(error);
    }
  }

  Future<void> _playSelected() async {
    final card = _selected;
    if (card == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    final error = await _repo.play(roomId: widget.roomId, playerKey: widget.myKey, card: card);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      if (error == null) {
        _selected = null;
      }
    });
    if (error != null) {
      context.snack(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final palette = FeltPalette.of(context);
    return AZLeaveGuard(
      onLeave: _leave,
      child: Scaffold(
        body: FeltBackdrop(
          child: SafeArea(
            child: room == null
                ? const Center(child: CircularProgressIndicator(color: FeltColors.brass))
                : _body(room, palette),
          ),
        ),
      ),
    );
  }

  Widget _body(Map<String, dynamic> room, FeltPalette palette) {
    final status = room['status']?.toString() ?? 'waiting';
    final code = room['code']?.toString() ?? '';
    final seats = DeckRepository.seatsOf(room);
    final gameRaw = room['game'];
    final game = gameRaw is Map ? PistiGame.fromMap(gameRaw) : null;
    final playing = status == 'playing' && game != null && game.phase == 'play';
    final scored = game != null && game.phase == 'scored';
    final isHost = room['hostKey']?.toString() == widget.myKey;
    final myHand = game?.hands[widget.myKey] ?? const <String>[];
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: _leave,
                icon: Icon(Icons.close_rounded, color: palette.ink),
              ),
              Expanded(
                child: Text('Pişti', style: feltDisplay(palette.ink, 28)),
              ),
              Text(code, style: feltUi(FeltColors.brass, 18, weight: FontWeight.w700)),
            ],
          ),
        ),
        Expanded(
          child: playing || scored
              ? FeltTableView(
                  table: game.table,
                  seats: seats,
                  turn: game.turn,
                  captured: {
                    for (final seat in game.seats) seat: game.captured[seat]?.length ?? 0,
                  },
                )
              : _waiting(code, seats, palette, wide),
        ),
        if (playing && widget.myKey != 'table') _hand(myHand, game, palette),
        if (scored) _scores(game, seats, isHost, palette),
        if (!playing && !scored) _waitingActions(seats, isHost, palette),
      ],
    );
  }

  Widget _waiting(String code, List<DeckSeat> seats, FeltPalette palette, bool wide) {
    final link = DeepLinkService.webInvite('deck', code);
    final qr = _QrPanel(link: link, code: code);
    final people = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Beklenenler', style: feltUi(palette.ink, 16, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final seat in seats)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              seat.isTable ? '${seat.name} masayı tutuyor' : seat.name,
              style: feltUi(palette.ink, 15),
            ),
          ),
        if (seats.where((seat) => !seat.isTable).length < 2)
          Text('Başlamak için iki oyuncu gerekli.', style: feltUi(palette.muted, 14)),
      ],
    );
    if (wide) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: people),
            const SizedBox(width: 24),
            qr,
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        qr,
        const SizedBox(height: 20),
        people,
      ],
    );
  }

  Widget _hand(List<String> hand, PistiGame game, FeltPalette palette) {
    final mine = game.turn == widget.myKey;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(color: palette.surface.withValues(alpha: 0.92)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mine ? 'Kartını seç, sonra oyna' : 'Sıra karşıda',
            style: feltUi(palette.muted, 13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hand.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final card = hand[index];
                final selected = card == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = card),
                  child: AnimatedSlide(
                    offset: selected ? const Offset(0, -0.08) : Offset.zero,
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 140),
                    child: PlayingCardView(card: card, width: 78, selected: selected),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              onPressed: mine && _selected != null && !_busy ? _playSelected : null,
              style: FilledButton.styleFrom(
                backgroundColor: FeltColors.clay,
                foregroundColor: FeltColors.ivory,
              ),
              child: Text(
                _busy ? 'Gidiyor' : 'Kartı oyna',
                style: feltUi(FeltColors.ivory, 16, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scores(PistiGame game, List<DeckSeat> seats, bool isHost, FeltPalette palette) {
    final names = {for (final seat in seats) seat.key: seat.name};
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          for (final seat in game.seats)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${names[seat] ?? seat}: ${game.scores[seat] ?? 0}',
                style: feltUi(palette.ink, 16, weight: FontWeight.w700),
              ),
            ),
          if (isHost)
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _start,
                style: FilledButton.styleFrom(backgroundColor: FeltColors.felt, foregroundColor: FeltColors.ivory),
                child: Text('Yeni el dağıt', style: feltUi(FeltColors.ivory, 16, weight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _waitingActions(List<DeckSeat> seats, bool isHost, FeltPalette palette) {
    final ready = seats.where((seat) => !seat.isTable).length >= 2;
    if (!isHost) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          ready ? 'Kurucu eli dağıtınca oyun başlar.' : 'Oyuncular bekleniyor.',
          textAlign: TextAlign.center,
          style: feltUi(palette.muted, 14),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          onPressed: ready && !_busy ? _start : null,
          style: FilledButton.styleFrom(backgroundColor: FeltColors.felt, foregroundColor: FeltColors.ivory),
          child: Text(
            ready ? 'Eli dağıt' : 'İki oyuncu gerekli',
            style: feltUi(FeltColors.ivory, 16, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.link, required this.code});

  final String link;
  final String code;

  @override
  Widget build(BuildContext context) => Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: link,
            size: 180,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(code, style: feltUi(FeltColors.ink, 20, weight: FontWeight.w700)),
          Text(
            'TV, bilgisayar veya telefonda aç',
            textAlign: TextAlign.center,
            style: feltUi(const Color(0xFF5E6B62), 12),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Share.share('Pişti masasına katıl. Kod: $code\n$link'),
            child: const Text('Daveti paylaş'),
          ),
        ],
      ),
    );
}
