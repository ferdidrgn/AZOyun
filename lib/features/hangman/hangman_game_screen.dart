import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/achievement_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/room_service.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

const _kWords = [
  'FLUTTER','ANDROID','KOTLIN','PYTHON','JAVASCRIPT','YAZILIM',
  'BILGISAYAR','PROGRAMLAMA','INTERNET','VERITABANI','ALGORITMA',
  'FUTBOL','BASKETBOL','TENIS','YUZME','BISIKLET','OLIMPIYAT',
  'SAMPIYONA','STADYUM','VOLEYBOL','ATLETIZM',
  'ISTANBUL','ANKARA','IZMIR','ANTALYA','BURSA','TRABZON',
  'ESKISEHIR','GAZIANTEP','SAMSUN',
  'KAPLAN','ASLAN','KARTAL','PENGUEN','YUNUS','ZEBRA',
  'GITAR','PIYANO','KEMAN','DAVUL','TROMPET',
  'TATIL','SEYAHAT','UCAK','PASAPORT','OTEL','PLAJ',
  'ELMA','ARMUT','MANGO','KIRAZ','PORTAKAL','AVOKADO',
  'ASTRONOT','GALAKSI','METEOR','YILDIZ','GEZEGEN','ROKET',
  'DOKTOR','MUHENDIS','OGRETMEN','AVUKAT','PILOT','MIMAR',
  'KITAP','ROMAN','SENARYO','MAKALE','DERGI','GAZETE',
];

const _kRed   = Color(0xFFAD6F63);
const _kGreen = Color(0xFF77916F);
const _kGrey  = Color(0xFF9E9E9E);
const _kRedLt = Color(0xFFF3E3DF);
const _kBg    = Color(0xFFF6F1E9);

/// Dart'ın `String.toUpperCase()` metodu Türkçe'ye duyarlı değil: küçük
/// "i" harfini noktasız "I" yapar, noktalı "İ" değil (bkz. aynı düzeltme
/// `city_screens.dart` içinde). Burada bunun etkisi çok daha ciddi: serbest
/// metin kelime kutusuna "kelime" gibi noktalı "i" içeren bir sözcük
/// yazıldığında `_submitWord` bunu yanlışlıkla "KELIME" (noktasız I) olarak
/// saklıyordu. Tahmin edenin klavyesinde noktalı "İ" ve noktasız "I" ayrı
/// tuşlar olduğundan, doğal olarak "İ"ye basan oyuncu o harfi ASLA
/// bulamıyor ve her denemede boşuna bir hak kaybediyordu. Sabit kelime
/// listesi (`_kWords`) bilerek yalnızca ASCII harfler içeriyor, bu yüzden
/// bu hata sadece "kendi kelimenizi yazın" kutusunu etkiliyordu.
String _trUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

class HangmanGameScreen extends StatefulWidget {
  const HangmanGameScreen({
    super.key, required this.roomId,
    required this.myKey, required this.myName,
  });
  final String roomId, myKey, myName;
  @override
  State<HangmanGameScreen> createState() => _HangmanGameScreenState();
}

