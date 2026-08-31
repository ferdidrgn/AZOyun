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
      color: AZColors.surface,
      borderRadius: BorderRadius.circular(AZRadius.xl),
      boxShadow: AZShadow.soft(AZShadow.lightTint),
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
      color: Color.fromRGBO(255, 255, 255, opacity),
      borderRadius: BorderRadius.circular(AZRadius.lg),
      border: Border.all(color: const Color(0x40FFFFFF)),
    ),
    child: child,
  );
}

class AZGameCard extends StatefulWidget {
  const AZGameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  final String       title, subtitle, emoji;
  final Gradient     gradient;
  final VoidCallback onTap;
  final String?      badge;

  @override
  State<AZGameCard> createState() => _AZGameCardState();
}

class _AZGameCardState extends State<AZGameCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.gradient is LinearGradient
        ? (widget.gradient as LinearGradient).colors.first
        : AZColors.purple;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(AZRadius.xl),
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(_pressed ? 60 : 100),
                blurRadius: _pressed ? 10 : 20,
                offset: Offset(0, _pressed ? 4 : 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(AZRadius.lg),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                ),
                child: Center(
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(widget.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(widget.badge!,
                                style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                    letterSpacing: 0.3)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 5),
                      Text(widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0xD9FFFFFF), height: 1.3)),
                    ]),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: Color(0x26FFFFFF), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
              ),
            ]),
          ),
        ),
      ),
    );
  }
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
    width: width,
    height: height,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AZRadius.lg)),
      ),
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: color, strokeWidth: 2.5))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10)
              ],
              Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
    ),
  );
}

class AZJoinButton extends StatelessWidget {
  const AZJoinButton(
      {super.key, required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool          loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.login),
      label: const Text('ODAYA KATIL',
          style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
// ROOM HEADER — oda/lobi ekranlarının en üstündeki "[X]  BAŞLIK" satırı.
// 12 lobi ekranında birebir aynı `Row`'du: solda kapat düğmesi, ortada
// `Expanded` içinde ortalanmış başlık, sağda düğmeyi dengeleyen 48'lik boşluk.
// ═══════════════════════════════════════════════════════════════════════════

class AZRoomHeader extends StatelessWidget {
  const AZRoomHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.titleSize  = 18,
    this.closeColor = Colors.white,
  });

  final String       title;
  final VoidCallback onClose;

  /// Yalnızca uzun başlıklar için küçültülür (Yalancılar Kahvesi: 17).
  final double titleSize;

  /// Yalnızca koyu temalı Dövüşçüler ekranı bunu `Colors.white54` yapıyor.
  final Color closeColor;

  @override
  Widget build(BuildContext context) => Row(children: [
    IconButton(icon: Icon(Icons.close, color: closeColor), onPressed: onClose),
    Expanded(
      child: Text(title,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.bold)),
    ),
    const SizedBox(width: 48),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOM CODE
// ═══════════════════════════════════════════════════════════════════════════

class AZRoomCode extends StatelessWidget {
  const AZRoomCode(
      {super.key, required this.code, required this.accentColor});

  final String code;
  final Color  accentColor;

  @override
  Widget build(BuildContext context) => AZCard(
    child: Column(children: [
      Text('ODA KODU',
          style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: Colors.grey.shade500)),
      const SizedBox(height: 6),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(code,
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
                color: accentColor)),
        IconButton(
          icon: Icon(Icons.copy_rounded, color: accentColor),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kod kopyalandı!')));
          },
        ),
      ]),
      Text('Arkadaşına gönder',
          style:
              TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
    padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: isMe
          ? const Color(0x47FFFFFF)
          : const Color(0x1AFFFFFF),
      borderRadius: BorderRadius.circular(AZRadius.md),
      border: isMe
          ? Border.all(color: Colors.white, width: 1.5)
          : null,
    ),
    child: Row(children: [
      Text(present ? emoji : '○',
          style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          present ? name : 'Bekleniyor...',
          style: TextStyle(
              color: present ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w600,
              fontSize: 15),
        ),
      ),
      if (isHost)
        _Badge(
            label: 'HOST',
            bg: AZColors.accentGoldSoft,
            fg: AZColors.textPrimary),
      if (isMe)
        _Badge(
            label: 'SEN',
            bg: Colors.white24,
            fg: Colors.white),
    ]),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.label, required this.bg, required this.fg});

  final String label;
  final Color  bg, fg;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: fg)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// NAME CHIP — lobi ekranlarında "👤 Adın ✎" rozeti; dokununca
