# AZ Oyun — Yol Haritası

Bu doküman AZ Oyun'u "arkadaşlarla eğlenmek için basit, çok oyunculu oyun
koleksiyonu" vizyonuna göre nasıl büyüteceğimizi anlatır. Hedef: **çok kazanmak
değil, insanları eğlendirmek — az ve dürüst bir gelir modeliyle sürdürülebilir
kalmak.**

## 1. Şu an elimizde ne var?

Proje zaten olgun bir temele sahip:

- **12 online oda-tabanlı oyun** (Firebase Realtime Database, 6 haneli oda
  kodu ile arkadaş davet etme): Mini Golf, Serbest Vuruş (futbol), Araba
  Yarışı, Adam Asmaca, Şehir Bulmaca, Kelime Bulmaca, Okey, Okey 101, Dama,
  Dövüşçüler, Vampir Köylü, Yalancılar Kahvesi, **Hain Kim? (Among Us
  tarzı — görev + gizli hain + toplantı/oylama, telif nedeniyle özgün isim
  ve tema ile)**.
- **18 hızlı (tek cihaz) oyun**: bkz. bölüm 3, 3.1, 3.2 — içlerinde artık
  öykü tabanlı bir polisiye oyun da var (bkz. bölüm 3.3).
- AdMob entegrasyonu (banner + interstitial + rewarded), tutarlı bir tasarım
  dili (`AZTheme`, `AZColors`, `AZGameCard` vb.), güvenli yerel depolama.
- **Eksik olan:** tek cihazda "pas-at-oyna" (hot-seat) basit oyunlar, XP/seviye
  /başarım sistemi, kalıcı liderlik tablosu, Google Play Games Services
  (bulut kayıt, resmi liderlik/başarımlar), uygulama içi satın alma.

Bu yol haritası önce **basit, hızlı, aynı cihazda oynanan oyunlarla** başlıyor
(kurulum yok, oda kodu yok — aç ve oyna), çünkü kullanıcı ilk 30 saniyede
eğlenmeli. Firebase'li "oda" oyunları uzak arkadaşlar için; yeni hızlı oyunlar
ise aynı masadaki arkadaşlar / tek başına oyalanma için.

## 2. Eklenebilecek oyunlar — geniş liste

### A) Klasik strateji / masa oyunları (2 kişi, kolay AI yazılabilir)
1. XOX (Tic-Tac-Toe) ✅ *seçildi*
2. 4'lü Bağlantı (Connect Four) ✅ *seçildi*
3. Reversi / Othello ✅ *seçildi*
4. Nim (taş alma oyunu) ✅ *seçildi*
5. Vur-Kaç (Dama zaten var) — mini satranç varyantı (gelecek)
6. Tavla (Backgammon) — orta vadede, zar + hamle mantığı gerektirir
7. Amazons / Quoridor tarzı basit strateji (ileri seviye)

### B) Parti / sosyal oyunlar (2-6 kişi, aynı cihaz)
8. Taş Kağıt Makas turnuvası ✅ *seçildi*
9. Hafıza Kartları (eşleştirme) ✅ *seçildi*
10. Çizgi Doldurma (Dots and Boxes) ✅ *seçildi*
11. Refleks Çarpışması (en hızlı basan kazanır) ✅ *seçildi*
12. Kim Bilir? (trivia / bilgi yarışması, sırayla soru) ✅ *seçildi (Faz 2)*
13. Sayı Tahmin Düellosu (Bulls & Cows) ✅ *seçildi (Faz 2)*
14. Balon Patlatma Yarışı (dokunma hızı) ✅ *seçildi (Faz 2)*
15. Parti Zarı (basit zar oyunu, set bonuslu) ✅ *seçildi (Faz 2)*

### C) Arcade / tek kişilik (skor tabanlı, sırayla yüksek skor yarışı olarak da oynanır)
16. Yılan (Snake) ✅ *seçildi*
17. 2048 ✅ *seçildi*
18. Flappy tarzı "Zıpla Geç" ✅ *seçildi (Faz 3)*
19. Kayan Yapboz (15-puzzle) ✅ *seçildi (Faz 2)*
20. Renk Eşleştir / Simon Says hafıza dizisi ✅ *seçildi (Faz 3, "Renk Hafızası")*
21. Meyve Kesme tarzı dokunma oyunu — gelecek