class _HangmanGameScreenState extends State<HangmanGameScreen>
    with TickerProviderStateMixin {
  final _db  = FirebaseDatabase.instance.ref();
  late DatabaseReference _ref;
  StreamSubscription? _sub;
  Map<String, dynamic> _room = {};
  bool _roomGone = false;
  final _handled = <String>{};

  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeAnim;
  int _prevWrong = 0;

  // Rewarded: bu tur canlandırma hakkı kullanıldı mı?
  bool _usedRevive = false;

  @override
  void initState() {
    super.initState();
    _ref = _db.child('${GamePaths.hangman}/${widget.roomId}');

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0,  end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0,  end:  0.0),  weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _sub = _ref.onValue.listen(_onFirebase);
  }

  @override
  void dispose() { _shakeCtrl.dispose(); _sub?.cancel(); super.dispose(); }

  // ── Computed ────────────────────────────────────────────────────────────

  Map    get _players   => (_room['players'] as Map?) ?? {};
  String get _phase     => (_room['phase']   as String?) ?? 'choose';
  int    get _round     => (_room['round']   as int?)    ?? 1;
  int    get _maxRound  => (_room['maxRounds'] as int?)  ?? 6;
  String get _chooser   => (_room['chooser'] as String?) ?? 'p1';
  String get _guesser   => _chooser == 'p1' ? 'p2' : 'p1';
  bool   get _amChooser => widget.myKey == _chooser;
  bool   get _amGuesser => widget.myKey == _guesser;

  String?      get _word    => _room['game']?['word'] as String?;
  List<String> get _guessed => List<String>.from(_room['game']?['guessed'] ?? []);
  int          get _wrong   => (_room['game']?['wrong'] as int?) ?? 0;

  String _pName(String k)  => (_players[k]?['name']  as String?) ?? k;
  int    _pScore(String k) => (_players[k]?['score'] as int?)    ?? 0;

  // 5 yanlışta "revive" hakkı göster (henüz 6'ya ulaşmadan)
  bool get _canShowRevive =>
      _amGuesser && _wrong == 5 && !_usedRevive && _phase == 'play';

  // ── Firebase ────────────────────────────────────────────────────────────

  void _onFirebase(DatabaseEvent e) {
    if (!mounted) return;
    if (e.snapshot.value == null) {
      // Oda silindi (rakip ayrıldı ya da bağlantısı koptu) — eskiden burada
      // sessizce return edilirdi ve ekran sonsuza dek donuk kalırdı. Artık
      // ana menüye dönüyoruz.
      if (!_roomGone) {
        _roomGone = true;
        Navigator.popUntil(context, (r) => r.isFirst);
      }
      return;
    }
    final d = Map<String, dynamic>.from(e.snapshot.value as Map);

    final nw = (d['game']?['wrong'] as int?) ?? 0;
    if (nw > _prevWrong) { _prevWrong = nw; _shakeCtrl.forward(from: 0); }

    // Yeni tura geçince revive sıfırla
    final newRound = (d['round'] as int?) ?? 1;
    if (newRound != _round) setState(() => _usedRevive = false);

    setState(() => _room = d);

    final status = d['status'] as String? ?? '';
    final phase  = d['phase']  as String? ?? '';
    final round  = d['round']  as int?    ?? 1;

    if (status == 'finished') {
      if (_handled.add('final')) {
        AdService.instance.onGameEnd(); // interstitial tetikle
        _showFinalDialog(d);
      }
      return;
    }
    if (phase == 'result') {
      if (_handled.add('result_$round')) _showResultDialog(d, round);
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _submitWord(String raw) async {
    final word = _trUpper(raw).replaceAll(RegExp(r'[^A-ZÇĞİÖŞÜ]'), '');
    if (word.length < 3) { context.snack('En az 3 harf olmalı'); return; }
    await _ref.update({
      'game':  {'word': word, 'guessed': [], 'wrong': 0},
      'phase': 'play',
    });
    _prevWrong = 0;
  }

  Future<void> _guessLetter(String letter) async {
    if (!_amGuesser || _word == null) return;
    if (_guessed.contains(letter)) return;

    final newGuessed = [..._guessed, letter];
    final hit        = _word!.contains(letter);
    final newWrong   = hit ? _wrong : _wrong + 1;

    await _ref.child('game').update({'guessed': newGuessed, 'wrong': newWrong});

    final allFound = _word!.split('').every(newGuessed.contains);
    if (allFound)        await _endRound(guesserWon: true,  wrong: newWrong);
    else if (newWrong >= 6) await _endRound(guesserWon: false, wrong: newWrong);
  }

  /// Rewarded reklam izleyerek 1 yanlış sil (5 → 4)
  void _watchAdForRevive() {
    AdService.instance.showRewarded(
      onRewarded: (_) async {
        if (!mounted) return;
        setState(() => _usedRevive = true);
        await _ref.child('game').update({'wrong': _wrong - 1});
        context.snack('🎁 Reklam izledin! 1 can kazandın.');
      },
      onNotReady: () => context.snack('Reklam henüz hazır değil.'),
    );
  }

  Future<void> _endRound({required bool guesserWon, required int wrong}) async {
    final winner = guesserWon ? _guesser : _chooser;
    final bonus  = guesserWon ? (10 - wrong).clamp(4, 10) : 5;
    final prevSc = _pScore(winner);
    final isLast = _round >= _maxRound;

    await _ref.update({
      'phase': 'result',
      'result': {
        'winner': winner,
        'word':   _word,
        'reason': guesserWon ? 'found' : 'hanged',
      },
      'players/$winner/score': prevSc + bonus,
      if (isLast) 'status': 'finished',
    });
  }

  // ÖNEMLİ DÜZELTME: bu metod eskiden "if (!_isHost) return;" ile SADECE
  // p1'de çalışıyordu. Ama "Sonraki Tur" butonu HER İKİ oyuncuya da
  // gösteriliyor — p2 (misafir/tahminci) kendi butonuna bassa bile hiçbir
  // şey olmuyordu (sessiz no-op), oyun sonuç ekranında sonsuza dek takılı
  // kalıyordu çünkü sadece host'un kendi butonuna basması bir işe
  // yarıyordu. Artık HERKES ilerletebiliyor — tazeden okunan round
  // numarası, dialogun gösterdiği rounddan farklıysa (başka oyuncu zaten
  // ilerletmişse) hiçbir şey yapmadan çıkıyor, bu da çifte ilerlemeyi
  // (bir raundun atlanmasını) önlüyor.
  Future<void> _advanceRound(int fromRound) async {
    final snap = await _ref.get();
    if (!snap.exists) return;
    final live = Map<String, dynamic>.from(snap.value as Map);
    final liveRound = (live['round'] as int?) ?? 1;
    if (liveRound != fromRound) return; // başka oyuncu zaten ilerletti
    final liveChooser = (live['chooser'] as String?) ?? 'p1';
    final nextChooser = liveChooser == 'p1' ? 'p2' : 'p1';
    await _ref.update({
      'round':   fromRound + 1,
      'chooser': nextChooser,
      'phase':   'choose',
      'game':    null,
      'result':  null,
    });
  }

  Future<void> _deleteRoom() =>
      _db.child('${GamePaths.hangman}/${widget.roomId}').remove();

  /// Aktif oyunda önceden HİÇBİR çıkış yolu yoktu. Adam Asmaca tam olarak
  /// 2 kişilik (sabit p1/p2 rolleriyle) olduğu için, biri ayrılınca oyun
  /// zaten anlamlı şekilde devam edemez — oda tamamen siliniyor.
  Future<void> _leaveGame() async {
    await _deleteRoom();
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _confirmLeave() async {
    final ok = await confirmLeaveGame(
      context,
      title:        'Oyundan çık?',
      message:      'Aktif bir oyunun ortasındasın. Çıkarsan bu geri alınamaz.',
      // Bu ekranın kendi kırmızı sabiti; değeri zaten `Colors.red.shade700`
      // ile aynı (#D32F2F) ama sabit burada bilerek korunuyor.
      confirmColor: _kRed,
    );
    if (ok) await _leaveGame();
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _showResultDialog(Map<String, dynamic> d, int round) {
    final result = Map<String, dynamic>.from(d['result'] as Map);
    final winner = result['winner']  as String;
    final word   = result['word']    as String;
    final reason = result['reason']  as String;
    final iWon   = winner == widget.myKey;
    final isLast = round >= ((d['maxRounds'] as int?) ?? 6);

    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(iWon ? '🎉 Tur Kazandın!' : '😔 Tur Kaybettin',
            textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            reason == 'found'
                ? '${_pName(winner)} kelimeyi buldu!'
                : 'Adam asıldı! ${_pName(winner)} puan aldı.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Kelime: ', style: TextStyle(color: Colors.grey)),
              Text(word, style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: Colors.blue, letterSpacing: 3)),
            ]),
          ),
          const SizedBox(height: 14),
          _ScoreRow(
              p1Name: _pName('p1'), p1Score: _pScore('p1'),
              p2Name: _pName('p2'), p2Score: _pScore('p2'),
              myKey:  widget.myKey),
        ]),
        actions: [FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kRed),
          onPressed: () {
            Navigator.pop(context);
            if (!isLast) _advanceRound(round);
          },
          child: Text(isLast ? 'Sonuçlara Git' : 'Sonraki Tur →'),
        )],
      ),
    );
  }

  void _showFinalDialog(Map<String, dynamic> d) {
    final p1s = _pScore('p1');
    final p2s = _pScore('p2');
    final headline = p1s > p2s
        ? '🏆 ${_pName("p1")} kazandı!'
        : p2s > p1s ? '🏆 ${_pName("p2")} kazandı!' : '🤝 Berabere!';
    final myScore = _pScore(widget.myKey);
    final otherScore = widget.myKey == 'p1' ? p2s : p1s;
    ProfileService.instance
        .reportGameResult(gameId: 'hangman', won: myScore > otherScore)
        .then((_) => AchievementService.instance.checkAndUnlock());

    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Oyun Bitti!', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(headline, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _ScoreRow(
              p1Name: _pName('p1'), p1Score: p1s,
              p2Name: _pName('p2'), p2Score: p2s,
              myKey:  widget.myKey),
        ]),
        actions: [FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kRed),
          onPressed: () async {
            await _deleteRoom();
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: const Text('Ana Menü'),
        )],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_room.isEmpty) {
      return const Scaffold(
          backgroundColor: _kBg,
          body: Center(child: CircularProgressIndicator(color: _kRed)));
    }

    return AZLeaveGuard(
      onLeave: _confirmLeave,
      child: Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        _TopBar(
          round: _round, maxRounds: _maxRound,
          p1Name: _pName('p1'), p1Score: _pScore('p1'),
          isP1Me: widget.myKey == 'p1',
          p2Name: _pName('p2'), p2Score: _pScore('p2'),
          onLeave: _confirmLeave,
        ),
        Expanded(
          child: _phase == 'choose' ? _buildChoosePhase() : _buildPlayPhase(),
        ),
        // Banner reklam — oyun altında
        const BannerAdWidget(),
      ])),
      ),
    );
  }

  Widget _buildChoosePhase() {
    if (_amChooser) {
      return _WordChooserPanel(
          guesserName: _pName(_guesser), onSubmit: _submitWord);
    }
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(width: 56, height: 56,
          child: CircularProgressIndicator(strokeWidth: 3, color: _kRed)),
      const SizedBox(height: 24),
      Text('${_pName(_chooser)} kelime seçiyor...',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Hazır ol!', style: TextStyle(color: _kGrey)),
    ]));
  }

  Widget _buildPlayPhase() {
    if (_word == null) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color.fromRGBO(
              _amGuesser ? 46 : 255,
              _amGuesser ? 125 : 152,
              _amGuesser ? 50  : 0,
              0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _amGuesser ? _kGreen : Colors.orange),
        ),
        child: Text(
          _amGuesser ? '🔍 Sıra sende — harf seç!'
              : '👀 ${_pName(_guesser)} tahmin ediyor...',
          style: TextStyle(
              color: _amGuesser ? _kGreen : Colors.orange.shade800,
              fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),

      // ── Revive butonu (5 yanlışta göster) ──────────────────────────────
      if (_canShowRevive)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: RewardedAdButton(
            label: '1 Can Kazan',
            icon:  Icons.favorite_rounded,
            color: Colors.deepOrange,
            onRewarded: (_) async {
              if (!mounted) return;
              setState(() => _usedRevive = true);
              await _ref.child('game').update({'wrong': _wrong - 1});
              context.snack('🎁 1 can kazandın!');
            },
          ),
        ),

      AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) =>
            Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
        child: SizedBox(
          height: 180,
          child: CustomPaint(
              size: const Size(220, 180),
              painter: _HangmanPainter(_wrong)),
        ),
      ),
      Text('${_wrong}/6 yanlış',
          style: TextStyle(
              color: _wrong >= 4 ? _kRed : _kGrey,
              fontSize: 12,
              fontWeight: _wrong >= 5 ? FontWeight.bold : FontWeight.normal)),
      const SizedBox(height: 8),
      _WordDisplay(word: _word!, guessed: _guessed),
      const Spacer(),
      if (_amGuesser)
        _TurkishKeyboard(guessed: _guessed, word: _word!, onTap: _guessLetter)
      else
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${_pName(_guesser)} tahmin ediyor...',
              style: const TextStyle(
                  color: _kGrey, fontStyle: FontStyle.italic, fontSize: 14)),
        ),
      const SizedBox(height: 4),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WORD CHOOSER PANEL
