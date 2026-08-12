import 'package:flutter/material.dart';

import '../../core/services/achievement_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import 'mystery_case_data.dart';

const kNoirGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1A1A2E), Color(0xFF3D0C0C)],
);
const _kAccent = Color(0xFF8B0000);

// ═══════════════════════════════════════════════════════════════════════════
// LOBİ
// ═══════════════════════════════════════════════════════════════════════════

class MysteryLobbyScreen extends StatelessWidget {
  const MysteryLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) => AZGradientScaffold(
    gradient: kNoirGradient,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        const SizedBox(height: 4),
        const Text('🕵️', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 10),
        const Text('GECE EKSPRESİ CİNAYETİ',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        const Text('Polisiye · İz Sürme · ~10 dakika',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 24),
        AZFrostCard(
          opacity: 0.08,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('🚂 Vaka Dosyası',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 10),
              Text(
                'Bir gece ekspresinde esrarengiz bir ölüm. Kanıtları topla, '
                'şüphelileri sorguya çek, gerçek katili bul — ama dikkat et, '
                'en olası şüpheli her zaman suçlu olan değildir.\n\n'
                'Tek başına oynanır ama arkadaşlarınla birlikte tartışarak '
                'çözmek daha eğlenceli. Kararın kesinleşince geri dönüş yok!',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AZButton(
          label: 'SORUŞTURMAYA BAŞLA',
          icon: Icons.search_rounded,
          color: _kAccent,
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MysteryCaseScreen())),
        ),
        const SizedBox(height: 16),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ANA VAKA EKRANI — giriş, olay yeri + şüpheliler, sonuç
// ═══════════════════════════════════════════════════════════════════════════

enum _Phase { intro, hub, ended }

class MysteryCaseScreen extends StatefulWidget {
  const MysteryCaseScreen({super.key});

  @override
  State<MysteryCaseScreen> createState() => _MysteryCaseScreenState();
}

class _MysteryCaseScreenState extends State<MysteryCaseScreen> {
  _Phase _phase = _Phase.intro;
  int _introIndex = 0;
  final Set<String> _foundClues = {};
  String? _accusedId;

  void _nextIntro() {
    if (_introIndex < kIntroPages.length - 1) {
      setState(() => _introIndex++);
    } else {
      setState(() => _phase = _Phase.hub);
    }
  }

  void _discoverClue(String id) => setState(() => _foundClues.add(id));

  Future<void> _openAccusation() async {
    final chosen = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _AccusationScreen()),
    );
    if (chosen == null || !mounted) return;
    final correct = chosen == kCulpritId;
    await ProfileService.instance.reportGameResult(gameId: 'mysterycase1', won: correct);
    await AchievementService.instance.checkAndUnlock();
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
              const Text('🚂', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 18),
              Text(kIntroPages[_introIndex],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.7)),
            ]),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            for (var i = 0; i < kIntroPages.length; i++)
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
          label: _introIndex < kIntroPages.length - 1 ? 'DEVAM ET' : 'SORUŞTURMAYA BAŞLA',
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
          const Expanded(
            child: Text('GECE EKSPRESİ CİNAYETİ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                  child: Text('Not Defterin: ${_foundClues.length}/${kClues.length} ipucu',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            _label('🔍  OLAY YERİ · kanıt aramak için dokun'),
            const SizedBox(height: 10),
            for (final c in kClues) _clueCard(c),
            const SizedBox(height: 22),
            _label('🗣️  ŞÜPHELİLER · sorgulamak için dokun'),
            const SizedBox(height: 10),
            for (final s in kSuspects) _suspectCard(s),
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
    final correct = _accusedId == kCulpritId;
    final ending = kEndings[_accusedId]!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        Text(correct ? '🎯' : '❌', style: const TextStyle(fontSize: 56)),
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
        Text('${_foundClues.length}/${kClues.length} ipucu buldun',
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
                label: 'ANA MENÜ', color: _kAccent, onPressed: () => Navigator.pop(context)),
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
  const _AccusationScreen();

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
              for (final s in kSuspects)
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
