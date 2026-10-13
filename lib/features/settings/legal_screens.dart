import 'package:flutter/material.dart';

import '../../core/services/app_strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GİZLİLİK POLİTİKASI + KULLANIM ŞARTLARI
//
// Google AdMob/AdSense, Firebase (Analytics, Crashlytics, Realtime Database,
// Cloud Messaging), Google Play Games Services ve uygulama içi satın alma
// (in_app_purchase) ile uyumlu, AZ Oyun'un gerçek veri işleme pratiğine göre
// yazılmıştır. Web sürümü (azoyun.web.app/privacy-policy.html ve /terms.html)
// ile aynı içeriği taşır — biri değişirse diğeri de güncellenmelidir.
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
          Text(body, style: const TextStyle(fontSize: 14, height: 1.7)),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

const _lastUpdated = '13 Ekim 2026';

const _privacyText = '''
Son güncelleme: $_lastUpdated

AZ Oyun ("biz", "uygulama") olarak gizliliğinize önem veriyoruz. Bu Gizlilik Politikası, AZ Oyun'u (Android, iOS ve azoyun.web.app web sürümü) kullanırken hangi verilerin toplandığını, nasıl kullanıldığını, kimlerle paylaşıldığını ve haklarınızın ne olduğunu açıklar.

1. TOPLADIĞIMIZ VERİLER

• Oyuncu adı: Kendi seçtiğiniz takma ad; cihazınızda saklanır ve online oyunlarda diğer oyunculara gösterilir. Hesap/e-posta/şifre istemiyoruz, misafir olarak oynanabilir.
• Oyun içi verileri: Online oda oyunlarında oda kodu, hamleler ve skorlar Firebase Realtime Database üzerinde oyun süresince geçici olarak tutulur, oda kapandığında silinir.
• İlerleme verileri: Seviye, XP, coin ve başarımlar cihazınızda yerel olarak (shared_preferences / secure storage) saklanır.
• Teknik ve kullanım verileri: Firebase Analytics ile anonimleştirilmiş kullanım istatistikleri (açılan ekranlar, oynanan oyun türü, oturum süresi) ve Firebase Crashlytics ile çökme/hata raporları (cihaz modeli, işletim sistemi sürümü, hata yığın izi) topluyoruz. Bu veriler uygulamayı iyileştirmek için kullanılır ve kimliğinizi doğrudan belirlemez.
• Reklam verileri: Google AdMob (mobil) ve Google AdSense (web) reklamları göstermek için cihazınızın reklam kimliğini (Advertising ID/GAID, IDFA) ve web'de çerezleri kullanabilir. Bkz. Bölüm 4.
• Bildirim jetonu: Bildirim izni verirseniz Firebase Cloud Messaging cihazınıza özgü bir jeton oluşturur; bu jeton sadece size bildirim göndermek için kullanılır.
• Google Play Games Services / Game Center: Bağlanmayı seçerseniz, Google/Apple hesabınızla ilişkili oyuncu kimliği, liderlik tablosu ve başarım verileri bu servislerle paylaşılır.
• Satın alma verileri: Uygulama içi satın alma (reklam kaldırma, coin paketi, 6 aylık premium, gönüllü bağış) Google Play / App Store üzerinden işlenir. Kredi kartı veya ödeme bilgilerinizi biz görmeyiz, saklamayız; sadece işlemin başarılı olup olmadığı bilgisini alırız.

2. VERİLERİ NASIL KULLANIYORUZ

Verileriniz şu amaçlarla kullanılır: uygulamanın çalışması (oda eşleştirme, ilerleme takibi), hata ayıklama ve performans iyileştirme (Crashlytics/Analytics), bildirim gönderme, reklam gösterimi ve satın alma haklarının teslimi. Verilerinizi satmıyoruz ve pazarlama amacıyla üçüncü taraflara aktarmıyoruz.

3. ÜÇÜNCÜ TARAF HİZMET SAĞLAYICILAR

Uygulama aşağıdaki üçüncü taraf hizmetleri kullanır; her biri kendi gizlilik politikasına tabidir:

• Google Firebase — Analytics, Crashlytics, Realtime Database, Cloud Messaging (privacy.google.com)
• Google AdMob — mobil uygulama içi reklamlar (policies.google.com/technologies/ads)
• Google AdSense — web sürümü (azoyun.web.app) reklamları
• Google Play Games Services / Apple Game Center — liderlik tablosu ve başarımlar
• Google Play Billing / Apple In-App Purchase — uygulama içi satın almaların işlenmesi

4. REKLAMLAR, ÇEREZLER VE KİŞİSELLEŞTİRİLMİŞ REKLAM TERCİHLERİ

Google dahil üçüncü taraf reklam satıcıları, reklam sunmak için çerezler ve mobil reklam kimlikleri kullanır. Google'ın reklam çerezlerini kullanması, Google'ın ve iş ortaklarının kullanıcılara AZ Oyun'daki ve/veya internetteki diğer sitelerdeki önceki ziyaretlerine dayanarak reklam sunmasına olanak tanır.

Kişiselleştirilmiş reklamları devre dışı bırakmak isterseniz:
• Web'de Google Reklam Ayarları (adssettings.google.com) veya www.aboutads.info üzerinden üçüncü taraf satıcı çerezlerini devre dışı bırakabilirsiniz.
• Mobilde cihazınızın işletim sistemi ayarlarından (Android: Ayarlar → Gizlilik → Reklamlar; iOS: Ayarlar → Gizlilik → Reklam) reklam kişiselleştirmesini sınırlayabilir veya reklam kimliğinizi sıfırlayabilirsiniz.
• Reklamsız deneyim için uygulama içinden kalıcı "Reklamları Kaldır" veya "6 Ay Premium" satın alabilirsiniz.

5. ÇOCUKLARIN GİZLİLİĞİ

AZ Oyun genel kitleye yöneliktir ve 13 yaş altı kullanıcılardan bilerek kişisel veri toplamıyoruz. 13 yaşından küçük bir çocuğun bize veri sağladığını fark edersek bu veriyi sileriz. Bir veli/vasi olarak çocuğunuzun bize veri sağladığını düşünüyorsanız Bölüm 9'daki iletişim bilgilerinden bize ulaşın.

6. VERİ GÜVENLİĞİ

Verileriniz Google Firebase altyapısında endüstri standardı güvenlik önlemleriyle (şifreli aktarım, erişim kontrolü) saklanır. Hiçbir sistem %100 güvenli değildir; makul güvenlik önlemleri alsak da mutlak güvenlik garanti edilemez.

7. VERİ SAKLAMA VE SİLME

Yerel verileri (ilerleme, tema, dil tercihi) uygulamayı cihazınızdan silerek kaldırabilirsiniz. Online oda verileri, oda kapandığında veya belirli bir süre işlem görmediğinde sunucudan otomatik silinir. Analytics/Crashlytics verileri Google'ın kendi saklama politikalarına göre periyodik olarak anonimleştirilir veya silinir.

8. HAKLARINIZ (KVKK ve GDPR)

6698 sayılı KVKK ve ilgili olduğu ölçüde GDPR kapsamında; verilerinizin işlenip işlenmediğini öğrenme, işlenmişse bilgi talep etme, düzeltilmesini veya silinmesini isteme ve işlemeye itiraz etme hakkına sahipsiniz. Bu taleplerinizi Bölüm 9'daki iletişim yollarıyla bize iletebilirsiniz; makul bir süre içinde yanıtlarız.

9. İLETİŞİM

Bu Gizlilik Politikası veya kişisel verilerinizle ilgili sorularınız için Google Play / App Store'daki uygulama sayfamızdaki geliştirici iletişim bilgilerini kullanabilir veya azoyun.web.app üzerinden bize ulaşabilirsiniz.

10. DEĞİŞİKLİKLER

Bu politikayı zaman zaman güncelleyebiliriz. Önemli değişiklikler uygulama içinde duyurulur ve bu sayfadaki "Son güncelleme" tarihi yenilenir.
''';

