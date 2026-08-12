import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../services/leaderboard_service.dart';
import '../services/profile_service.dart';
import '../theme/az_theme.dart';
import '../widgets/az_widgets.dart';

export 'game_ids.dart';

/// Tek cihazda oynanan hızlı oyunlar için ortak oyuncu modeli.
class QPPlayer {
  QPPlayer({required this.name, this.isAI = false});

  final String name;
  final bool isAI;
  int score = 0;
}

const List<Color> kPlayerColors = [
  AZColors.blue,
  AZColors.red,
  AZColors.green,
  AZColors.orange,
  AZColors.purple,
  Color(0xFF00BFA5),
];

// ═══════════════════════════════════════════════════════════════════════════
// OYUNCU KURULUM EKRANI
// ═══════════════════════════════════════════════════════════════════════════

/// Her hızlı oyunun başında gösterilen ortak kurulum ekranı: oyuncu sayısı
/// (destekliyorsa), oyuncu adları, ve varsa "bilgisayara karşı oyna" seçeneği.
/// `Navigator.pop` ile `List<QPPlayer>` döner; kullanıcı geri dönerse `null`.
class QuickPlaySetup extends StatefulWidget {
  const QuickPlaySetup({
    super.key,
    required this.gameTitle,
    required this.emoji,
    required this.gradient,
    required this.minPlayers,
    required this.maxPlayers,
    this.allowAI = false,
    this.instructions,
  });

  final String gameTitle;
  final String emoji;
  final Gradient gradient;
  final int minPlayers;
  final int maxPlayers;
  final bool allowAI;
  final String? instructions;

  @override
  State<QuickPlaySetup> createState() => _QuickPlaySetupState();
}

