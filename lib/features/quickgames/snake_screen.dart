import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quickplay/quickplay.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';

class SnakeLobbyScreen extends StatelessWidget {
  const SnakeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuickPlaySetup(
        gameTitle: 'Yılan',
        emoji: '🐍',
        gradient: AZColors.gradGreen,
        minPlayers: 1,
        maxPlayers: 6,
        instructions:
            'Cihazı sırayla birbirinize verin, herkes bir kez oynar. '
            'Yemleri ye, duvara ya da kendine çarpma. En yüksek skor kazanır!',
      );
}

enum _Dir { up, down, left, right }

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key, required this.players});

  final List<QPPlayer> players;

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  static const _gridSize = 14;
  final _rng = Random();

  late List<int> _scores;
  int _playerIndex = 0;
  bool _waitingHandoff = true;

  List<Point<int>> _snake = const [];
  Point<int> _food = const Point(0, 0);
  _Dir _dir = _Dir.right;
  _Dir _pendingDir = _Dir.right;
  Timer? _timer;
  int _score = 0;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _scores = List.filled(widget.players.length, 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    _snake = const [Point(6, 7), Point(5, 7), Point(4, 7)];
    _dir = _Dir.right;
    _pendingDir = _Dir.right;
    _score = 0;
    _over = false;
    _spawnFood();
    setState(() => _waitingHandoff = false);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _spawnFood() {
    Point<int> p;
    do {
      p = Point(_rng.nextInt(_gridSize), _rng.nextInt(_gridSize));
    } while (_snake.contains(p));
    _food = p;
  }

  void _setDir(_Dir d) {
    final opposite = switch (_dir) {
      _Dir.up => _Dir.down,
      _Dir.down => _Dir.up,
      _Dir.left => _Dir.right,
      _Dir.right => _Dir.left,
    };
    if (d == opposite) return;
    _pendingDir = d;
  }

  void _tick() {
    if (_over) return;
    _dir = _pendingDir;
    final head = _snake.first;
    final newHead = switch (_dir) {
      _Dir.up => Point(head.x, head.y - 1),
      _Dir.down => Point(head.x, head.y + 1),
      _Dir.left => Point(head.x - 1, head.y),
      _Dir.right => Point(head.x + 1, head.y),
    };
    final hitWall = newHead.x < 0 || newHead.x >= _gridSize || newHead.y < 0 || newHead.y >= _gridSize;
    // Yem yenmeyecekse kuyruğun son hücresi bu hamlede boşalacak — kafa oraya
    // girebilir. Kontrolü tam _snake listesine göre yapmak, geçerli bir
    // hareketi yanlışlıkla "kendine çarpma" sayardı.
    final willEat = newHead == _food;
    final body = willEat ? _snake : _snake.sublist(0, _snake.length - 1);
    if (hitWall || body.contains(newHead)) {
      _endSession();
      return;
    }
    setState(() {
      _snake = [newHead, ..._snake];
      if (newHead == _food) {
        _score += 10;
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _endSession() {
    _timer?.cancel();
    _scores[_playerIndex] = _score;
    setState(() => _over = true);
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
    var bestIdx = 0;
    for (var i = 1; i < _scores.length; i++) {
      if (_scores[i] > _scores[bestIdx]) bestIdx = i;
    }
    final winner = widget.players[bestIdx];
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: 'snake',
      resultTitle: '${winner.name} kazandı! 🏆',
      resultMessage: '${winner.name}: ${_scores[bestIdx]} puan',
      humanWon: true,
      score: _scores[bestIdx],
      scorerName: winner.name,
      onRematch: () {
        setState(() {
          _playerIndex = 0;
          _waitingHandoff = true;
          _scores = List.filled(widget.players.length, 0);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final singlePlayer = widget.players.length == 1;
    return AZGradientScaffold(
      gradient: AZColors.gradGreen,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const QuickPlayTopBar(title: 'Yılan'),
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
          const Text('🐍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(singlePlayer ? 'Hazır mısın?' : 'Sıra: ${p.name}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AZButton(
              label: 'BAŞLA',
              icon: Icons.play_arrow_rounded,
              color: AZColors.greenDk,
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
            decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(AZRadius.md)),
            padding: const EdgeInsets.all(4),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _gridSize * _gridSize,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _gridSize),
              itemBuilder: (_, i) {
                final x = i % _gridSize, y = i ~/ _gridSize;
                final pt = Point(x, y);
                final isHead = _snake.isNotEmpty && _snake.first == pt;
                final isBody = !isHead && _snake.contains(pt);
                final isFood = _food == pt;
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isHead
                        ? Colors.white
                        : (isBody
                            ? AZColors.green
                            : (isFood ? AZColors.orange : Colors.transparent)),
                    borderRadius: BorderRadius.circular(3),
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
            color: AZColors.greenDk,
            onPressed: _goNext)
      else
        _buildDpad(),
    ]);
  }

  Widget _buildDpad() {
    Widget btn(IconData icon, _Dir d) => IconButton(
          onPressed: () => _setDir(d),
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
