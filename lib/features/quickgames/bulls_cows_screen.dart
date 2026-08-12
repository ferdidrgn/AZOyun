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
            Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(AZRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(i < _current.length ? '${_current[i]}' : '',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
            GestureDetector(
              onTap: () => _tapDigit(d),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _current.contains(d) ? Colors.white24 : Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('$d',
                    style: TextStyle(
                        color: _current.contains(d) ? Colors.white54 : AZColors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
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
                  Text(g.guess,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                  const Spacer(),
                  Text('🎯 ${g.bulls}  🔸 ${g.cows}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
