import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class ReflexTapLobbyScreen extends StatelessWidget {
  const ReflexTapLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Refleks Çarpışması',
        emoji: '⚡',
        gradient: AZColors.gradRed,
        minPlayers: 2,
        maxPlayers: 6,
        instructions:
            'Herkes parmağını kendi kutusunun üzerinde tutsun. Ekran '
            '"ŞİMDİ!" yazınca ilk basan turu kazanır. Erken basan o turu kaybeder! '
            'İlk 3 puana ulaşan turnuvayı kazanır.',
      );
}

enum _RoundPhase { armed, go, result }

class ReflexTapGameScreen extends StatefulWidget {
  const ReflexTapGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<ReflexTapGameScreen> createState() => _ReflexTapGameScreenState();
}

class _ReflexTapGameScreenState extends State<ReflexTapGameScreen> {
  static const _target = 3;
  final _rng = Random();

  late List<int> _scores;
  _RoundPhase _phase = _RoundPhase.armed;
  Timer? _armTimer;
  QPPlayer? _roundWinner;
  final Set<QPPlayer> _falseStarters = {};

  @override
  void initState() {
    super.initState();
    _scores = List.filled(widget.players.length, 0);
    _startRound();
  }

  @override
  void dispose() {
    _armTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _falseStarters.clear();
    _roundWinner = null;
    setState(() => _phase = _RoundPhase.armed);
    final delayMs = 1200 + _rng.nextInt(2800);
    _armTimer?.cancel();
    _armTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      if (_falseStarters.length == widget.players.length) {
        _startRound();
        return;
      }
      setState(() => _phase = _RoundPhase.go);
    });
  }

  void _tapPlayer(int idx) {
    final p = widget.players[idx];
    if (_phase == _RoundPhase.armed) {
      if (_falseStarters.contains(p)) return;
      setState(() => _falseStarters.add(p));
      return;
    }
    if (_phase == _RoundPhase.go) {
      if (_falseStarters.contains(p)) return;
      _armTimer?.cancel();
      setState(() {
        _roundWinner = p;
        _scores[idx]++;
        _phase = _RoundPhase.result;
      });
    }
  }

  void _afterResult() {
    final leaderIdx = _scores.indexWhere((s) => s >= _target);
    if (leaderIdx != -1) {
      _finish(leaderIdx);
    } else {
      _startRound();
    }
  }

  Future<void> _finish(int winnerIdx) async {
    _armTimer?.cancel();
    final winner = widget.players[winnerIdx];
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'reflex',
      resultTitle: '${winner.name} kazandı! ⚡',
      resultMessage: '${winner.name} ilk $_target puana ulaştı!',
      humanWon: true,
      onRematch: () {
        setState(() => _scores = List.filled(widget.players.length, 0));
        _startRound();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _phase == _RoundPhase.go ? AZColors.gradGreen : AZColors.gradRed;
    return AZGradientScaffold(
      gradient: gradient,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: 'Refleks Çarpışması'),
          const SizedBox(height: 12),
          _buildStatusBanner(),
          const SizedBox(height: 16),
          Expanded(child: _buildPlayerGrid()),
          if (_phase == _RoundPhase.result) ...[
            const SizedBox(height: 16),
            AZButton(
                label: 'DEVAM',
                icon: Icons.arrow_forward_rounded,
                color: AZColors.redDk,
                onPressed: _afterResult),
          ],
        ]),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final text = switch (_phase) {
      _RoundPhase.armed => '✋ HAZIR OLUN... erken basma!',
      _RoundPhase.go => '⚡ ŞİMDİ! İlk basan kazanır!',
      _RoundPhase.result => _roundWinner != null
          ? '${_roundWinner!.name} bu turu kazandı!'
          : 'Bu tur boş geçti',
    };
    return AZFrostCard(
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildPlayerGrid() {
    return GridView.builder(
      itemCount: widget.players.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
      itemBuilder: (_, i) {
        final p = widget.players[i];
        final disqualified = _falseStarters.contains(p);
        return GestureDetector(
          onTap: () => _tapPlayer(i),
          child: Container(
            decoration: BoxDecoration(
              color: disqualified
                  ? Colors.black26
                  : kPlayerColors[i % kPlayerColors.length].withAlpha(200),
              borderRadius: BorderRadius.circular(AZRadius.lg),
            ),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(p.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(disqualified ? 'ERKEN!' : '${_scores[i]} puan',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ),
        );
      },
    );
  }
}
