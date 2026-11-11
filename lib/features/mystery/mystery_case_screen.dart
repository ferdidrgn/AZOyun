import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/achievement_service.dart';
import '../../core/services/mystery_campaign_service.dart';
import '../../core/services/profile_service.dart';
import 'mystery_case_data.dart';

const kNoirGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF182829), Color(0xFF453121)],
);
const _paper = Color(0xFFEFE2C7);
const _gold = Color(0xFFE7BB75);
const _panel = Color(0xFF253333);
const _label = TextStyle(
    color: _gold,
    fontSize: 12,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w700);

class MysteryLobbyScreen extends StatefulWidget {
  const MysteryLobbyScreen({super.key});

  @override
  State<MysteryLobbyScreen> createState() => _MysteryLobbyScreenState();
}

class _MysteryLobbyScreenState extends State<MysteryLobbyScreen> {
  final _campaign = MysteryCampaignService.instance;
  late Future<void> _progress = _campaign.load();

  Future<void> _open(MysteryChapter chapter) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => _ChapterScreen(chapter: chapter)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => _CasePage(
        title: 'Dedektif Dosyaları',
        child: FutureBuilder<void>(
          future: _progress,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: FilledButton(
                onPressed: () => setState(() => _progress = _campaign.load()),
                child: const Text('İlerleme okunamadı · Tekrar dene'),
              ));
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final next = kMysteryChapters.indexWhere(
              (chapter) => !_campaign.isCompleted(chapter.id),
            );
            final total = kMysteryChapters.length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: [
                const Text('SARNIÇ KIYISI  /  10 BÖLÜM', style: _label),
                const SizedBox(height: 10),
                const _StoryTitle('Silt Defteri'),
                const SizedBox(height: 12),
                const _StoryParagraph(
                  'Gece postasında bulunan bir ceset, on sekiz yıl önce kapanan bir dosyayı yeniden açıyor.',
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: (next == -1 ? total : next) / total,
                  color: _gold,
                  backgroundColor: _panel,
                  semanticsLabel: 'Tamamlanan bölümler',
                ),
                const SizedBox(height: 16),
                if (next != -1)
                  FilledButton(
                    onPressed: () => _open(kMysteryChapters[next]),
                    child: Text(next == 0
                        ? 'Soruşturmaya başla'
                        : 'Soruşturmaya devam et'),
                  )
                else
                  const Text('Dosya kapandı. Her bölümü yeniden okuyabilirsin.',
                      style: TextStyle(color: _gold)),
                const SizedBox(height: 22),
                for (final chapter in kMysteryChapters)
                  _chapterTile(
                      chapter, next == -1 || chapter.number <= next + 1),
              ],
            );
          },
        ),
      );

  Widget _chapterTile(MysteryChapter chapter, bool unlocked) => ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: unlocked,
        onTap: unlocked ? () => _open(chapter) : null,
        leading: Text(chapter.number.toString().padLeft(2, '0'), style: _label),
        title: Text(unlocked ? chapter.title : 'Kilitli bölüm'),
        trailing: Icon(
          _campaign.isCompleted(chapter.id)
              ? Icons.check_circle_outline
              : unlocked
                  ? Icons.arrow_forward
                  : Icons.lock_outline,
          color: _gold,
        ),
      );
}

class _ChapterScreen extends StatefulWidget {
  const _ChapterScreen({required this.chapter});

  final MysteryChapter chapter;

  @override
  State<_ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<_ChapterScreen> {
  final _seen = <int>{};
  final _scroll = ScrollController();
  int? _selected;
  String? _feedback;
  bool _solved = false;
  bool _saving = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _selected == null) return;
    final chapter = widget.chapter;
    if (_selected != chapter.solution) {
      setState(() => _feedback =
          'Bu çıkarım delillerin tümünü açıklamıyor. Deftere dönüp tekrar karşılaştır.');
      return;
    }
    setState(() => _saving = true);
    bool firstSolve;
    try {
      firstSolve =
          await MysteryCampaignService.instance.markCompleted(chapter.id);
    } catch (error) {
      debugPrint('Silt Defteri ilerleme kaydı: $error');
      if (mounted)
        setState(() {
          _saving = false;
          _feedback = 'İlerleme kaydedilemedi. Yeniden dene.';
        });
      return;
    }
    if (mounted) {
      setState(() {
        _saving = false;
        _solved = true;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    if (firstSolve) unawaited(_award());
  }

  Future<void> _award() async {
    try {
      await ProfileService.instance
          .reportGameResult(gameId: 'mysterycase1', won: true);
      await AchievementService.instance.checkAndUnlock();
    } catch (error) {
      debugPrint('Silt Defteri ödül kaydı: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final count = chapter.evidence.length;
    final seen = _seen.length;
    final number = chapter.number;
    final total = kMysteryChapters.length;
    return _CasePage(
      title: 'Silt Defteri',
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Text('BÖLÜM $number / $total', style: _label),
          const SizedBox(height: 10),
          _StoryTitle(chapter.title),
          const SizedBox(height: 22),
          if (_solved) ...[
            Text(number == total ? 'SON SÖZ' : 'ÇIKARIM DOĞRULANDI',
                style: _label),
            const SizedBox(height: 12),
            _StoryParagraph(chapter.reconstruction),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bölüm listesine dön'),
            ),
          ] else ...[
            for (final scene in chapter.scenes) ...[
              _StoryParagraph(scene),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 10),
            Text('DELİL DEFTERİ  ·  $seen/$count', style: _label),
            const SizedBox(height: 10),
            for (var i = 0; i < count; i++)
              ExpansionTile(
                key: ValueKey(chapter.evidence[i].title),
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                backgroundColor: _panel,
                textColor: _paper,
                iconColor: _gold,
                leading: Icon(
                    _seen.contains(i) ? Icons.check : Icons.article_outlined,
                    color: _gold),
                onExpansionChanged: (open) {
                  if (open) setState(() => _seen.add(i));
                },
                title: Text(chapter.evidence[i].title),
                children: [_StoryParagraph(chapter.evidence[i].account)],
              ),
            const SizedBox(height: 24),
            const Text('ÇIKARIM', style: _label),
            const SizedBox(height: 8),
            Text(chapter.question,
                style: const TextStyle(fontSize: 20, color: _paper)),
            const SizedBox(height: 12),
            if (seen < count)
              const Text('Karar vermek için üç delili de incele.')
            else ...[
              for (var i = 0; i < chapter.answers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                              _selected = i;
                              _feedback = null;
                            }),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: _paper,
                      backgroundColor: _selected == i ? _panel : null,
                      side: BorderSide(
                          color: _selected == i ? _gold : Colors.white54),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Semantics(
                        selected: _selected == i,
                        child: Text(chapter.answers[i])),
                  ),
                ),
              if (_feedback != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                      liveRegion: true,
                      child: Text(_feedback!,
                          style: const TextStyle(color: _gold))),
                ),
              FilledButton(
                onPressed: _saving || _selected == null ? null : _submit,
                child: Text(_saving ? 'Kaydediliyor…' : 'Çıkarımı doğrula'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CasePage extends StatelessWidget {
  const _CasePage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _gold, surface: _panel),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF182829),
          appBar:
              AppBar(title: Text(title), backgroundColor: Colors.transparent),
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: kNoirGradient),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: child,
            )),
          ),
        ),
      );
}

class _StoryTitle extends StatelessWidget {
  const _StoryTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: _paper, fontFamily: 'serif', fontSize: 39, height: 1.1),
      );
}

class _StoryParagraph extends StatelessWidget {
  const _StoryParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: _paper, fontSize: 17, height: 1.65),
      );
}
