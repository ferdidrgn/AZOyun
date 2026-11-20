import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

const _kDigits = 4;
const _kMaxAttempts = 10;

class BullsCowsLobbyScreen extends StatelessWidget {
  const BullsCowsLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Sayı Tahmin Düellosu',
        emoji: '🔢🕵️',
        gradient: AZColors.gradPurple,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Sistem 4 farklı rakamdan oluşan gizli bir sayı tutar. Tahmin et, '
            '"doğru yer" ve "yanlış yer" ipucuyla sayıyı bul. En az denemede '
            'bulan kazanır!',
      );
}

class BullsCowsGameScreen extends StatelessWidget {
  const BullsCowsGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  Widget build(BuildContext context) => TurnBasedChase(
        players: players,
        gameId: 'bullscows',
        gradient: AZColors.gradPurple,
        title: 'Sayı Tahmin Düellosu',
        emoji: '🔢',
        higherIsBetter: false,
        handoffHint: 'Her oyuncuya farklı bir gizli sayı verilir, adil olsun!',
        formatScore: (s) => s > _kMaxAttempts ? 'çözemedi 😔' : '$s deneme',
        sessionBuilder: (context, player, onFinished) =>
            _BullsCowsSession(player: player, onFinished: onFinished),
      );
}

class _Guess {
  const _Guess(this.guess, this.bulls, this.cows);
  final String guess;
  final int bulls, cows;
}

class _BullsCowsSession extends StatefulWidget {
  const _BullsCowsSession({required this.player, required this.onFinished});

  final QPPlayer player;
  final void Function(int score) onFinished;

  @override
  State<_BullsCowsSession> createState() => _BullsCowsSessionState();
}

class _BullsCowsSessionState extends State<_BullsCowsSession> {
  final _rng = Random();
  late final String _secret = _generateSecret();
  final List<int> _current = [];
  final List<_Guess> _history = [];
  bool _finished = false;

  String _generateSecret() {
    final digits = List.generate(10, (i) => i)..shuffle(_rng);
    return digits.take(_kDigits).join();
  }

  void _tapDigit(int d) {
    if (_current.length >= _kDigits || _current.contains(d)) return;
    setState(() => _current.add(d));
  }

  void _backspace() {
    if (_current.isEmpty) return;
    setState(() => _current.removeLast());
  }

  void _submit() {
    if (_current.length != _kDigits || _finished) return;
    final guess = _current.join();
    var bulls = 0, cows = 0;
    for (var i = 0; i < _kDigits; i++) {
      if (guess[i] == _secret[i]) {
        bulls++;
      } else if (_secret.contains(guess[i])) {
        cows++;
      }
    }
    setState(() {
      _history.insert(0, _Guess(guess, bulls, cows));
      _current.clear();
    });
    if (bulls == _kDigits) {
      _finished = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onFinished(_history.length);
      });
    } else if (_history.length >= _kMaxAttempts) {
      _finished = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onFinished(_kMaxAttempts + 5);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AZFrostCard(
        child: Text(
            '${widget.player.name} · Deneme ${_history.length}/$_kMaxAttempts',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _kDigits; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: i < _current.length
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFF7D7), Color(0xFFFFD878), Color(0xFFE6A82C)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x442D1A70), Color(0x22200C56)],
                      ),
                borderRadius: BorderRadius.circular(AZRadius.md),
                border: Border.all(
                  color: i < _current.length
                      ? const Color(0xFFFFF0AE)
                      : Colors.white.withAlpha(70),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(48),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                  if (i < _current.length)
                    const BoxShadow(
                      color: Color(0x44FFE18A),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(i < _current.length ? '${_current[i]}' : '',
                  style: const TextStyle(
                  color: Color(0xFF45247D),
                  shadows: [Shadow(color: Colors.white70, blurRadius: 2, offset: Offset(0, 1))],
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (var d = 0; d < 10; d++)
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _tapDigit(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  curve: Curves.easeOut,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _current.contains(d)
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF8C75B4), Color(0xFF574276), Color(0xFF3C2B58)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFE4DDF1), Color(0xFFC7B8DF)],
                          ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _current.contains(d)
                          ? Colors.white.withAlpha(80)
                          : const Color(0xFFF8F2FF),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(_current.contains(d) ? 18 : 70),
                        blurRadius: _current.contains(d) ? 2 : 6,
                        offset: Offset(0, _current.contains(d) ? 1 : 4),
                      ),
                      if (!_current.contains(d))
                        const BoxShadow(
                          color: Color(0xAAFFFFFF),
                          blurRadius: 2,
                          offset: Offset(-1, -1),
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('$d',
                      style: TextStyle(
                          color: _current.contains(d) ? Colors.white54 : AZColors.purple,
                          shadows: _current.contains(d)
                              ? const [
                                  Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))
                                ]
                              : null,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextButton.icon(
            onPressed: _current.isEmpty ? null : _backspace,
            icon: const Icon(Icons.backspace_rounded, color: Colors.white70, size: 18),
            label: const Text('SİL', style: TextStyle(color: Colors.white70)),
          ),
        ),
        Expanded(
          child: AZButton(
            label: 'TAHMİN ET',
            icon: Icons.send_rounded,
            color: AZColors.purple,
            onPressed: _current.length == _kDigits ? _submit : null,
            height: 44,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      Expanded(
        child: ListView.builder(
          itemCount: _history.length,
          itemBuilder: (_, i) {
            final g = _history[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AZFrostCard(
                opacity: 0.08,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 66,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFF7D7), Color(0xFFE5D5AF)],
                      ),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFEFE1BD)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Text(g.guess,
                        style: const TextStyle(
                            color: Color(0xFF422B6B),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4)),
                  ),
                  const Spacer(),
                  _HintPill(icon: Icons.place_rounded, count: g.bulls, color: const Color(0xFF54E1A0)),
                  const SizedBox(width: 7),
                  _HintPill(icon: Icons.swap_horiz_rounded, count: g.cows, color: const Color(0xFFFFD36E)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.icon, required this.count, required this.color});

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(130)),
          boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 8)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
      );
}
