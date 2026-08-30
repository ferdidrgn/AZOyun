import 'package:flutter/material.dart';

import '../../../core/theme/dashboard_tokens.dart';
import 'bento_card.dart';

/// Google Play Games Services bağlantı durumunu gösteren, tıklanabilir
/// bir CTA banner'ı.
class PlayGamesBanner extends StatelessWidget {
  const PlayGamesBanner({
    super.key,
    required this.connected,
    required this.connecting,
    required this.onConnect,
  });

  final bool connected, connecting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => BentoCard(
        onTap: connected ? null : (connecting ? null : onConnect),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (connected ? DashTokens.emerald : DashTokens.accent(context)).withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              connected ? Icons.cloud_done_rounded : Icons.videogame_asset_rounded,
              color: connected ? DashTokens.emeraldSoft : DashTokens.accentSoft(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Google Play Games\'e bağlı' : 'Google Play Games\'e bağlan',
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: DashTokens.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? 'İlerlemen bulutta yedekleniyor'
                      : 'İlerlemeni buluta yedekle, liderlik tablosuna gir',
                  style: DashTokens.labelSm,
                ),
              ],
            ),
          ),
          if (connecting)
            SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: DashTokens.accentSoft(context)))
          else if (!connected)
            Icon(Icons.chevron_right_rounded, color: DashTokens.textTertiary),
        ]),
      );
}