// ════════════════════════════════════════════════════════════════════════════

class _WordChooserPanel extends StatefulWidget {
  const _WordChooserPanel({required this.guesserName, required this.onSubmit});
  final String guesserName;
  final Future<void> Function(String) onSubmit;
  @override
  State<_WordChooserPanel> createState() => _WordChooserPanelState();
}

class _WordChooserPanelState extends State<_WordChooserPanel> {
  final _ctrl = TextEditingController();
  bool _busy  = false;

  Future<void> _send(String w) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onSubmit(w);
    if (mounted) setState(() { _busy = false; _ctrl.clear(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _kRedLt, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline, color: _kRed, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '${widget.guesserName} bu kelimeyi tahmin edecek!',
              style: const TextStyle(color: _kRed, fontSize: 13),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-ZÇĞİÖŞÜa-zçğışöü]'))
          ],
          style: const TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Kendi kelimenizi yazın',
            suffixIcon: IconButton(
              icon: _busy
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kRed))
                  : const Icon(Icons.send_rounded, color: _kRed),
              onPressed: _busy ? null : () => _send(_ctrl.text),
            ),
          ),
          onSubmitted: _send,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: _kRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: _busy ? null : () => _send(_ctrl.text),
            child: _busy
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('GÖNDER', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        const Text('— veya listeden seç —',
            style: TextStyle(color: _kGrey, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 2.5,
              mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: _kWords.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: _busy ? null : () => _send(_kWords[i]),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _kRedLt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kRed.withAlpha(76))),
              child: Text(_kWords[i],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11, color: _kRed)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WORD DISPLAY
// ════════════════════════════════════════════════════════════════════════════

class _WordDisplay extends StatelessWidget {
  const _WordDisplay({required this.word, required this.guessed});
  final String word; final List<String> guessed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Wrap(
      alignment: WrapAlignment.center, spacing: 5, runSpacing: 6,
      children: word.split('').map((l) {
        final show = guessed.contains(l);
        return SizedBox(
          width: 32, height: 44,
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(show ? l : '',
                style: const TextStyle(fontSize: 22,
                    fontWeight: FontWeight.bold, color: _kRed)),
            const SizedBox(height: 2),
            Container(height: 2.5,
                decoration: BoxDecoration(
                    color: show ? _kRed : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2))),
          ]),
        );
      }).toList(),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// TURKISH KEYBOARD