// [showNameDialog] açılır. Altı lobide (Adam Asmaca, Mini Golf, Serbest
// Vuruş, Şehir Bulmaca, Kelime Bulmaca, Yalancılar Kahvesi) birebir aynıydı.
//
// NOT: Diğer altı lobide (Okey, Dama, Araba Yarışı, Dövüşçüler, Hain Kim?,
// Vampir Köylü) bu rozet bilerek DEĞİŞTİRİLMEDİ — oralarda ölçüler farklı
// (daha küçük dolgu/yazı) ya da kalem ikonu hiç yok. Hepsini tek bir
// parametreli widget'a zorlamak görsel değişiklik riski taşırdı.
// ═══════════════════════════════════════════════════════════════════════════

class AZNameChip extends StatelessWidget {
  const AZNameChip({super.key, required this.name, required this.onTap});

  /// `null` ise 'Ad seç' yazar.
  final String?      name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AZFrostCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.person_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(name ?? 'Ad seç',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        const Icon(Icons.edit_rounded, color: Colors.white60, size: 14),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// NAME DIALOG
// ═══════════════════════════════════════════════════════════════════════════

Future<String?> showNameDialog(
  BuildContext context, {
  String? current,
  Color   accentColor = AZColors.purple,
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
        decoration:
            const InputDecoration(hintText: 'Oyun içi adınız'),
        onSubmitted: (v) {
          final n = v.trim();
          if (n.isNotEmpty) Navigator.pop(context, n);
        },
      ),
      actions: [
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: accentColor),
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
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]'))
    ],
    maxLength: 6,
    textAlign: TextAlign.center,
    style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 8,
        color: Colors.white),
    decoration: InputDecoration(
      counterText: '',
      hintText: 'ODA KODU',
      hintStyle:
          const TextStyle(color: Color(0x61FFFFFF), fontSize: 16),
      filled: true,
      fillColor: const Color(0x1FFFFFFF),
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
    child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5)),
          const SizedBox(width: 14),
          Text(message,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15)),
        ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROL AÇILIŞ KARTI — sosyal-tahmin oyunları (Hain Kim?, Vampir Köylü,
// Yalancılar Kahvesi) için ortak, 3D hissi veren dramatik rol açıklama
// ekranı. Düz bir showDialog yerine hafif bir "kart açılıyor" animasyonu
// (perspektif döndürme + geri sekmeli ölçek) kullanır.
// ═══════════════════════════════════════════════════════════════════════════

Future<void> showRoleRevealCard(
  BuildContext context, {
  required String emoji,
  required String title,
  required String description,
  required Color color,
  String confirmLabel = 'Anladım',
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 550),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) {
      final t = Curves.easeOutBack.transform(animation.value.clamp(0.0, 1.0));
      final fade = Curves.easeOut.transform(animation.value.clamp(0.0, 1.0));
      return Opacity(
        opacity: fade,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0018)
            ..rotateX((1 - t) * 0.7)
            ..scale(0.65 + 0.35 * t),
          child: Center(
            child: _RoleRevealContent(
              emoji: emoji,
              title: title,
              description: description,
              color: color,
              confirmLabel: confirmLabel,
            ),
          ),
        ),
      );
    },
  );
}

class _RoleRevealContent extends StatelessWidget {
  const _RoleRevealContent({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.confirmLabel,
  });