const _termsText = '''
Son güncelleme: $_lastUpdated

Bu Kullanım Şartları ("Şartlar"), AZ Oyun uygulamasını (Android, iOS, azoyun.web.app) kullanırken uymanız gereken kuralları belirler. Uygulamayı indirip kullanarak bu Şartları kabul etmiş olursunuz.

1. HİZMETİN TANIMI

AZ Oyun; Dama, Okey, çok oyunculu sosyal çıkarım oyunları ve tek-cihaz parti oyunları dahil 30'dan fazla oyunu içeren, hesap gerektirmeyen (misafir olarak oynanabilen) ücretsiz bir eğlence uygulamasıdır. Hizmet reklam destekli sunulur; isteğe bağlı uygulama içi satın almalar mevcuttur.

2. UYGUNLUK

Uygulama genel kitleye yöneliktir. 13 yaşından küçükseniz uygulamayı bir ebeveyn/vasi gözetiminde kullanmalısınız.

3. HİZMETİN KULLANIMI

AZ Oyun'u yasalara uygun, saygılı ve adil bir şekilde kullanmayı kabul edersiniz. Aşağıdakiler yasaktır: hile/bot kullanımı, diğer oyuncuları taciz etme, uygunsuz/hakaret içeren kullanıcı adı veya içerik paylaşma, uygulamayı tersine mühendislikle incelemeye çalışma veya sunucu/oda altyapısını kötüye kullanma.

4. HESAP VE İÇERİK

Hesap oluşturmadan (misafir olarak) oynayabilirsiniz; girdiğiniz takma addan ve paylaştığınız içerikten siz sorumlusunuz. Uygunsuz kullanıcı adları veya davranışlar bildirilebilir ve ilgili odadan/oturumdan engellenebilirsiniz.

5. REKLAMLAR

Uygulama Google AdMob (mobil) ve Google AdSense (web) aracılığıyla banner ve geçiş (interstitial) reklamlar gösterir. Reklam içeriği Google ve reklam verenler tarafından belirlenir; reklam içeriğinden veya reklama tıklayarak gittiğiniz üçüncü taraf sitelerden sorumlu değiliz. Reklamsız deneyim satın alarak reklamları kaldırabilirsiniz.

6. UYGULAMA İÇİ SATIN ALMALAR

Reklam kaldırma, coin paketleri, 6 aylık premium ve gönüllü bağış satın almaları tamamen isteğe bağlıdır ve hiçbir oyun içi rekabet avantajı (pay-to-win) sağlamaz — AZ Oyun'un temel ilkesi budur. Satın almalar Google Play / App Store üzerinden işlenir ve ilgili mağazanın iade/fatura politikalarına tabidir; biz ödeme bilgilerinizi tutmayız.

7. FİKRİ MÜLKİYET

Uygulamanın tasarımı, kodu, logosu ve özgün içerikleri (örn. Dedektif Kampanyası hikâyesi) AZ Oyun'a aittir. İzinsiz kopyalama, dağıtma veya ticari amaçla kullanma yasaktır.

8. ÜÇÜNCÜ TARAF HİZMETLER

Uygulama Google Firebase, Google Play Games Services, Apple Game Center ve ilgili mağaza ödeme sistemlerini kullanır; bu hizmetlerin kendi kullanım şartları ayrıca geçerlidir.

9. HİZMETİN DEĞİŞTİRİLMESİ VEYA SONLANDIRILMASI

Hizmeti, özellikleri veya belirli oyunları önceden bildirmeden ekleyebilir, değiştirebilir veya kaldırabiliriz. Kötüye kullanım tespit edilirse bir kullanıcının/oturumun erişimini kısıtlayabiliriz.

10. GARANTİ REDDİ

Uygulama "olduğu gibi" ve "mevcut haliyle" sunulur. Kesintisiz, hatasız veya her cihazla uyumlu çalışacağını garanti etmiyoruz.

11. SORUMLULUĞUN SINIRLANDIRILMASI

Yürürlükteki kanunların izin verdiği azami ölçüde, uygulamanın kullanımından veya kullanılamamasından doğabilecek dolaylı, arızi veya sonuç niteliğindeki zararlardan sorumlu değiliz.

12. GEÇERLİ HUKUK

Bu Şartlar Türkiye Cumhuriyeti kanunlarına tabidir; uyuşmazlıklarda Türkiye mahkemeleri yetkilidir.

13. DEĞİŞİKLİKLER

Bu Şartları zaman zaman güncelleyebiliriz; önemli değişiklikler uygulama içinde duyurulur ve bu sayfadaki "Son güncelleme" tarihi yenilenir. Güncelleme sonrası uygulamayı kullanmaya devam etmeniz yeni Şartları kabul ettiğiniz anlamına gelir.

14. İLETİŞİM

Sorularınız için Google Play / App Store'daki uygulama sayfamızdaki geliştirici iletişim bilgilerini kullanabilir veya azoyun.web.app üzerinden bize ulaşabilirsiniz.
''';