// ════════════════════════════════════════════════════════════════════════════

class _TurkishKeyboard extends StatelessWidget {
  const _TurkishKeyboard({
    required this.guessed, required this.word, required this.onTap});
  final List<String> guessed;
  final String       word;
  final Future<void> Function(String) onTap;

  static const _rows = [
    ['Q','W','E','R','T','Y','U','I','O','P','Ğ','Ü'],
    ['A','S','D','F','G','H','J','K','L','Ş','İ'],
    ['Z','X','C','V','B','N','M','Ö','Ç'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Column(
        children: _rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((letter) {
              final used    = guessed.contains(letter);
              final correct = used && word.contains(letter);
              final wrong   = used && !word.contains(letter);
              return GestureDetector(
                onTap: used ? null : () => onTap(letter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 28, height: 36, margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: correct ? _kGreen
                        : wrong ? Colors.grey.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: correct ? _kGreen : Colors.grey.shade300),
                    boxShadow: used ? [] : const [
                      BoxShadow(color: Color(0x14000000),
                          blurRadius: 2, offset: Offset(0, 1))
                    ],
                  ),
                  child: Center(child: Text(letter,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: correct ? Colors.white
                              : wrong ? Colors.grey.shade400
                              : Colors.black87))),
                ),
              );
            }).toList(),
          ),
        )).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HANGMAN PAINTER
