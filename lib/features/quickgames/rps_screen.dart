import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class RpsLobbyScreen extends StatelessWidget {
  const RpsLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Taş Kağıt Makas',
        emoji: '🪨📄✂️',
        gradient: AZColors.gradOrange,
        minPlayers: 2,
        maxPlayers: 6,
        allowAI: true,
        instructions:
            'Sırayla cihazı arkadaşına ver, herkes gizlice seçimini yapsın. '
            'Kaybedenler elenir, son kalan oyuncu turnuvayı kazanır!',
      );
}

const _kGestureEmoji = {'rock': '🪨', 'paper': '📄', 'scissors': '✂️'};
const _kGestureLabel = {'rock': 'TAŞ', 'paper': 'KAĞIT', 'scissors': 'MAKAS'};

const _kGestureColors = {
  'rock': Color(0xFF9DAFC3),
  'paper': Color(0xFF77D5E4),
  'scissors': Color(0xFFFFB765),
};

enum _Phase { handoff, choosing, reveal }

class RpsGameScreen extends StatefulWidget {
  const RpsGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<RpsGameScreen> createState() => _RpsGameScreenState();
}

class _RpsGameScreenState extends State<RpsGameScreen> {
  final _rng = Random();
  late List<QPPlayer> _active;
  final Map<QPPlayer, String> _choices = {};
  int _collectIndex = 0;
  _Phase _phase = _Phase.handoff;
  List<QPPlayer> _roundEliminated = [];
  bool _roundWasTie = false;
  int _round = 1;

  @override
  void initState() {
    super.initState();
    _active = List.of(widget.players);
    _startRound();
  }

  void _startRound() {
    _choices.clear();
    _collectIndex = 0;
    _roundEliminated = [];
    _roundWasTie = false;
    _advanceCollect();
  }

  void _advanceCollect() {
    if (_collectIndex >= _active.length) {
      _resolveRound();
      return;
    }
    final p = _active[_collectIndex];
    if (p.isAI) {
      const gestures = ['rock', 'paper', 'scissors'];
      _choices[p] = gestures[_rng.nextInt(3)];
      _collectIndex++;
      _advanceCollect();
      return;
    }
    setState(() => _phase = _Phase.handoff);
  }

  void _choose(String gesture) {
    final p = _active[_collectIndex];
    _choices[p] = gesture;
    _collectIndex++;
    _advanceCollect();
  }

  bool _beats(String a, String b) =>
      (a == 'rock' && b == 'scissors') ||
      (a == 'scissors' && b == 'paper') ||
      (a == 'paper' && b == 'rock');

  void _resolveRound() {
    final gestures = _choices.values.toSet();
    if (gestures.length == 1 || gestures.length == 3) {
      _roundWasTie = true;
    } else {
      final list = gestures.toList();
      final winnerGesture = _beats(list[0], list[1]) ? list[0] : list[1];
      _roundEliminated =
          _active.where((p) => _choices[p] != winnerGesture).toList();
    }
    setState(() => _phase = _Phase.reveal);
  }

  Future<void> _nextAfterReveal() async {
    if (!_roundWasTie) {
      _active = _active.where((p) => !_roundEliminated.contains(p)).toList();
    }
    if (_active.length <= 1) {
      await _finish();
      return;
    }
    _round++;
    _startRound();
  }

  Future<void> _finish() async {
    final winner = _active.isNotEmpty ? _active.first : null;
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'rps',
      resultTitle: winner == null ? 'Oyun bitti' : '${winner.name} kazandı! 🏆',
      resultMessage: winner == null ? '' : 'Turnuvada son ayakta kalan oyuncu!',
      humanWon: winner != null && !winner.isAI,
      onRematch: () {
        _active = List.of(widget.players);
        _round = 1;
        _startRound();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AZGradientScaffold(
      gradient: AZColors.gradOrange,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          QuickPlayTopBar(title: 'Taş Kağıt Makas · Tur $_round'),
          const SizedBox(height: 16),
          Expanded(child: _buildPhase()),
        ]),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.handoff:
        final p = _active[_collectIndex];
        return _CenterCard(children: [
          const Text('📱', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Cihazı ${p.name}\'e ver',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Diğer oyuncular bakmasın!',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 28),
          AZButton(
            label: 'HAZIRIM',
            icon: Icons.visibility_rounded,
            color: AZColors.orangeDk,
            onPressed: () => setState(() => _phase = _Phase.choosing),
          ),
        ]);

      case _Phase.choosing:
        final p = _active[_collectIndex];
        return _CenterCard(children: [
          Text('${p.name}, seç!',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final g in ['rock', 'paper', 'scissors'])
                _GestureButton(
                  emoji: _kGestureEmoji[g]!,
                  label: _kGestureLabel[g]!,
                  color: _kGestureColors[g]!,
                  onTap: () => _choose(g),
                ),
            ],
          ),
        ]);

