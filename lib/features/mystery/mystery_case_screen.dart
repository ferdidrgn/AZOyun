import 'package:flutter/material.dart';

import '../../core/services/achievement_service.dart';
import '../../core/services/mystery_campaign_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'mystery_case_data.dart';

const kNoirGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2A2A3A), Color(0xFF4A2222)],
);
const _kAccent = Color(0xFFA85C5C);
const _kGoldAccent = Color(0xFFD9A25C);

/// Türkçe büyük harfe çevirir (`toUpperCase()` "i" → noktasız "I" yapar,
/// başlıklarda "İ" olması gerekir).
String _trUpper(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

// ═══════════════════════════════════════════════════════════════════════════
// KAMPANYA HUB — vaka listesi, kilit durumu
// ═══════════════════════════════════════════════════════════════════════════

class MysteryLobbyScreen extends StatefulWidget {
  const MysteryLobbyScreen({super.key});

  @override
  State<MysteryLobbyScreen> createState() => _MysteryLobbyScreenState();
}

class _MysteryLobbyScreenState extends State<MysteryLobbyScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    MysteryCampaignService.instance.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  bool _isUnlocked(int index) {
    if (index == 0) return true;
    return MysteryCampaignService.instance.isCompleted(kMysteryCases[index - 1].id);
  }

  Future<void> _openCase(MysteryCase c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MysteryCaseScreen(mysteryCase: c)),
    );
    if (mounted) setState(() {}); // yeni vaka açılmış olabilir
  }

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
    gradient: kNoirGradient,
    child: _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 4),
              const Text('🕵️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 10),
              const Text('DEDEKTİF DOSYALARI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 6),
              const Text('Birbirine bağlı vakalar · her biri bir öncekini açar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 24),
              for (var i = 0; i < kMysteryCases.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _caseCard(kMysteryCases[i], _isUnlocked(i)),
                ),
              const SizedBox(height: 8),
              AZFrostCard(
                opacity: 0.08,
                child: Text(
                  MysteryCampaignService.instance.isCompleted(kMysteryCases.last.id)
                      ? '🕯️ Dedektif Dosyaları — hikaye tamamlandı. Vakaları istediğin zaman tekrar oynayabilirsin.'
                      : '📖 5 bölümlük tek bir hikaye — sonuna kadar iz sür.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
  );

  Widget _caseCard(MysteryCase c, bool unlocked) {
    final done = MysteryCampaignService.instance.isCompleted(c.id);
    return GestureDetector(
      onTap: unlocked ? () => _openCase(c) : null,
      child: AZFrostCard(
        opacity: unlocked ? (c.isFinale ? 0.16 : 0.1) : 0.05,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked ? const Color(0x26FFFFFF) : const Color(0x14FFFFFF),
              shape: BoxShape.circle,
              border: c.isFinale ? Border.all(color: _kGoldAccent, width: 2) : null,
            ),
            child: Text(unlocked ? c.emoji : '🔒', style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                      c.isFinale
                          ? 'BÜYÜK FİNAL'
                          : 'VAKA ${c.number}',
                      style: TextStyle(
                          color: c.isFinale ? _kGoldAccent : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  if (done) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded, color: AZColors.success, size: 13),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(unlocked ? c.title : '???',
                    style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                    unlocked ? c.subtitle : 'Önceki vakayı tamamlayınca açılır',
                    style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANA VAKA EKRANI — giriş, olay yeri + şüpheliler, sonuç
// ═══════════════════════════════════════════════════════════════════════════

enum _Phase { intro, hub, ended }

class MysteryCaseScreen extends StatefulWidget {
  const MysteryCaseScreen({super.key, required this.mysteryCase});

  final MysteryCase mysteryCase;

  @override
  State<MysteryCaseScreen> createState() => _MysteryCaseScreenState();
}

class _MysteryCaseScreenState extends State<MysteryCaseScreen> {
  _Phase _phase = _Phase.intro;
  int _introIndex = 0;
  final Set<String> _foundClues = {};
  String? _accusedId;

  MysteryCase get _case => widget.mysteryCase;

  void _nextIntro() {
    if (_introIndex < _case.introPages.length - 1) {
      setState(() => _introIndex++);
    } else {
      setState(() => _phase = _Phase.hub);
    }
  }

  void _discoverClue(String id) => setState(() => _foundClues.add(id));

  Future<void> _openAccusation() async {
    final chosen = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _AccusationScreen(suspects: _case.suspects)),
    );
    if (chosen == null || !mounted) return;
    final correct = chosen == _case.culpritId;
    await ProfileService.instance.reportGameResult(gameId: 'mysterycase1', won: correct);
    await AchievementService.instance.checkAndUnlock();
    await MysteryCampaignService.instance.markCompleted(_case.id);
    if (!mounted) return;
    setState(() {
      _accusedId = chosen;
      _phase = _Phase.ended;
    });
  }

  void _restart() {
    setState(() {
      _phase = _Phase.intro;
      _introIndex = 0;
      _foundClues.clear();
      _accusedId = null;
    });
  }

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
    gradient: kNoirGradient,
    child: switch (_phase) {
      _Phase.intro => _buildIntro(),
      _Phase.hub => _buildHub(),
      _Phase.ended => _buildEnding(),
    },
  );

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        const Spacer(),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateX(-0.08)
            ..rotateY(0.05),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(AZRadius.lg),
              border: Border.all(color: const Color(0x33FFFFFF)),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 14))],
            ),
            child: Column(children: [
              Text(_case.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 18),
              Text(_case.introPages[_introIndex],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.7)),
            ]),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            for (var i = 0; i < _case.introPages.length; i++)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                      color: i <= _introIndex ? _kAccent : Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        AZButton(
          label: _introIndex < _case.introPages.length - 1 ? 'DEVAM ET' : 'SORUŞTURMAYA BAŞLA',
          icon: Icons.arrow_forward_rounded,
          color: _kAccent,
          onPressed: _nextIntro,
        ),
      ]),
    );
  }

  Widget _buildHub() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Text(_trUpper(_case.title),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 48),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AZFrostCard(
              child: Row(children: [
                const Icon(Icons.menu_book_rounded, color: Colors.white70),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Not Defterin: ${_foundClues.length}/${_case.clues.length} ipucu',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            _label('🔍  OLAY YERİ · kanıt aramak için dokun'),
            const SizedBox(height: 10),
            for (final c in _case.clues) _clueCard(c),
            const SizedBox(height: 22),
            _label('🗣️  ŞÜPHELİLER · sorgulamak için dokun'),
            const SizedBox(height: 10),
            for (final s in _case.suspects) _suspectCard(s),
            const SizedBox(height: 26),
            AZButton(label: '⚖️  SUÇLAMAYI YAP', color: _kAccent, onPressed: _openAccusation),
          ]),
        ),
      ),
    ]);
  }

  Widget _label(String t) =>
      Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1));

  Widget _clueCard(MysteryClue c) {
    final found = _foundClues.contains(c.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showClueDialog(c),
        child: AZFrostCard(
          opacity: found ? 0.16 : 0.08,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Text(c.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(c.title,
                  style: TextStyle(
                      color: found ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
            ),
            Icon(
              found ? Icons.check_circle_rounded : Icons.search_rounded,
              color: found ? AZColors.success : Colors.white38,
              size: 18,
            ),
          ]),
        ),
      ),
    );
  }

  void _showClueDialog(MysteryClue c) {
    _discoverClue(c.id);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${c.emoji}  ${c.title}'),
        content: Text(c.description, style: const TextStyle(height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
      ),
    );
  }

  Widget _suspectCard(MysterySuspect s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => _SuspectDialogueScreen(suspect: s))),
        child: AZFrostCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Text(s.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(s.role, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white38, size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _buildEnding() {
    final correct = _accusedId == _case.culpritId;
    final ending = _case.endings[_accusedId]!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        Text(correct ? (_case.isFinale ? '🎭' : '🎯') : '❌', style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(ending.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        AZFrostCard(
          opacity: 0.1,
          child: Text(ending.body, style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 14)),
        ),
        const SizedBox(height: 16),
        Text('${_foundClues.length}/${_case.clues.length} ipucu buldun',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 26),
        Row(children: [
          Expanded(
            child: AZButton(
                label: 'TEKRAR OYNA',
                color: Colors.grey.shade700,
                onPressed: _restart),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AZButton(
                label: 'DOSYALARA DÖN', color: _kAccent, onPressed: () => Navigator.pop(context)),
          ),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ŞÜPHELİ SORGU EKRANI
// ═══════════════════════════════════════════════════════════════════════════

class _SuspectDialogueScreen extends StatefulWidget {
  const _SuspectDialogueScreen({required this.suspect});

  final MysterySuspect suspect;

  @override
  State<_SuspectDialogueScreen> createState() => _SuspectDialogueScreenState();
}

class _SuspectDialogueScreenState extends State<_SuspectDialogueScreen> {
  final Set<int> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final s = widget.suspect;
    return AZGradientScaffold(
      gradient: kNoirGradient,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            Expanded(
              child: Text(s.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 48),
          ]),
          Text(s.role, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 16),
          Text(s.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          AZFrostCard(
            opacity: 0.1,
            child: Text(s.flavor,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, height: 1.5)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: s.questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final qa = s.questions[i];
                final open = _revealed.contains(i);
                return AZFrostCard(
                  opacity: 0.1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _revealed.add(i)),
                        child: Row(children: [
                          const Icon(Icons.help_outline_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(qa.question,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                          ),
                        ]),
                      ),
                      if (open) ...[
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),
                        Text('"${qa.answer}"',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUÇLAMA EKRANI
// ═══════════════════════════════════════════════════════════════════════════

class _AccusationScreen extends StatefulWidget {
  const _AccusationScreen({required this.suspects});

  final List<MysterySuspect> suspects;

  @override
  State<_AccusationScreen> createState() => _AccusationScreenState();
}

class _AccusationScreenState extends State<_AccusationScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
    gradient: kNoirGradient,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          const Expanded(
            child: Text('KİMİ SUÇLUYORSUN?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 48),
        ]),
        const SizedBox(height: 6),
        const Text('Bu karar geri alınamaz, dedektif.',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              for (final s in widget.suspects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = s.id),
                    child: AZFrostCard(
                      opacity: _selected == s.id ? 0.22 : 0.08,
                      child: Row(children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(s.role, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (_selected == s.id)
                          const Icon(Icons.check_circle_rounded, color: AZColors.success),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AZButton(
          label: 'SUÇLAMAYI ONAYLA',
          color: _kAccent,
          onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
        ),
        const SizedBox(height: 12),
      ]),
    ),
  );
}