### D) 3D / fizik tabanlı (Transform + perspektif ile "pseudo-3D" görünüm)
22. 3D Bowling (mini bovling) ✅ *seçildi (Faz 3, "Mini Bovling" — perspektif Transform ile tilt edilmiş lane, nişan+güç zamanlama mekaniği)*
23. 3D Air Hockey — gelecek
24. Top Toplama / Labirent (tilt/dokunma kontrollü 3D top) — gelecek
25. Basit araba park etme (3D perspektif) — gelecek

## 3.2 Faz 3 — eklenen 3 oyun (tamamlandı ✅)

| # | Oyun | Oyuncu | Tür | Not |
|---|------|--------|-----|-----|
| 16 | Zıpla Geç | 1-6 (sırayla) | Arcade (gerçek zamanlı) | Flappy Bird tarzı, dokun-zıpla, engellerden geç |
| 17 | Renk Hafızası | 1-6 (sırayla) | Arcade (hafıza) | Simon Says — büyüyen renk dizisini tekrarla |
| 18 | Mini Bovling | 1-6 (sırayla) | Arcade / pseudo-3D | `Transform` ile perspektif tilt edilmiş lane; 2 atışlık çerçeve |

Ayrıca bu turda **tasarım yenilendi**: `AZGameCard` basılma animasyonu ve
daha yumuşak gölge/rozet tasarımı aldı; Hızlı Oyunlar sekmesi tek büyük
gride yerine **Strateji / Parti / Arcade & Skor** olmak üzere 3 alt
bölüme ayrıldı, her bölümün kendi renk kimliği var.

> Not: "3D" oyunlar Flutter'da ya `flutter_3d_controller`/`three_dart` gibi
> paketler ya da Flame + basit izometrik çizim ile yapılabilir. İlk fazda
> bunlara girmiyoruz — önce 2D'de temel altyapıyı (XP, başarım, liderlik,
> mağaza) oturtup, sonra 3D'yi bir sonraki fazda ekliyoruz.

## 3. İlk fazda yapılan 10 oyun

Basitlik + çeşitlilik + "arkadaşla oynanabilirlik" dengesine göre seçildi:

| # | Oyun | Oyuncu | AI? | Tür |
|---|------|--------|-----|-----|
| 1 | XOX | 2 | ✅ | Strateji |
| 2 | 4'lü Bağlantı | 2 | ✅ | Strateji |
| 3 | Reversi | 2 | ✅ | Strateji |
| 4 | Taş Kağıt Makas | 2-6 | ✅ | Parti |
| 5 | Hafıza Kartları | 2-6 | — | Parti |
| 6 | Çizgi Doldurma | 2-4 | — | Parti |
| 7 | Nim | 2 | ✅ | Strateji |
| 8 | Yılan | 1-6 (sırayla) | — | Arcade/skor |
| 9 | 2048 | 1-6 (sırayla) | — | Arcade/skor |
| 10 | Refleks Çarpışması | 2-6 | — | Parti |

Hepsi tek cihazda oynanır (oda kodu gerekmez), her maç sonunda kazanana/skora
göre **XP + coin** verilir.

## 3.1 Faz 2 — eklenen 5 oyun (tamamlandı ✅)

| # | Oyun | Oyuncu | Tür | Kazanma kriteri |
|---|------|--------|-----|-----------------|
| 11 | Kim Bilir? (Trivia) | 1-6 (sırayla) | Bilgi yarışması | En yüksek puan (5 soru × 20 puan) |
| 12 | Sayı Tahmin Düellosu | 1-6 (sırayla) | Mantık/Bulls&Cows | En az denemede bulan |
| 13 | Balon Patlatma | 1-6 (sırayla) | Refleks/skor | 20 saniyede en çok balon |
| 14 | Parti Zarı | 1-6 (sırayla) | Zar/şans | En yüksek puan (set bonuslu) |
| 15 | Kayan Yapboz | 1-6 (sırayla) | Bulmaca | En az hamlede çözen |