      case _Phase.reveal:
        return _CenterCard(children: [
          _roundResultBanner(),
          const SizedBox(height: 18),
          for (final p in _active) _buildPlayerResult(p),
          const SizedBox(height: 12),
          AZButton(
            label: 'DEVAM',
            icon: Icons.arrow_forward_rounded,
            color: AZColors.orangeDk,
            onPressed: _nextAfterReveal,
          ),
        ]);
    }
  }

  Widget _roundResultBanner() {
    final title = _roundWasTie ? 'BERABERE' : 'BU TURUN KAZANANLARI';
    final subtitle = _roundWasTie
        ? 'Ayni tur yeniden oynanacak'
        : '${_active.length - _roundEliminated.length} oyuncu turu gecti';
    final color = _roundWasTie ? const Color(0xFFFFCF64) : const Color(0xFF6CF0B1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _roundWasTie
              ? const [Color(0xFF86642A), Color(0xFF543E24), Color(0xFF30251D)]
              : const [Color(0xFF27865B), Color(0xFF18513F), Color(0xFF12332F)],
        ),
        borderRadius: BorderRadius.circular(AZRadius.lg),
        border: Border.all(color: color.withAlpha(190), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withAlpha(75), blurRadius: 20, offset: const Offset(0, 7)),
          const BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-.4, -.5),
                colors: [Colors.white.withAlpha(225), color, color.withAlpha(130)],
              ),
              border: Border.all(color: Colors.white.withAlpha(180), width: 1.5),
              boxShadow: [BoxShadow(color: color.withAlpha(110), blurRadius: 12, offset: const Offset(0, 3))],
            ),
            child: Icon(_roundWasTie ? Icons.sync_rounded : Icons.emoji_events_rounded,
                color: const Color(0xFF182638), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerResult(QPPlayer player) {
    final eliminated = _roundEliminated.contains(player);
    final gesture = _choices[player];
    final color = _kGestureColors[gesture] ?? Colors.white;
    final outcome = _roundWasTie ? 'TEKRAR' : (eliminated ? 'ELENDI' : 'TURU GECTI');
    final accent = _roundWasTie
        ? const Color(0xFFFFCF64)
        : (eliminated ? const Color(0xFFFF8B87) : const Color(0xFF70F0B3));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: eliminated
                ? const [Color(0xFF443B45), Color(0xFF292632)]
                : const [Color(0xFF5A5368), Color(0xFF332F47), Color(0xFF242238)],
          ),
          borderRadius: BorderRadius.circular(AZRadius.md),
          border: Border.all(color: accent.withAlpha(eliminated ? 90 : 180), width: eliminated ? 1 : 1.4),
          boxShadow: [
            BoxShadow(
              color: eliminated ? Colors.black.withAlpha(35) : accent.withAlpha(45),
              blurRadius: eliminated ? 5 : 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(color: Colors.white.withAlpha(18), blurRadius: 3, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-.4, -.5),
                  colors: [Color.lerp(color, Colors.white, .5)!, color, Color.lerp(color, Colors.black, .35)!],
                ),
                border: Border.all(color: Colors.white.withAlpha(175), width: 1.3),
                boxShadow: [BoxShadow(color: color.withAlpha(85), blurRadius: 9, offset: const Offset(0, 3))],
              ),
              child: Text(_kGestureEmoji[gesture] ?? '?', style: const TextStyle(fontSize: 23)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(player.name,
                  style: TextStyle(
                      color: eliminated ? Colors.white60 : Colors.white,
                      fontWeight: FontWeight.w800,
                      shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))])),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withAlpha(eliminated ? 28 : 45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withAlpha(eliminated ? 90 : 175)),
              ),
              child: Text(outcome,
                  style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  const _CenterCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
      );
}

class _GestureButton extends StatelessWidget {
  const _GestureButton({required this.emoji, required this.label, required this.color, required this.onTap});

  final String emoji, label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-.4, -.5),
                colors: [Color.lerp(color, Colors.white, .55)!, color, Color.lerp(color, Colors.black, .4)!],
              ),
              border: Border.all(color: Colors.white.withAlpha(190), width: 2),
              boxShadow: [
                BoxShadow(color: color.withAlpha(145), blurRadius: 18, offset: const Offset(0, 7)),
                const BoxShadow(color: Color(0x77000000), blurRadius: 5, offset: Offset(0, 4)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 9,
                  child: Container(
                    width: 30,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(120),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Text(emoji,
                    style: const TextStyle(
                        fontSize: 36,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 3))])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      );
}
