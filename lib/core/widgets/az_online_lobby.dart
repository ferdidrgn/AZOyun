import 'package:flutter/material.dart';

import 'az_widgets.dart';

class AZOnlineLobby extends StatelessWidget {
  const AZOnlineLobby({
    super.key,
    required this.title,
    required this.icon,
    required this.summary,
    required this.instructions,
    required this.playerName,
    required this.codeController,
    required this.loading,
    required this.onRename,
    required this.onCreate,
    required this.onJoin,
    this.setupOptions,
  });

  final String title, summary, instructions;
  final IconData icon;
  final String? playerName;
  final TextEditingController codeController;
  final bool loading;
  final VoidCallback onRename, onCreate, onJoin;
  final Widget? setupOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(icon,
                                size: 30,
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(summary, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(instructions),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (setupOptions != null) ...[
                  setupOptions!,
                  const SizedBox(height: 16),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(playerName ?? 'Oyuncu adını seç'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: loading ? null : onRename,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: loading ? null : onCreate,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Oda oluştur'),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  enabled: !loading,
                  decoration: const InputDecoration(labelText: 'Oda kodu'),
                  onSubmitted: (_) {
                    if (!loading) onJoin();
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: loading ? null : onJoin,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Odaya katıl'),
                ),
                if (loading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AZOnlineWaitingRoom extends StatelessWidget {
  const AZOnlineWaitingRoom({
    super.key,
    required this.title,
    required this.game,
    required this.code,
    required this.capacity,
    required this.players,
    required this.myKey,
    required this.isHost,
    required this.canStart,
    required this.starting,
    required this.onStart,
    required this.onLeave,
  });

  final String title, game, code, myKey;
  final int capacity;
  final Map<dynamic, dynamic> players;
  final bool isHost, canStart, starting;
  final VoidCallback onStart, onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AZLeaveGuard(
      onLeave: onLeave,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: onLeave),
          title: Text(title),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AZRoomCode(
                    code: code,
                    accentColor: theme.colorScheme.primary,
                    inviteGame: game,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Oyuncular (${players.length}/$capacity)',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          for (var index = 1; index <= capacity; index++)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(players.containsKey('p$index')
                                  ? Icons.person_rounded
                                  : Icons.person_outline_rounded),
                              title: Text(
                                  players['p$index']?['name'] as String? ??
                                      'Boş koltuk'),
                              trailing: 'p$index' == myKey
                                  ? const Text('Sen')
                                  : players['p$index']?['isHost'] == true
                                      ? const Text('Oda sahibi')
                                      : null,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isHost)
                    FilledButton.icon(
                      onPressed: canStart && !starting ? onStart : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(starting ? 'Başlatılıyor…' : 'Maçı başlat'),
                    ),
                  if (!canStart || !isHost)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        !canStart
                            ? 'Maç için en az iki oyuncu gerekli.'
                            : 'Oda sahibinin maçı başlatması bekleniyor.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