Bu 5 oyun, tekrar kullanılabilir bir **`TurnBasedChase`** iskeleti üzerine
kuruldu (`lib/core/quickplay/quickplay.dart`) — "cihazı sırayla ver, herkes
bir oturum oynasın, en iyi sonuç kazansın" mantığını tek yerden yönetir.

## 3.3 "Büyük oyun" — Gece Ekspresi Cinayeti (tamamlandı ✅)

Heavy Rain / polisiye iz sürme esintili, tek seferlik ama tekrar oynanabilir
öykü oyunu (`lib/features/mystery/`). Flutter'da gerçek 3D fizik/kamera
motoru olmadığından "3D his" yerine **anlatı derinliğine** yatırım yapıldı:

- Sinematik giriş (3 sahne, ilerleme çubuğu, hafif perspektif `Transform`
  ile tilt edilmiş "dosya kartı" görünümü)
- 🔍 Olay yeri: 6 tıklanabilir kanıt, her biri Not Defteri'ne ekleniyor
- 🗣️ 4 şüpheli, her biri 2 soruluk diyalog; cevaplar kanıtlarla
  çelişebiliyor (dikkatli oyuncu yalanı yakalar)
- ⚖️ Suçlama ekranı → **4 farklı son** (1 doğru + 3 yanlış), gerçek
  katilin tam hikâyesi ve twist'i her sonda açıklanıyor
- Maç sonunda XP/başarım sistemine bağlı (`ProfileService.reportGameResult`)

**Sırada olabilecekler:** bu "vaka motoru" genişletilip 2. bir vaka
eklenebilir; ayrıca kullanıcı Steam'deki *Liars Bar*'a benzer bir
mekanik istedi (kart blöfü + rus ruleti cezası) — mevcut "Yalancılar
Kahvesi" bundan farklı çalışıyor, istenirse ayrı bir oyun olarak
eklenebilir.

## 4. Oyun dışı sistemler (bu fazda kurulan altyapı)

### 4.1 XP / Seviye
- Her maç katılımı: **+5 XP**, galibiyet: **+15 XP ekstra**.
- Seviye formülü: `seviye = (toplamXP / 100).floor() + 1` (basit, öngörülebilir).
- Seviye atlayınca kısa bir kutlama animasyonu + coin bonusu.

### 4.2 Coin (oyun içi para birimi)
- Katılım +2, galibiyet +10 coin.
- Coin'ler **kozmetik mağaza** için (avatar çerçevesi, tahta/kart teması) —
  asla "kazanma gücü" satmıyoruz (pay-to-win yok).

### 4.3 Başarımlar (Achievements)
`lib/core/models/achievement.dart` içinde tanımlı, örnek:
- İlk Adım (ilk maç), Işınlanan (10 maç), Kalpli Kazanan (5 galibiyet),
  Seri Galip (3 üst üste galibiyet), Her Şeyi Dene (10 oyunun hepsini dene),
  Efsane (50 maç).
- Yerelde `AchievementService` ile takip edilir; Google Play Games'e
  bağlandığında otomatik senkronize edilir (bkz. 4.5).

### 4.4 Liderlik tablosu
- Skor tabanlı oyunlar (Yılan, 2048, Refleks) için yerel "en iyi 10" listesi.
- Google Play Games bağlıysa aynı skor resmi bulut liderlik tablosuna da
  gönderilir (yapılandırma sonrası).

### 4.5 Google Play Games Services
- `lib/core/services/play_games_service.dart` — `games_services` paketiyle:
  giriş (sign-in), başarım açma, skor gönderme, **bulut kayıt (saved game)**.
- **Yapılması gereken (Play Console tarafında, kod hazır):**
  1. Play Console'da uygulamayı oluştur, Play Games Services'i etkinleştir.
  2. Liderlik tablosu ve başarım ID'lerini oluştur, `play_games_ids.dart`
     dosyasındaki placeholder'ları gerçek ID'lerle doldur.
  3. `android/app/src/main/res/values/strings.xml` içine
     `app_id` (Play Games) ekle.