// ════════════════════════════════════════════════════════════════════════════

class _HangmanPainter extends CustomPainter {
  const _HangmanPainter(this.wrong);
  final int wrong;

  @override
  void paint(Canvas canvas, Size s) {
    final g = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 5 ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(s.width*.10, s.height*.95), Offset(s.width*.55, s.height*.95), g);
    canvas.drawLine(Offset(s.width*.22, s.height*.95), Offset(s.width*.22, s.height*.04), g);
    canvas.drawLine(Offset(s.width*.22, s.height*.04), Offset(s.width*.68, s.height*.04), g);
    canvas.drawLine(Offset(s.width*.68, s.height*.04), Offset(s.width*.68, s.height*.18), g);

    final b = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 4 ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (wrong >= 1) canvas.drawCircle(Offset(s.width*.68, s.height*.26), s.height*.08, b);
    if (wrong >= 2) canvas.drawLine(Offset(s.width*.68, s.height*.34), Offset(s.width*.68, s.height*.60), b);
    if (wrong >= 3) canvas.drawLine(Offset(s.width*.68, s.height*.42), Offset(s.width*.52, s.height*.53), b);
    if (wrong >= 4) canvas.drawLine(Offset(s.width*.68, s.height*.42), Offset(s.width*.84, s.height*.53), b);
    if (wrong >= 5) canvas.drawLine(Offset(s.width*.68, s.height*.60), Offset(s.width*.52, s.height*.80), b);
    if (wrong >= 6) {
      canvas.drawLine(Offset(s.width*.68, s.height*.60), Offset(s.width*.84, s.height*.80), b);
      final d = Paint()..color = _kRed..strokeWidth = 2.5..strokeCap = StrokeCap.round;
      final cx = s.width*.68; final cy = s.height*.26;
      canvas.drawLine(Offset(cx-6, cy-6), Offset(cx+6, cy+6), d);
      canvas.drawLine(Offset(cx+6, cy-6), Offset(cx-6, cy+6), d);
    }
  }

  @override bool shouldRepaint(_HangmanPainter o) => o.wrong != wrong;
}

