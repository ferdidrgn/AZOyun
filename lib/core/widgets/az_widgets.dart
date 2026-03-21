import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/az_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LAYOUT
// ═══════════════════════════════════════════════════════════════════════════

class AZGradientScaffold extends StatelessWidget {
  const AZGradientScaffold({
    super.key,
    required this.gradient,
    required this.child,
    this.resizeToAvoidBottomInset = true,
  });

  final Gradient gradient;
  final Widget   child;
  final bool     resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    body: Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(child: child),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CARDS
// ═══════════════════════════════════════════════════════════════════════════

class AZCard extends StatelessWidget {
  const AZCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget     child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AZRadius.xl),
      boxShadow: const [
        BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 6))
      ],
    ),
    child: child,
  );
}

class AZFrostCard extends StatelessWidget {
  const AZFrostCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.opacity = 0.15,
  });

  final Widget     child;
  final EdgeInsets padding;
  final double     opacity;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(AZRadius.lg),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
    ),
    child: child,
  );
}

class AZGameCard extends StatelessWidget {
  const AZGameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  final String      title, subtitle, emoji;
  final Gradient    gradient;
  final VoidCallback onTap;
  final String?     badge;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AZRadius.xl),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AZRadius.xl),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AZRadius.lg),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(badge!,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 20),
          ]),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// BUTTONS
// ═══════════════════════════════════════════════════════════════════════════

class AZButton extends StatelessWidget {
  const AZButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AZColors.purple,
    this.loading = false,
    this.width = double.infinity,
    this.height = 56,
  });

  final String        label;
  final VoidCallback? onPressed;
  final IconData?     icon;
  final Color         color;
  final bool          loading;
  final double        width, height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width, height: height,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AZRadius.lg)),
      ),
      child: loading
          ? SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: color, strokeWidth: 2.5))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
              Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
    ),
  );
}

class AZJoinButton extends StatelessWidget {
  const AZJoinButton({super.key, required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool          loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.login),
      label: const Text('ODAYA KATIL',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AZColors.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AZRadius.md)),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOM CODE
// ═══════════════════════════════════════════════════════════════════════════

class AZRoomCode extends StatelessWidget {
  const AZRoomCode({super.key, required this.code, required this.accentColor});

  final String code;
  final Color  accentColor;

  @override
  Widget build(BuildContext context) => AZCard(
    child: Column(children: [
      Text('ODA KODU',
          style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.grey.shade500)),
      const SizedBox(height: 6),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(code,
            style: TextStyle(
                fontSize: 38, fontWeight: FontWeight.bold,
                letterSpacing: 10, color: accentColor)),
        IconButton(
          icon: Icon(Icons.copy_rounded, color: accentColor),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Kod kopyalandı!')));
          },
        ),
      ]),
      Text('Arkadaşına gönder',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PLAYER TILE
// ═══════════════════════════════════════════════════════════════════════════

class AZPlayerTile extends StatelessWidget {
  const AZPlayerTile({
    super.key,
    required this.name,
    required this.isMe,
    required this.isHost,
    this.emoji = '👤',
    this.present = true,
  });

  final String name;
  final bool   isMe, isHost, present;
  final String emoji;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: isMe
          ? Colors.white.withOpacity(0.28)
          : Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(AZRadius.md),
      border: isMe ? Border.all(color: Colors.white, width: 1.5) : null,
    ),
    child: Row(children: [
      Text(present ? emoji : '○', style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          present ? name : 'Bekleniyor...',
          style: TextStyle(
              color: present ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      if (isHost) _Badge(label: 'HOST', bg: Colors.yellow, fg: Colors.brown),
      if (isMe)   _Badge(label: 'SEN',  bg: Colors.white24, fg: Colors.white),
    ]),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color  bg, fg;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// NAME DIALOG
// ═══════════════════════════════════════════════════════════════════════════

Future<String?> showNameDialog(
  BuildContext context, {
  String?  current,
  Color    accentColor = AZColors.purple,
}) async {
  final ctrl = TextEditingController(text: current ?? '');
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('👤 Adınız'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 14,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Oyun içi adınız'),
        onSubmitted: (v) {
          final n = v.trim();
          if (n.isNotEmpty) Navigator.pop(context, n);
        },
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accentColor),
          onPressed: () {
            final n = ctrl.text.trim();
            if (n.isNotEmpty) Navigator.pop(context, n);
          },
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CODE FIELD
// ═══════════════════════════════════════════════════════════════════════════

class AZCodeField extends StatelessWidget {
  const AZCodeField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textCapitalization: TextCapitalization.characters,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]'))],
    maxLength: 6,
    textAlign: TextAlign.center,
    style: const TextStyle(
        fontSize: 28, fontWeight: FontWeight.bold,
        letterSpacing: 8, color: Colors.white),
    decoration: InputDecoration(
      counterText: '',
      hintText: 'ODA KODU',
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AZRadius.md),
          borderSide: BorderSide.none),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// WAITING CARD
// ═══════════════════════════════════════════════════════════════════════════

class AZWaitingCard extends StatelessWidget {
  const AZWaitingCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => AZFrostCard(
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
      const SizedBox(width: 14),
      Text(message, style: const TextStyle(color: Colors.white, fontSize: 15)),
    ]),
  );
}
