import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

enum _LetterMark { correct, misplaced, absent }

class _GuessRow {
  const _GuessRow(this.word, this.marks);
  final String word;
  final List<_LetterMark> marks;
}

class _WordlePlayer {
  const _WordlePlayer(this.id, this.name, this.firstClub);
  final String id;
  final String name;
  final String? firstClub;
}

class FootballWordleScreen extends StatefulWidget {
  const FootballWordleScreen({super.key});

  @override
  State<FootballWordleScreen> createState() => _FootballWordleScreenState();
}

class _FootballWordleScreenState extends State<FootballWordleScreen> {
  final _random = Random();
  final _input = TextEditingController();
  List<_WordlePlayer> _players = const [];
  _WordlePlayer? _answer;
  final List<_GuessRow> _guesses = [];
  bool _loading = true;
  bool _done = false;
  bool _won = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is List)
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    if (raw is Map)
      return raw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    return const [];
  }

  String _word(String name) =>
      name.trim().split(RegExp(r'\s+')).last.toUpperCase();

  Future<void> _load() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('footballCatalog/current/players')
          .get()
          .timeout(const Duration(seconds: 12));
      final players = _maps(snapshot.value)
          .map((raw) {
            final careers = _maps(raw['careers'])
              ..sort((a, b) => (a['startYear'] is num
                          ? (a['startYear'] as num).toInt()
                          : 9999)
                      .compareTo(
                    b['startYear'] is num
                        ? (b['startYear'] as num).toInt()
                        : 9999,
                  ));
            final firstClub =
                careers.isEmpty ? null : careers.first['label']?.toString();
            return _WordlePlayer(
                '${raw['id'] ?? ''}', '${raw['name'] ?? ''}', firstClub);
          })
          .where((player) =>
              player.id.isNotEmpty &&
              RegExp(r'^[A-Z]{5,8}$').hasMatch(_word(player.name)))
          .toList();
      if (players.length < 30)
        throw StateError('Futbolcu Wordle için yeterli oyuncu adı yok.');
      if (!mounted) return;
      setState(() {
        _players = players;
        _answer = players[_random.nextInt(players.length)];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  List<_LetterMark> _score(String guess, String target) {
    final marks = List<_LetterMark>.filled(guess.length, _LetterMark.absent);
    final remaining = <String, int>{};
    for (var i = 0; i < target.length; i++) {
      if (guess[i] == target[i]) {
        marks[i] = _LetterMark.correct;
      } else {
        remaining[target[i]] = (remaining[target[i]] ?? 0) + 1;
      }
    }
    for (var i = 0; i < guess.length; i++) {
      if (marks[i] == _LetterMark.correct) continue;
      final count = remaining[guess[i]] ?? 0;
      if (count > 0) {
        marks[i] = _LetterMark.misplaced;
        remaining[guess[i]] = count - 1;
      }
    }
    return marks;
  }

  void _submit() {
    final answer = _answer;
    if (_done || answer == null) return;
    final word = _word(_input.text);
    if (!RegExp(r'^[A-Z]{5,8}$').hasMatch(word)) {
      setState(() =>
          _error = '5–8 harfli İngilizce harflerden oluşan bir soyad yaz.');
      return;
    }
    if (word.length != _word(answer.name).length) {
      setState(
          () => _error = 'Bugünkü cevap ${_word(answer.name).length} harf.');
      return;
    }
    final marks = _score(word, _word(answer.name));
    setState(() {
      _guesses.add(_GuessRow(word, marks));
      _input.clear();
      _error = null;
      _won = word == _word(answer.name);
      _done = _won || _guesses.length == 6;
    });
  }

  void _newRound() {
    if (_players.isEmpty) return;
    setState(() {
      _answer = _players[_random.nextInt(_players.length)];
      _guesses.clear();
      _done = false;
      _won = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answerWord = _answer == null ? '' : _word(_answer!.name);
    final colors = {
      _LetterMark.correct: const Color(0xFF397A49),
      _LetterMark.misplaced: const Color(0xFFB69332),
      _LetterMark.absent: theme.colorScheme.surfaceContainerHighest,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Futbol Wordle')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _answer == null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error ?? 'Dinamik oyuncu paketi bulunamadı.',
                          textAlign: TextAlign.center)))
              : Center(
                  child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    Text('Futbolcunun soyadını altı denemede bul.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium),
                    if (_guesses.length >= 3 &&
                        !_done &&
                        _answer!.firstClub != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                              'İpucu: ${_answer!.firstClub} forması giydi.',
                              textAlign: TextAlign.center)),
                    const SizedBox(height: 14),
                    for (var row = 0; row < 6; row++)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                List.generate(answerWord.length, (column) {
                              final guess =
                                  row < _guesses.length ? _guesses[row] : null;
                              final letter = guess != null
                                  ? guess.word[column]
                                  : row == _guesses.length &&
                                          !_done &&
                                          column < _input.text.length
                                      ? _input.text.toUpperCase()[column]
                                      : '';
                              final color = guess == null
                                  ? theme.colorScheme.surfaceContainerLow
                                  : colors[guess.marks[column]]!;
                              return Container(
                                  width: 42,
                                  height: 46,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: theme
                                              .colorScheme.outlineVariant)),
                                  child: Text(letter,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20)));
                            }),
                          )),
                    if (!_done)
                      TextField(
                          controller: _input,
                          maxLength: answerWord.length,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                              labelText:
                                  '${answerWord.length} harfli soyadı yaz',
                              suffixIcon: IconButton(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.send)),
                              border: const OutlineInputBorder())),
                    if (_error != null)
                      Text(_error!,
                          style: TextStyle(color: theme.colorScheme.error)),
                    if (_done) ...[
                      const SizedBox(height: 12),
                      Text(
                          _won
                              ? 'Doğru! ${_answer!.name}'
                              : 'Cevap: ${_answer!.name}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge),
                      if (_answer!.firstClub != null)
                        Text('Kulüp geçmişi: ${_answer!.firstClub}',
                            textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _newRound,
                          child: const Text('Yeni futbolcu')),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                        'Yeşil doğru harfi doğru yerde, sarı doğru harfi farklı yerde gösterir.',
                        textAlign: TextAlign.center),
                  ]),
                )),
    );
  }
}