- ID'ler girilene kadar servis sessizce no-op çalışır (uygulama çökmez).

### 4.6 Kayıt / Save sistemi
- Yerel: `SharedPreferences` (profil, XP, coin, başarımlar, skor geçmişi).
- Bulut: Play Games "Saved Games" API ile yedekleme (telefon değişince
  ilerleme kaybolmasın) — altyapı hazır, Play Console ID'leri girilince aktif.

### 4.7 Reklamlar (mevcut sistemi genişletiyoruz)
- Zaten var olan `AdService` korunuyor (banner + interstitial + rewarded).
- Hızlı oyunlarda politika: **interstitial sadece her 3-4 maçta bir**,
  oyunun ortasında asla değil (sadece sonuç ekranından çıkarken).
- Rewarded reklam kullanım yerleri: ekstra coin, "tekrar dene" hakkı
  (Snake/2048'de oyunu kaldığı yerden değil ama bonus can gibi küçük iyilikler).
- **Kural:** reklam asla oynanabilirliği bozmamalı, asla zorla izletilmemeli
  (interstitial hariç, o da düşük sıklıkta).

### 4.8 Uygulama içi satın alma (IAP)
`lib/core/services/iap_service.dart` iskeleti hazır. Önerilen ilk ürünler:
- **Reklamsız deneyim** (tek seferlik, ör. ₺29.99) — en çok talep edilen.
- **Coin paketleri** (küçük/orta/büyük) — kozmetik mağaza için.
- **Destek ol / kahve ısmarla** (opsiyonel bağış tarzı ürün) — "az kazan"
  felsefesine en uygunu; zorlamadan gönüllü destek.
- Asla: oyun içi avantaj, ekstra hamle, rakibi zayıflatma gibi pay-to-win
  ürünler **eklenmeyecek**. Bu, "arkadaşlarla adil oyun" vizyonuyla çelişir.

## 5. Öncelik sırası (neden bu sıra?)

1. **Hızlı oyunlar + XP/başarım/liderlik altyapısı** (bu faz) — çünkü
   kullanıcıyı 30 saniyede oyuna sokmak ve "geri gelme" nedeni (XP, seviye,
   başarım) her şeyin temeli. Mevcut 11 oyun zaten var, bunlar eksikti.
2. **Google Play Games Services + Play Console yayın hazırlığı** — resmi
   mağazada olmak, bulut kayıt, kurumsal güven.
3. **Reklam ince ayarı + ilk IAP (reklamsız + coin)** — sürdürülebilir ama
   agresif olmayan gelir.
4. **Faz 2 oyunlar** (B/C listesindeki kalanlar: trivia, bulls&cows, 15-puzzle
   vb.) — mevcut altyapıyı (quickplay kiti) tekrar kullanarak hızlıca eklenir.
5. **Faz 3: 3D oyunlar** — bowling, air hockey gibi — daha fazla geliştirme
   zamanı gerektirir, kullanıcı tabanı büyüdükten sonra mantıklı.

## 6. Gelir modeli felsefesi

"Az kazan, çok eğlendir": agresif reklam sıklığı yok, pay-to-win yok, zorunlu
giriş yok (misafir olarak da oynanabilir). Gelir; gönüllü IAP (reklamsız,
kozmetik, destek ol) ve makul sıklıkta interstitial/rewarded reklamdan gelir.
Amaç viral büyüme (arkadaşını davet et → oda kodu paylaş) ve elde tutma
(XP/seviye/başarım) — reklam geliri bunun doğal sonucu, öncelik değil.

## 7. Endüstriyel altyapı — kalıcı liste (ASLA UNUTMA)

Bu bölüm kullanıcının açıkça istediği, "sanayi/endüstriyel standartta çalışan
uygulama" için gereken tüm alt yapı parçalarının kalıcı kaydıdır. Bir madde
tamamlandığında ✅ işaretlenir ama **satır silinmez** — gelecekteki oturumlar
neyin yapıldığını, neyin hâlâ eksik/manuel adım gerektirdiğini buradan görür.

### 7.1 İlk açılış deneyimi
- [x] Splash ekranı (native Android launch + Flutter tarafı) —
      `lib/features/onboarding/splash_screen.dart`
- [x] 3 sayfalık Onboarding (ilk açılışta bir kez, sonra `SharedPreferences`
      ile bir daha gösterilmez) — `lib/features/onboarding/onboarding_screen.dart`,
      `OnboardingService`
- [x] Onboarding sonunda bildirim izni isteme akışı

### 7.2 Bildirimler
- [x] `NotificationService` — izin isteme (Android 13+ `POST_NOTIFICATIONS`),
      Firebase Cloud Messaging token alma, foreground/background mesaj
      dinleme
- [x] Ayarlar ekranında "Bildirim İzinlerine Git" butonu (sistem ayarlarını
      açar)
- ⚠️ **Kullanıcı tarafında kalan adım:** Gerçek push göndermek için Firebase
  Console → Cloud Messaging'den kampanya/test mesajı gönderilmeli. Kod
  alıcı tarafı hazır (token alınıyor, foreground/background dinleniyor) ama
  "gönderici" (sunucu/console) tarafı bizim elimizde değil.

### 7.3 Deep link
- [x] `DeepLinkService` — `azoyun://` özel şema ile oda daveti gibi
      senaryoları uygulama içinde yönlendirme (`main.dart`'ta ilk link +
      canlı akış dinleniyor, `AndroidManifest.xml`'de intent-filter var)
- ⚠️ **Gelecek iş:** Gerçek `https://azoyun.app/...` tarzı Universal/App
  Links için barındırılan bir domain + `assetlinks.json`/
  `apple-app-site-association` dosyası gerekir — bu bizim elimizde değil,
  domain alındığında eklenir. (Not: Firebase Dynamic Links Ağustos 2025'te
  Google tarafından kapatıldı, kullanılmıyor.) Ayrıca deep link şu an
  sadece bir SnackBar ile bilgi gösteriyor — otomatik oda-doldurma her
  online oyunun lobi ekranını güncellemeyi gerektirir, kapsam dışı bırakıldı.

### 7.4 Tema sistemi
- [x] 3 seçenek: **Sistem** (telefonun temasını takip et), **Açık Tema**
      (marka renklerimiz, mevcut mor gradyan), **Koyu Tema** (yeni,
      koyu marka rengi) — `AZTheme.light` / `AZTheme.dark`
- [x] `ThemeService` ile tercih `SharedPreferences`'ta saklanır, Ayarlar'da
      3 seçenekli kart ile değiştirilir
- Not: Tema sistemi `MaterialApp.themeMode` üzerinden Ayarlar/Profil/Splash/
  Onboarding gibi "chrome" ekranlarını kapsar. 30+ oyun ekranının her biri
  kendi özel gradyan temasıyla çalışmaya devam ediyor (Vampir Köylü'nün
  karanlık teması, Gece Ekspresi'nin noir teması gibi) — bunları da genel
  tema sistemine bağlamak ayrı, büyük bir iştir; şimdilik kapsam dışı.

### 7.5 Dil sistemi
- [x] `LanguageService` — TR/EN arası anlık geçiş, `SharedPreferences`'ta
      saklanır, Ayarlar'da dil seçim ekranı (`LanguageScreen`)
- Not: Flutter'ın resmi `flutter gen-l10n` (ARB tabanlı) sistemi **bilinçli
  olarak kullanılmadı** çünkü bu ortamda Flutter SDK çalıştırılamıyor, kod
  üretimi doğrulanamaz. Bunun yerine elle yazılmış, derleme zamanı kod
  üretimi gerektirmeyen basit bir çeviri haritası (`AppStrings`) kullanıldı.
- ⚠️ **Kapsam:** Bu turda yeni eklenen ekranlar (Ayarlar, Onboarding, dil
  seçimi, yasal metinler) iki dilde de çalışır. 31 oyunun **içindeki** tüm
  metinleri İngilizce'ye çevirmek ayrı, büyük bir içerik işidir — istenirse
  oyun oyun ilerlenir. Yeni bir dil eklemek `AppLanguage`'e bir değer ve
  `AppStrings`'e yeni bir `Map` eklemek kadar basit.

### 7.6 Google Play Games
- [x] Uygulama açılışında otomatik (sessiz) giriş denemesi — `main.dart`
      `runApp()` sonrası `PlayGamesService.instance.signIn()` çağrılıyor;
      önceden sadece Profil/Ayarlar ekranında manuel "BAĞLAN" butonu vardı,
      o da hâlâ duruyor (otomatik giriş başarısız olursa manuel bağlanılabilir)
- ⚠️ **Kullanıcı tarafında kalan adım:** Play Console'da liderlik
  tablosu/başarım ID'lerini oluşturup `play_games_service.dart`'taki
  placeholder'lara yapıştırman gerekiyor (bkz. bölüm 4.5).

### 7.7 Ayarlar ekranı (yeni, hepsini birleştiren merkez)
- [x] Tema seçici, dil seçici, bildirim izni butonu, Play Games durumu —
      `lib/features/settings/settings_screen.dart`, ana ekranda sağ üst
      dişli ikonundan açılıyor
- [x] Gizlilik Politikası (uygulama içi metin ekranı — barındırılan URL yok)
- [x] Kullanım Şartları (uygulama içi metin ekranı)
- [x] Bağış butonu → IAP ürünü **`donation_small`**
- [x] Uygulamayı paylaş (`share_plus`)
- [x] Uygulamayı değerlendir / App Review (`in_app_review`)
- ⚠️ **Kullanıcı tarafında kalan adım:** Gizlilik Politikası/Kullanım
  Şartları metinleri taslak olarak yazıldı (`legal_screens.dart` içinde
  ekranda da amber uyarı bandı var) ama **gerçek yayın öncesi bir
  avukat/uzman tarafından gözden geçirilmeli** — özellikle KVKK/GDPR ve
  reklam SDK'ları (AdMob, Firebase) ile ilgili veri toplama beyanları için.
  `donation_small` ürününün Play Console'da (tüketilebilir olarak)
  oluşturulması gerekiyor (bkz. bölüm 4.8).

### 7.8 Firebase (genel güçlendirme)
- [x] Cloud Messaging entegrasyonu (bkz. 7.2)
- [ ] Analytics (opsiyonel, gelecek — kullanıcı davranışını anlamak için)
- [ ] Crashlytics (opsiyonel, gelecek — `firebaseCrashlytics` bloğu
      `build.gradle.kts`'de zaten yorum satırı olarak duruyor, aktif değil)

### 7.9 Android manifest / platform ayarları
- [x] Deep link için `intent-filter` (custom scheme `azoyun://`)
- [x] `POST_NOTIFICATIONS` izni (Android 13+)
- [x] FCM meta-data (varsayılan bildirim ikonu/kanalı)

## 8. İkinci endüstriyel tur — kalıcı liste (ASLA UNUTMA)

Bölüm 7 ile aynı kural geçerli: bir madde tamamlandığında ✅ işaretlenir ama
satır silinmez. Bu bölüm, kullanıcının 13 Ağustos 2026 turunda istediği,
"artık gerçek bir oyun mağazası ürünü gibi olsun" kapsamındaki işlerin kaydı.

### 8.1 Dedektif oyunu → çok vakalı kampanya
- [ ] "Gece Ekspresi Cinayeti" tek vakadan, birbirine bağlı **10 vaka + 1
      final bonus vaka** zincirine genişletilecek
- [ ] Final vakada şok twist: oyuncunun çözdüğü tüm vakalar aslında
      perde arkasındaki tek bir kişinin (büyük kötü) uzun vadeli planının
      parçalarıymış; o kişi herkesi kullanmış/kandırmış ve planını
      tamamlayarak büyük bir güç/kontrol elde etmiş olacak
- [ ] Final, ana karakterin şaşkınlığıyla ve akıbeti belirsiz bırakılarak
      biter (klasik "to be continued" hissi) — aksiyonlu, nefes nefese temp
- Not: 10 vakanın hepsini ilk vaka (Gece Ekspresi) kadar uzun/detaylı
  yazmak tek oturumda bitecek bir iş değil — kampanya **iskeleti**
  (vaka zinciri state'i, ilerleme kaydı, XP artışı) ve **birden fazla yeni
  vaka + final** bu turda eklenecek, kalanlar sıradaki turlarda tamamlanacak.

### 8.2 Reklam & Premium
- [x] Interstitial sıklığı: her oyun sonunda değil, **5 oyunda 1** (önceden
      3'tü) — kullanıcıyı boğmadan gelir üretmeye devam
- [x] Banner reklamlar korunuyor (mevcut `AdaptiveBannerAdWidget`)
- [x] Yeni IAP ürünü: **Premium — 6 Ay Reklamsız** (`premium_6m_noads`,
      ~50 TL), non-consumable; satın alınınca `StorageService.extendPremium`
      bitiş tarihini `flutter_secure_storage`'a yazar (zaten aktifse
      üzerine ekler), `AdService.disableAds()` anında çağrılır, uygulama
      her açılışta `applyPremiumStateIfActive()` ile süresi dolmamışsa
      reklamları kapalı başlatır
- [x] Ayarlar ekranına "Premium — 6 Ay Reklamsız" butonu (aktifken kalan
      gün sayısını gösterir)
- Not: Tek bir `AdService._adsEnabled` bayrağı kullanıldığı için premium
  aktifken ödüllü (rewarded) reklamlar da kapanır — "reklamsız" özelliği
  basit ve tutarlı tutmak için bilinçli bir tercih.
- ⚠️ **Kullanıcı tarafında kalan adım:** Yeni IAP ürününün Play
  Console'da `premium_6m_noads` ID'siyle non-consumable olarak
  oluşturulması gerekiyor.

### 8.3 Google Play Console — pre-launch report uyarıları
Play Console'un "3 işlem öneriliyor" uyarısı, sürüm 5 (1.0.0) için:
- [x] **R8/kaynak küçültme:** `isShrinkResources = true` zaten
      `build.gradle.kts`'de aktif (önceki turda eklendi) — bu uyarı eski
      bir build'e ait, bir sonraki yüklemede kendiliğinden düzelecek
- ⚠️ **AGP 9.0+ yükseltmesi:** Şu an `com.android.application` 8.11.1.
      Bu ortamda gerçek bir Flutter/Gradle derlemesi çalıştırılamadığından
      (Flutter SDK yok), AGP sürümünü körlemesine yükseltmek NDK
      versiyonunda daha önce yaşanan build kırılmasına benzer bir riske
      yol açabilir. **Kullanıcı tarafında kalan adım:** Android Studio'yu
      güncelleyip AGP'yi kademeli yükselt, `flutter build appbundle` ile
      yerel olarak doğrula.
- [x] **Bit eşlem (Bitmap) alt örnekleme uyarısı — kök neden bulundu ve
      düzeltildi:** `assets/images/` klasöründe **hiçbir Dart dosyasından
      referans verilmeyen** 3 unutulmuş görsel duruyordu —
      `enemy_car.png` (1024×1024, ~1 MB), `road_texture.png`
      (1024×1024, ~1.6 MB), `player_car.gif` (~925 KB). Araba Yarışı
      oyunu emoji tabanlı sprite'lara geçtiğinden beri bunlar tamamen
      ölü ağırlıktı ama `pubspec.yaml` hâlâ `assets/images/` klasörünü
      bütün olarak bundle'a dahil ediyordu. Silindi, `pubspec.yaml`'dan
      `assets/images/` satırı kaldırıldı. Play Console'un işaret ettiği
      obfuscate sınıflar (`D.b.c`, `F1.x.c`) hâlâ bir SDK'nın iç kodu
      olabilir ama bu APK'yı gereksiz yere büyüten, kullanılmayan
      yüksek-çözünürlüklü görselleri ortadan kaldırmak zaten doğru adımdı.
      **Kullanıcı tarafında kalan adım:** Bir sonraki build'i Play
      Console'a yükleyip uyarının düşüp düşmediğini kontrol et; hâlâ
      görünüyorsa ProGuard/R8 mapping dosyasını
      (`build/app/outputs/mapping/release/mapping.txt`) yükleyip hangi
      SDK olduğunu netleştir.
- [x] **Uçtan uca (edge-to-edge) ekran uyarısı:** Ekranlarımız zaten
      `SafeArea` kullanıyor; asıl neden Android 15 hedefleyen uygulamalarda
      edge-to-edge'in zorunlu hale gelmesi. `MainActivity` standart
      `FlutterActivity`'yi kullanıyor ve Flutter, güncel embedding'de
      edge-to-edge'i otomatik destekliyor — ekstra native kod gerekmedi.
      Play Console uyarısı da eski build'e ait, bir sonraki yüklemede
      düşmesi bekleniyor.

### 8.4 Firebase oda temizliği (hayalet oda önleme)
- [ ] `RoomService`'e `onDisconnect()` tabanlı temizlik eklenecek: bir
      oyuncu/host bağlantısı **crash/ağ kopması gibi kontrolsüz** bir
      şekilde koparsa (uygulamadan düzgün "çık" ile değil), oda Firebase'de
      sonsuza kadar kalmasın
- Not: "Host çıkarsa" / "oyun bitince silinsin" senaryosu zaten TÜM 12
  online oyunda çalışıyordu (`_leave()` + boş oda kontrolü) — eksik olan
  sadece **anormal/kontrolsüz kopma** durumuydu, `onDisconnect()` ile
  kapatılıyor.

### 8.5 Oyun içi hata taraması
- [x] Araba Yarışı: araba sprite'ları fizik yönüne göre hep **ters**
      duruyordu (emoji varsayılan olarak sola bakar, hareket matematiği
      açı 0'ı "sağa" kabul eder) — `+pi` düzeltmesiyle çözüldü
- [ ] Diğer oyunlarda (özellikle Dövüşçüler, Dama, Okey) benzer görsel/
      mantık hataları için tarama devam ediyor

### 8.6 Google Play Games Services v2
- [ ] `developer.android.com/games/pgs/android/android-start` rehberine
      göre kurulumun güncel olup olmadığı gözden geçirilecek
- Not: Şu an `games_services` Flutter paketi kullanılıyor (bkz. bölüm 4.5,
  7.6) — Google'ın native "Play Games Services v2" SDK'sına (Kotlin/Java
  tarafında doğrudan `com.google.android.gms:play-services-games-v2`)
  geçmek, paketi tamamen değiştirmek anlamına gelir; bu büyük bir karar,
  önce mevcut paketin v2 ile uyumlu olup olmadığı doğrulanacak.

### 8.7 Tüm oyunları "çocuksu 2D"den "3D/eğlenceli" hale getirme
- [ ] Kullanıcı geri bildirimi: mevcut UI'lar güzel ama oyunların çoğu
      (özellikle strateji/parti oyunları) düz 2D ve "çocuksu" hissettiriyor;
      Araba Yarışı ve Dövüşçüler'deki gibi daha "3D hissi veren" bir
      görsel dile geçilmesi isteniyor
- Not: Bu, **30+ oyunun tamamını** kapsayan çok büyük bir görsel yenileme
  girişimi — tek oturumda bitmez. Öncelik sırası önerisi: (1) en çok
  oynanacak/öne çıkan oyunlar (XOX, Vampir Köylü, Yalancılar Kahvesi), (2)
  arcade oyunları (zaten kısmen pseudo-3D olan Mini Bovling'e benzer
  gradient/gölge/perspektif teknikleri diğer arcade oyunlara uygulanabilir),
  (3) masa oyunları (Dama, Okey). İstenirse oyun oyun ilerlenir.