class _QuickPlaySetupState extends State<QuickPlaySetup> {
  late int _count = widget.minPlayers;
  late final List<TextEditingController> _controllers = List.generate(
    widget.maxPlayers,
    (i) => TextEditingController(text: 'Oyuncu ${i + 1}'),
  );
  bool _vsAI = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    final humanCount = _vsAI ? 1 : _count;
    final players = <QPPlayer>[
      for (var i = 0; i < humanCount; i++)
        QPPlayer(
          name: _controllers[i].text.trim().isEmpty
              ? 'Oyuncu ${i + 1}'
              : _controllers[i].text.trim(),
        ),
    ];
    if (_vsAI) players.add(QPPlayer(name: 'Bilgisayar', isAI: true));
    Navigator.pop(context, players);
  }

  @override
  Widget build(BuildContext context) {
    final showCount = !_vsAI && widget.maxPlayers > widget.minPlayers;
    final nameFieldCount = _vsAI ? 1 : _count;

    return AZGradientScaffold(
      gradient: widget.gradient,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(widget.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text(widget.gameTitle.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 24),
          if (widget.instructions != null) ...[
            AZFrostCard(
              opacity: 0.1,
              child: Text(widget.instructions!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.5)),
            ),
            const SizedBox(height: 20),
          ],
          if (widget.allowAI) ...[
            AZFrostCard(
              child: Row(children: [
                const Icon(Icons.smart_toy_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Bilgisayara karşı oyna',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _vsAI,
                  activeColor: Colors.white,
                  onChanged: (v) => setState(() => _vsAI = v),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ],
          if (showCount) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('OYUNCU SAYISI',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var n = widget.minPlayers; n <= widget.maxPlayers; n++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _count = n),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: n == _count
                              ? Colors.white
                              : const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(AZRadius.md),
                        ),
                        child: Text('$n',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: n == _count
                                    ? AZColors.purple
                                    : Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('OYUNCU ADLARI',
                style: TextStyle(
                    color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < nameFieldCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _controllers[i],
                style: const TextStyle(color: Colors.white),
                maxLength: 12,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: Icon(Icons.person_rounded,
                      color: kPlayerColors[i % kPlayerColors.length]),
                  hintText: 'Oyuncu ${i + 1}',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0x1FFFFFFF),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AZRadius.md),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
          const SizedBox(height: 16),
          AZButton(
            label: 'BAŞLA',
            icon: Icons.play_arrow_rounded,
            color: AZColors.purple,
            onPressed: _start,
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ÜST BAR (oyun içi geri + başlık)
// ═══════════════════════════════════════════════════════════════════════════

class QuickPlayTopBar extends StatelessWidget {
  const QuickPlayTopBar({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
        if (trailing != null) trailing!,
        if (trailing == null) const SizedBox(width: 48),
      ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// SONUÇ EKRANI — XP/coin/başarım ödülü
// ═══════════════════════════════════════════════════════════════════════════

/// Maç bitince çağrılır: profile XP/coin işler, başarımları kontrol eder,
/// (skor tabanlıysa) liderlik tablosuna yazar ve bir sonuç diyaloğu gösterir.
class QuickPlayResult {
  static Future<void> show(
    BuildContext context, {
    required String gameId,
    required String resultTitle,
    required String resultMessage,
    required bool humanWon,
    int? score,
    String? scorerName,
    VoidCallback? onRematch,
  }) async {
    final reward =
        await ProfileService.instance.reportGameResult(gameId: gameId, won: humanWon);
    final unlocked = await AchievementService.instance.checkAndUnlock();

    bool isNewRecord = false;
    if (score != null) {
      isNewRecord = await LeaderboardService.instance.submitScore(
        gameId: gameId,
        name: scorerName ?? 'Oyuncu',
        score: score,
      );
    }

    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        resultTitle: resultTitle,
        resultMessage: resultMessage,
        reward: reward,
        unlocked: unlocked,
        isNewRecord: isNewRecord,
        onRematch: onRematch,
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.resultTitle,
    required this.resultMessage,
    required this.reward,
    required this.unlocked,
    required this.isNewRecord,
    this.onRematch,
  });

  final String resultTitle;
  final String resultMessage;
  final GameRewardResult reward;
  final List<AchievementDef> unlocked;
  final bool isNewRecord;
  final VoidCallback? onRematch;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Column(children: [
          Text(resultTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isNewRecord) ...[
            const SizedBox(height: 4),
            const Text('🏅 Yeni rekor!',
                style: TextStyle(
                    color: AZColors.orangeDk,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(resultMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AZColors.purple.withAlpha(20),
                borderRadius: BorderRadius.circular(AZRadius.md),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.bolt_rounded, color: AZColors.purple, size: 18),
                Text(' +${reward.earnedXp} XP   ',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.monetization_on_rounded,
                    color: AZColors.orangeDk, size: 18),
                Text(' +${reward.earnedCoins}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
            if (reward.leveledUp) ...[
              const SizedBox(height: 10),
              Text('🎉 Seviye atladın! Şimdi seviye ${reward.newLevel}',
                  style: const TextStyle(
                      color: AZColors.greenDk, fontWeight: FontWeight.bold)),
            ],
            for (final a in unlocked) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AZColors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(AZRadius.md),
                ),
                child: Row(children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Başarım açıldı: ${a.title}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(a.description,
                            style: const TextStyle(
                                fontSize: 11, color: AZColors.textSecondary)),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ]),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('ANA MENÜ'),
          ),
          if (onRematch != null)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRematch!();
              },
              child: const Text('TEKRAR OYNA'),
            ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// SIRAYLA OYNA — ORTAK İSKELET
// ═══════════════════════════════════════════════════════════════════════════

/// Her oyuncunun cihazı sırayla alıp bir oturum oynadığı, en iyi sonucun
/// kazandığı basit oyunlar için ortak kabuk (Kim Bilir, Sayı Tahmini, Balon
/// Patlatma, Zar, Kayan Yapboz vb.). Oturumun kendisini [sessionBuilder]
/// üretir; oturum bitince [onFinished] ile skoru bildirir.
class TurnBasedChase extends StatefulWidget {
  const TurnBasedChase({
    super.key,
    required this.players,
    required this.gameId,
    required this.gradient,
    required this.title,
    required this.emoji,
    required this.sessionBuilder,
    this.higherIsBetter = true,
    this.formatScore,
    this.handoffHint,
  });

  final List<QPPlayer> players;
  final String gameId;
  final Gradient gradient;
  final String title;
  final String emoji;

  /// Bir oyuncunun oturumunu oluşturur. Oturum bitince [onFinished] çağrılır.
  final Widget Function(
    BuildContext context,
    QPPlayer player,
    void Function(int score) onFinished,
  ) sessionBuilder;

  /// true ise en yüksek skor kazanır (varsayılan), false ise en düşük
  /// (ör. en az hamle/deneme) kazanır.
  final bool higherIsBetter;
  final String Function(int score)? formatScore;
  final String? handoffHint;

  @override
  State<TurnBasedChase> createState() => _TurnBasedChaseState();
}

class _TurnBasedChaseState extends State<TurnBasedChase> {
  late List<int> _scores = List.filled(widget.players.length, 0);
  int _playerIndex = 0;
  bool _waitingHandoff = true;
  int _sessionKey = 0;

  void _start() => setState(() => _waitingHandoff = false);

  void _onSessionFinished(int score) {
    _scores[_playerIndex] = score;
    if (_playerIndex < widget.players.length - 1) {
      setState(() {
        _playerIndex++;
        _waitingHandoff = true;
        _sessionKey++;
      });
    } else {
      _finishAll();
    }
  }

  Future<void> _finishAll() async {
    var bestIdx = 0;
    for (var i = 1; i < _scores.length; i++) {
      final better =
          widget.higherIsBetter ? _scores[i] > _scores[bestIdx] : _scores[i] < _scores[bestIdx];
      if (better) bestIdx = i;
    }
    final winner = widget.players[bestIdx];
    final winnerScore = _scores[bestIdx];
    final display = widget.formatScore?.call(winnerScore) ?? '$winnerScore puan';
    if (!mounted) return;
    await QuickPlayResult.show(
      context,
      gameId: widget.gameId,
      resultTitle: '${winner.name} kazandı! 🏆',
      resultMessage: '${winner.name}: $display',
      humanWon: true,
      score: winnerScore,
      scorerName: winner.name,
      onRematch: () {
        setState(() {
          _playerIndex = 0;
          _waitingHandoff = true;
          _sessionKey++;
          _scores = List.filled(widget.players.length, 0);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final singlePlayer = widget.players.length == 1;
    return AZGradientScaffold(
      gradient: widget.gradient,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          QuickPlayTopBar(title: widget.title),
          const SizedBox(height: 12),
          if (_waitingHandoff)
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    singlePlayer
                        ? 'Hazır mısın?'
                        : 'Sıra: ${widget.players[_playerIndex].name}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (widget.handoffHint != null) ...[
                    const SizedBox(height: 10),
                    Text(widget.handoffHint!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  AZButton(
                      label: 'BAŞLA',
                      icon: Icons.play_arrow_rounded,
                      color: AZColors.purple,
                      onPressed: _start),
                ]),
              ),
            )
          else
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(_sessionKey),
                child: widget.sessionBuilder(
                    context, widget.players[_playerIndex], _onSessionFinished),
              ),
            ),
        ]),
      ),
    );
  }
}
