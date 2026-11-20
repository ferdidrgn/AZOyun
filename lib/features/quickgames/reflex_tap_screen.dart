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
  Timer? _pressTimer;
  int? _pressedPlayer;
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
    _pressTimer?.cancel();
    super.dispose();
  }

  void _showTapPress(int idx) {
    _pressTimer?.cancel();
    setState(() => _pressedPlayer = idx);
    _pressTimer = Timer(const Duration(milliseconds: 130), () {
      if (mounted) setState(() => _pressedPlayer = null);
    });
  }

  void _clearTapPress() {
    _pressTimer?.cancel();
    if (_pressedPlayer != null) setState(() => _pressedPlayer = null);
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
    final isGo = _phase == _RoundPhase.go;
    final isResult = _phase == _RoundPhase.result;
    final phaseColor = isGo
        ? const Color(0xFF34E889)
        : isResult
            ? const Color(0xFFFFD447)
            : const Color(0xFFFF405C);
    final phaseIcon = switch (_phase) {
      _RoundPhase.armed => Icons.hourglass_top_rounded,
      _RoundPhase.go => Icons.bolt_rounded,
      _RoundPhase.result => Icons.emoji_events_rounded,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isGo
              ? const [Color(0xFF65F0A2), Color(0xFF15965E), Color(0xFF07513E)]
              : isResult
                  ? const [Color(0xFFFFEAA0), Color(0xFFD79B28), Color(0xFF8B4A1C)]
                  : const [Color(0xFFFF8585), Color(0xFFCC364C), Color(0xFF721F38)],
        ),
        borderRadius: BorderRadius.circular(AZRadius.lg),
        border: Border.all(
          color: isResult ? const Color(0xFFFFE9A8) : Colors.white.withAlpha(125),
          width: isResult ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withAlpha(isGo || isResult ? 110 : 65),
            blurRadius: isGo || isResult ? 22 : 12,
            offset: const Offset(0, 7),
          ),
          const BoxShadow(color: Color(0x44000000), blurRadius: 3, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: -16,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withAlpha(34), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(phaseIcon, color: Colors.white, size: 24,
                    shadows: const [Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2))]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 2))],
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
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
        final isWinner = _roundWinner == p;
        final pressed = _pressedPlayer == i;
        final playerColor = kPlayerColors[i % kPlayerColors.length];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _showTapPress(i),
          onTapCancel: _clearTapPress,
          onTap: () => _tapPlayer(i),
          child: AnimatedScale(
            scale: pressed ? .965 : (isWinner ? 1.025 : 1),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, pressed ? 4 : 0, 0),
              decoration: BoxDecoration(
                gradient: disqualified
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF54525B), Color(0xFF292A34), Color(0xFF171B25)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(playerColor, Colors.white, .35)!.withAlpha(240),
                          playerColor.withAlpha(230),
                          Color.lerp(playerColor, Colors.black, .48)!.withAlpha(245),
                        ],
                      ),
                borderRadius: BorderRadius.circular(AZRadius.lg),
                border: Border.all(
                  color: isWinner
                      ? const Color(0xFFFFE37B)
                      : Colors.white.withAlpha(disqualified ? 45 : 115),
                  width: isWinner ? 3 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isWinner
                        ? const Color(0xFFFFD447).withAlpha(145)
                        : Colors.black.withAlpha(disqualified ? 18 : 65),
                    blurRadius: pressed ? 3 : (isWinner ? 24 : 13),
                    offset: Offset(0, pressed ? 1 : (isWinner ? 9 : 7)),
                  ),
                  if (!disqualified)
                    BoxShadow(
                      color: playerColor.withAlpha(70),
                      blurRadius: isWinner ? 16 : 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AZRadius.lg),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withAlpha(disqualified ? 22 : 80), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        if (isWinner)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.bolt_rounded, color: Color(0xFFFFE37B), size: 24),
                          ),
                        Text(p.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 2))],
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(disqualified ? 'ERKEN!' : '${_scores[i]} puan',
                            style: TextStyle(
                                color: disqualified ? const Color(0xFFFFB5B5) : Colors.white.withAlpha(220),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                shadows: const [Shadow(color: Colors.black45, blurRadius: 3)])),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
