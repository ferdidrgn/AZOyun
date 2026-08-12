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
                  onTap: () => _choose(g),
                ),
            ],
          ),
        ]);

      case _Phase.reveal:
        return _CenterCard(children: [
          if (_roundWasTie) ...[
            const Text('🤝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Berabere! Tur tekrar oynanıyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ] else ...[
            const Text('SONUÇLAR',
                style: TextStyle(
                    color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
          ],
          const SizedBox(height: 18),
          for (final p in _active)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AZFrostCard(
                opacity: _roundEliminated.contains(p) ? 0.06 : 0.18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Text(_kGestureEmoji[_choices[p]] ?? '❓',
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(p.name,
                        style: TextStyle(
                            color: _roundEliminated.contains(p)
                                ? Colors.white38
                                : Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  if (_roundEliminated.contains(p))
                    const Text('ELENDİ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ),
            ),
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
  const _GestureButton({required this.emoji, required this.label, required this.onTap});

  final String emoji, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      );
}
