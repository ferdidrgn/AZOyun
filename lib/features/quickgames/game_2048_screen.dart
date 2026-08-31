import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class Game2048LobbyScreen extends StatelessWidget {
  const Game2048LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: '2048',
        emoji: '🔢',
        gradient: AZColors.gradOrange,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Cihazı sırayla birbirinize verin, herkes bir kez oynar. '
            'Aynı sayılı kutucukları birleştirip 2048\'e ulaşmaya çalış. '
            'En yüksek skor kazanır!',
      );
}

enum _Dir { up, down, left, right }

class Game2048GameScreen extends StatefulWidget {
  const Game2048GameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<Game2048GameScreen> createState() => _Game2048GameScreenState();
}

class _Game2048GameScreenState extends State<Game2048GameScreen> {
  final _rng = Random();

  late List<int> _scores;
  int _playerIndex = 0;
  bool _waitingHandoff = true;

  List<List<int>> _grid = List.generate(4, (_) => List<int>.filled(4, 0));
  int _score = 0;
  int _moveScore = 0;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _scores = List.filled(widget.players.length, 0);
  }

  void _startSession() {
    _grid = List.generate(4, (_) => List<int>.filled(4, 0));
    _score = 0;
    _over = false;
    _spawnTile();
    _spawnTile();
    setState(() => _waitingHandoff = false);
  }

  void _spawnTile() {
    final empties = <List<int>>[
      for (var r = 0; r < 4; r++)
        for (var c = 0; c < 4; c++)
          if (_grid[r][c] == 0) [r, c],
    ];
    if (empties.isEmpty) return;
    final cell = empties[_rng.nextInt(empties.length)];
    _grid[cell[0]][cell[1]] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  List<int> _mergeLine(List<int> line) {
    final nonZero = line.where((v) => v != 0).toList();
    final merged = <int>[];
    var i = 0;
    while (i < nonZero.length) {
      if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
        final val = nonZero[i] * 2;
        merged.add(val);
        _moveScore += val;
        i += 2;
      } else {
        merged.add(nonZero[i]);
        i += 1;
      }
    }
    while (merged.length < line.length) {
      merged.add(0);
    }
    return merged;
  }

  bool _listEquals(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _applyMove(_Dir d) {
    _moveScore = 0;
    var changed = false;
    if (d == _Dir.left || d == _Dir.right) {
      for (var r = 0; r < 4; r++) {
        var row = _grid[r];
        if (d == _Dir.right) row = row.reversed.toList();
        final merged = _mergeLine(row);
        final newRow = d == _Dir.right ? merged.reversed.toList() : merged;
        if (!_listEquals(newRow, _grid[r])) changed = true;
        _grid[r] = newRow;
      }
    } else {
      for (var c = 0; c < 4; c++) {
        var col = [for (var r = 0; r < 4; r++) _grid[r][c]];
        if (d == _Dir.down) col = col.reversed.toList();
        final merged = _mergeLine(col);
        final newCol = d == _Dir.down ? merged.reversed.toList() : merged;
        for (var r = 0; r < 4; r++) {
          if (_grid[r][c] != newCol[r]) changed = true;
          _grid[r][c] = newCol[r];
        }
      }
    }
    return changed;
  }

  bool _isGameOver() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) return false;
        if (c + 1 < 4 && _grid[r][c] == _grid[r][c + 1]) return false;
        if (r + 1 < 4 && _grid[r][c] == _grid[r + 1][c]) return false;
      }
    }
    return true;
  }

  void _move(_Dir d) {
    if (_over) return;
    final changed = _applyMove(d);
    if (!changed) return;
    setState(() {
      _score += _moveScore;
      _spawnTile();
      _over = _isGameOver();
    });
    if (_over) _scores[_playerIndex] = _score;
  }

  void _goNext() {
    if (_playerIndex < widget.players.length - 1) {
      setState(() {
        _playerIndex++;
        _waitingHandoff = true;
      });
    } else {
      _finishAll();
    }
  }

  Future<void> _finishAll() async {
    var bestScore = _scores[0];
    for (var i = 1; i < _scores.length; i++) {
      if (_scores[i] > bestScore) bestScore = _scores[i];
    }
    // Skoru en iyi olan TÜM oyuncular — birden fazlaysa gerçek bir berabere,
    // ilk sıradaki oyuncuyu "kazandı" ilan etmek yanlış olurdu.
    final bestIdxs = [
      for (var i = 0; i < _scores.length; i++) if (_scores[i] == bestScore) i
    ];
    final draw = bestIdxs.length > 1;
    final winner = draw ? null : widget.players[bestIdxs.first];
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: '2048',
      resultTitle: draw ? 'Berabere! 🤝' : '${winner!.name} kazandı! 🏆',
      resultMessage: draw
          ? 'Birden fazla oyuncu $bestScore puan ile eşit skor yaptı.'
          : '${winner!.name}: $bestScore puan',
      humanWon: true,
      score: bestScore,
      scorerName: winner?.name,
      onRematch: () {
        setState(() {
          _playerIndex = 0;
          _waitingHandoff = true;
          _scores = List.filled(widget.players.length, 0);
        });
      },
    );
  }

  Color _tileColor(int v) {
    const colors = {
      2: Color(0xFFEEE4DA),
      4: Color(0xFFEDE0C8),
      8: Color(0xFFF2B179),
      16: Color(0xFFF59563),
      32: Color(0xFFF67C5F),
      64: Color(0xFFF65E3B),
      128: Color(0xFFEDCF72),
      256: Color(0xFFEDCC61),
      512: Color(0xFFEDC850),
      1024: Color(0xFFEDC53F),
      2048: Color(0xFFEDC22E),
    };
    if (v == 0) return const Color(0x14FFFFFF);
    return colors[v] ?? const Color(0xFF3C3A32);
  }

  Color _tileTextColor(int v) => v <= 4 ? const Color(0xFF776E65) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final singlePlayer = widget.players.length == 1;
    return AZGradientScaffold(
      gradient: AZColors.gradOrange,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: '2048'),
          const SizedBox(height: 12),
          if (_waitingHandoff)
            _buildHandoff(singlePlayer)
          else
            Expanded(child: _buildPlaying()),
        ]),
      ),
    );
  }

  Widget _buildHandoff(bool singlePlayer) {
    final p = widget.players[_playerIndex];
    return Expanded(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔢', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(singlePlayer ? 'Hazır mısın?' : 'Sıra: ${p.name}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AZButton(
              label: 'BAŞLA',
              icon: Icons.play_arrow_rounded,
              color: AZColors.orangeDk,
              onPressed: _startSession),
        ]),
      ),
    );
  }

  Widget _buildPlaying() {
    return Column(children: [
      AZFrostCard(
        child: Text('${widget.players[_playerIndex].name}: $_score puan',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(AZRadius.md)),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
              itemBuilder: (_, i) {
                final r = i ~/ 4, c = i % 4;
                final v = _grid[r][c];
                return Container(
                  decoration: BoxDecoration(
                      color: _tileColor(v), borderRadius: BorderRadius.circular(6)),
                  child: Center(
                    child: v == 0
                        ? null
                        : Text('$v',
                            style: TextStyle(
                                color: _tileTextColor(v),
                                fontWeight: FontWeight.bold,
                                fontSize: v >= 1024 ? 16 : 20)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (_over)
        AZButton(
            label: 'DEVAM',
            icon: Icons.arrow_forward_rounded,
            color: AZColors.orangeDk,
            onPressed: _goNext)
      else
        _buildDpad(),
    ]);
  }

  Widget _buildDpad() {
    Widget btn(IconData icon, _Dir d) => IconButton(
          onPressed: () => _move(d),
          icon: Icon(icon, color: Colors.white, size: 32),
        );
    return Column(children: [
      btn(Icons.keyboard_arrow_up_rounded, _Dir.up),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        btn(Icons.keyboard_arrow_left_rounded, _Dir.left),
        const SizedBox(width: 40),
        btn(Icons.keyboard_arrow_right_rounded, _Dir.right),
      ]),
      btn(Icons.keyboard_arrow_down_rounded, _Dir.down),
    ]);
  }
}