// ════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.round, required this.maxRounds,
    required this.p1Name, required this.p1Score, required this.isP1Me,
    required this.p2Name, required this.p2Score,
    required this.onLeave,
  });
  final int round, maxRounds;
  final String p1Name, p2Name;
  final int p1Score, p2Score;
  final bool isP1Me;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color.lerp(_kRed, Colors.black, 0.15)!, _kRed],
      ),
      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
    ),
    padding: const EdgeInsets.fromLTRB(4, 10, 14, 10),
    child: Row(children: [
      IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onLeave),
      _Pill(name: p1Name, score: p1Score, isMe: isP1Me),
      Expanded(child: Column(children: [
        Text('Tur $round/$maxRounds',
            style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const Text('ADAM ASMACA',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ])),
      _Pill(name: p2Name, score: p2Score, isMe: !isP1Me),
    ]),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.name, required this.score, required this.isMe});
  final String name; final int score; final bool isMe;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: isMe ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isMe
            ? const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))]
            : null),
    child: Column(children: [
      Text(name, style: TextStyle(fontSize: 11,
          color: isMe ? _kRed : Colors.white70, fontWeight: FontWeight.w600)),
      Text('$score', style: TextStyle(fontSize: 18,
          fontWeight: FontWeight.bold, color: isMe ? _kRed : Colors.white)),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// SCORE ROW
// ════════════════════════════════════════════════════════════════════════════

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.p1Name, required this.p1Score,
    required this.p2Name, required this.p2Score,
    required this.myKey,
  });
  final String p1Name, p2Name, myKey;
  final int p1Score, p2Score;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _Item(name: p1Name, score: p1Score, isMe: myKey == 'p1'),
      const Text('vs', style: TextStyle(color: _kGrey)),
      _Item(name: p2Name, score: p2Score, isMe: myKey == 'p2'),
    ]),
  );
}

class _Item extends StatelessWidget {
  const _Item({required this.name, required this.score, required this.isMe});
  final String name; final int score; final bool isMe;

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(name, style: TextStyle(fontWeight: FontWeight.bold,
        color: isMe ? _kRed : Colors.black87)),
    Text('$score', style: TextStyle(fontSize: 24,
        fontWeight: FontWeight.bold, color: isMe ? _kRed : Colors.black54)),
    Text('puan', style: TextStyle(fontSize: 11, color: isMe ? _kRed : _kGrey)),
  ]);
}