  final String emoji, title, description, confirmLabel;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 30),
    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, Color.lerp(color, Colors.black, 0.4)!],
      ),
      borderRadius: BorderRadius.circular(AZRadius.xxl),
      border: Border.all(color: const Color(0x33FFFFFF), width: 1.4),
      boxShadow: [
        BoxShadow(color: color.withAlpha(140), blurRadius: 42, spreadRadius: 2),
        const BoxShadow(color: Colors.black54, blurRadius: 26, offset: Offset(0, 18)),
      ],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 92,
        height: 92,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0x26FFFFFF), shape: BoxShape.circle),
        child: Text(emoji, style: const TextStyle(fontSize: 48)),
      ),
      const SizedBox(height: 20),
      Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 21, letterSpacing: 0.5)),
      const SizedBox(height: 14),
      Text(description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
      const SizedBox(height: 26),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AZRadius.lg)),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SNACKBAR — her online oyun ekranında ayrı ayrı tanımlanan `_snack()`
// yardımcı metodunun (29 kopyası vardı) ortak, tek noktadan hali.
// ═══════════════════════════════════════════════════════════════════════════

extension AZSnack on BuildContext {
  /// Varsayılan süre, `SnackBar`'ın kendi varsayılanıyla (4 saniye) aynı —
  /// mevcut çağrı yerlerinin çoğu süre belirtmiyordu, davranış değişmiyor.
  void snack(String message, {Duration duration = const Duration(milliseconds: 4000)}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ODADAN / OYUNDAN ÇIKIŞ — her online oyun ekranında ayrı ayrı yazılan geri
// tuşu koruması ve "çıkmak istediğine emin misin?" penceresinin ortak hali.
// ═══════════════════════════════════════════════════════════════════════════

/// Geri tuşunu (ve iOS kaydırma jestini) yakalayıp otomatik `pop` yerine
/// oyunun kendi çıkış akışını çalıştıran sarmalayıcı.
///
/// Her online oyun/oda ekranı Scaffold'unu `PopScope(canPop: false,
/// onPopInvoked: (_) => _leave())` ile sarıyordu — 20 kopya. Sarmalayıcının
/// tek nüshaya inmesinin asıl faydası: `onPopInvoked` ileride Flutter
/// tarafından `onPopInvokedWithResult` ile değiştirildiğinde 20 dosya değil
/// sadece burası güncellenecek.
///
/// [onLeave] `Future<void> Function()` de olabilir (`void` Dart'ta üst tip);
/// mevcut çağrı yerlerinin hepsi zaten `async` bir `_leave()` veriyordu ve
/// dönüş değeri hiçbir zaman beklenmiyordu — davranış birebir aynı.
class AZLeaveGuard extends StatelessWidget {
  const AZLeaveGuard({super.key, required this.onLeave, required this.child});

  final VoidCallback onLeave;
  final Widget       child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvoked: (_) => onLeave(),
    child: child,
  );
}

/// Aktif oyunun ortasında çıkışı onaylatan pencere.
///
/// 8 aktif oyun ekranındaki `_confirmLeave()` metotlarının AlertDialog'u
/// birebir aynıydı; sadece başlık ve gövde cümlesi oyundan oyuna değişiyordu.
/// Butonlar ('Vazgeç' / kırmızı 'Çık') bilerek parametre değil — sekiz ekranın
/// hepsinde aynıydı.
///
/// Dönüş: kullanıcı 'Çık' dediyse `true`. Pencere dışına dokunup kapatmak
/// (`null`) de 'Vazgeç' sayılır — eski çağrı yerlerindeki `if (ok == true)`
/// kontrolüyle aynı sonuç.
///
/// [confirmColor] varsayılanı [AZColors.redDk]; sadece kendi kırmızı
/// sabiti olan ekranlar (Adam Asmaca) bunu geçiyor.
Future<bool> confirmLeaveGame(
  BuildContext context, {
  required String title,
  required String message,
  Color?          confirmColor,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor ?? AZColors.redDk),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çık')),
      ],
    ),
  );
  return ok == true;
}
