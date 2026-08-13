import 'package:flutter/material.dart';

import '../../core/services/app_strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GİZLİLİK POLİTİKASI + KULLANIM ŞARTLARI
//
// ⚠️ Bu metinler TASLAKTIR. Yayın öncesi bir hukuk uzmanı tarafından, özellikle
// KVKK/GDPR ve reklam SDK'ları (AdMob, Firebase) ile ilgili veri toplama
// beyanları açısından gözden geçirilmelidir. Şu an sadece Türkçe — çok dilli
// hale getirmek ayrı bir içerik işidir (bkz. ROADMAP 7.5).
// ═══════════════════════════════════════════════════════════════════════════

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalScreen(title: t('privacy_title'), body: _privacyText);
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalScreen(title: t('terms_title'), body: _termsText);
}

class _LegalScreen extends StatelessWidget {
  const _LegalScreen({required this.title, required this.body});

  final String title, body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withAlpha(120)),
            ),
            child: const Text(
              '⚠️ Bu metin bir taslaktır. Yayın öncesi bir hukuk uzmanı tarafından '
              'gözden geçirilmeli, özellikle KVKK/GDPR uyumluluğu açısından.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.7)),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

const _privacyText = '''
AZ Oyun ("biz", "uygulama") olarak gizliliğinize önem veriyoruz. Bu politika, uygulamayı kullanırken hangi verilerin toplandığını ve nasıl kullanıldığını açıklar.

1. TOPLADIĞIMIZ VERİLER

• Oyuncu adı: Kendi seçtiğiniz takma ad, cihazınızda güvenli şekilde saklanır ve online oyunlarda diğer oyunculara gösterilir.
• Oyun verileri: Online oda oyunlarında (oda kodu, hamleler, skorlar) Firebase Realtime Database üzerinde, oyun süresince geçici olarak tutulur.
• İlerleme verileri: Seviye, XP, coin ve başarımlar cihazınızda yerel olarak saklanır.
• Reklam kimliği: Google AdMob, reklam gösterimi için cihazınızın reklam kimliğini (Advertising ID) kullanabilir.
• Bildirim jetonu: Bildirim izni verirseniz, Firebase Cloud Messaging cihazınıza özgü bir jeton oluşturur.
• Google Play Games: Bağlanmayı seçerseniz, Google hesabınızla ilişkili oyuncu kimliği ve liderlik tablosu verileri paylaşılır.

2. VERİLERİ NASIL KULLANIYORUZ

Verileriniz sadece uygulamanın çalışması (oda eşleştirme, ilerleme takibi, bildirimler) ve reklam gösterimi için kullanılır. Verilerinizi satmıyoruz.

3. ÜÇÜNCÜ TARAF HİZMETLER

• Google Firebase (Realtime Database, Cloud Messaging)
• Google AdMob
• Google Play Games Services

Bu hizmetlerin kendi gizlilik politikaları geçerlidir.

4. ÇOCUKLARIN GİZLİLİĞİ

Uygulama genel kitleye yöneliktir. 13 yaş altı kullanıcılardan bilerek kişisel veri toplamıyoruz.

5. VERİ SAKLAMA VE SİLME

Yerel verileri uygulamayı silerek kaldırabilirsiniz. Online oda verileri, oda kapandığında sunucudan silinir.

6. İLETİŞİM

Sorularınız için uygulama mağaza sayfasındaki geliştirici iletişim bilgilerini kullanabilirsiniz.
''';

const _termsText = '''
Bu Kullanım Şartları, AZ Oyun uygulamasını kullanırken uymanız gereken kuralları belirler.

1. HİZMETİN KULLANIMI

AZ Oyun'u yasalara uygun, saygılı ve adil bir şekilde kullanmayı kabul edersiniz. Hile, taciz ve uygunsuz içerik paylaşımı yasaktır.

2. HESAP VE İÇERİK

Oyun içi takma adınızdan ve paylaştığınız içerikten siz sorumlusunuz. Uygunsuz kullanıcı adları/içerikler engellenebilir.

3. UYGULAMA İÇİ SATIN ALMALAR

Bağış ve diğer satın almalar tamamen gönüllüdür, hiçbir oyun içi avantaj sağlamaz ve genellikle iade edilemez (mağaza politikalarına tabidir).

4. GARANTİ REDDİ

Uygulama "olduğu gibi" sunulur. Kesintisiz veya hatasız çalışacağını garanti etmiyoruz.

5. SORUMLULUK SINIRI

Uygulamanın kullanımından doğabilecek dolaylı zararlardan, yasaların izin verdiği ölçüde sorumlu değiliz.

6. DEĞİŞİKLİKLER

Bu şartları zaman zaman güncelleyebiliriz; önemli değişiklikler uygulama içinde duyurulur.

7. İLETİŞİM

Sorularınız için uygulama mağaza sayfasındaki geliştirici iletişim bilgilerini kullanabilirsiniz.
''';
