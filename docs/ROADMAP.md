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

### 4.5 Google Play Games Services — kuruldu ve aktif
- `lib/core/services/play_games_service.dart` — `games_services` paketiyle:
  giriş (sign-in), başarım açma, skor gönderme.
- Play Console tarafı tamamlandı: proje kimliği `517819561284`
  `res/values/strings.xml`'e girildi, 1 liderlik tablosu ("Skorboard")
  ve 1 başarım ("İlk") oluşturulup ID'leri kodda eşlendi (ayrıntı: 7.6).
- Oyuna özel yeni liderlik tablosu/başarım eklemek istersen: Play
  Console'da oluştur → ID'yi `play_games_service.dart`'taki
  `_leaderboardIds`/`_achievementIds` haritalarına ekle. ID'ler
  boş/eksikse servis sessizce no-op çalışır (uygulama çökmez).

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
- [x] **Uygulama açıkken (foreground) gerçek bildirim gösterme:** FCM,
      mesajı SADECE arka planda/kapalıyken otomatik sistem bildirimi
      olarak gösterir — ön plandayken hiçbir şey göstermiyordu (sadece
      `debugPrint`). `flutter_local_notifications` eklendi,
      `az_oyun_default_channel` kanalı (AndroidManifest'teki FCM varsayılan
      kanalıyla aynı ID) üzerinden foreground mesajları artık gerçek bir
      heads-up bildirim olarak gösteriliyor + kısa bir uygulama-içi banner
      (SnackBar) de eşlik ediyor, oyun içindeyken kaçırılmasın diye.
- ⚠️ **Kullanıcı tarafında kalan adım:** Gerçek push göndermek için Firebase
  Console → Cloud Messaging'den kampanya/test mesajı gönderilmeli. Kod
  alıcı tarafı tamamen hazır (token alınıyor, foreground/background
  dinleniyor, foreground'da da görünür bildirim çıkıyor) ama "gönderici"
  (sunucu/console) tarafı bizim elimizde değil.

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
- [x] 4 seçenek: **Açık Tema** (marka renklerimiz), **Koyu Tema** (koyu
      marka rengi) — `AZTheme.light` / `AZTheme.dark` — **Telefonun Teması**
      (Android 12+ Material You — telefonun duvar kağıdından çıkardığı
      gerçek dinamik renk, `dynamic_color` paketi + `AZTheme.fromScheme`)
      — ve **Özel Renk** (kullanıcı kendi vurgu rengini seçer, 12 renklik
      hazır bir paletten) — `AZTheme.fromSeed(seed, brightness)`.
      **"Sistem" seçeneği bilerek kaldırıldı** — belirsizdi (sadece OS'un
      açık/koyu anahtarını takip ediyordu, kendine özgü bir rengi yoktu);
      yerine gerçekten telefonun kendi rengini çeken "Telefonun Teması"
      geldi. Telefon Material You desteklemiyorsa (Android <12 / iOS)
      sessizce bizim `AZTheme.light`/`dark`'a düşer.
- [x] `ThemeService` ile tercih (ve seçilen özel renk) `SharedPreferences`'ta
      saklanır, Ayarlar'da 4 seçenekli kart ile değiştirilir
- [x] **Bug fix — ana sayfa artık gerçekten dinamik:** `HomeScreen`,
      `SplashScreen`, `OnboardingScreen`, `ProfileScreen` önceden arka
      plan/vurgu rengini `AZColors.gradPurple`/`AZColors.purple` olarak
      SABİT kullanıyordu — Ayarlar'dan tema değiştirmenin hiçbir görünür
      etkisi yoktu. Hepsi artık `AZTheme.dynamicGradient(context)` /
      `Theme.of(context).colorScheme.primary` kullanıyor, seçilen tema
      anında her yere yansıyor.
- Not: Tema sistemi `MaterialApp.themeMode` üzerinden Ayarlar/Profil/Splash/
  Onboarding/Ana Sayfa gibi "chrome" ekranlarını kapsar. 30+ oyun ekranının
  her biri kendi özel gradyan temasıyla çalışmaya devam ediyor (Vampir
  Köylü'nün karanlık teması, Gece Ekspresi'nin noir teması gibi) — bunları
  da genel tema sistemine bağlamak ayrı, büyük bir iştir; şimdilik kapsam
  dışı.

### 7.5 Dil sistemi
- [x] `LanguageService` — **6 dil** arası anlık geçiş (Türkçe, İngilizce,
      Almanca, Fransızca, İspanyolca, Rusça), `SharedPreferences`'ta
      saklanır, Ayarlar'da dil seçim ekranı (`LanguageScreen`)
- Not: Flutter'ın resmi `flutter gen-l10n` (ARB tabanlı) sistemi **bilinçli
  olarak kullanılmadı** çünkü bu ortamda Flutter SDK çalıştırılamıyor, kod
  üretimi doğrulanamaz. Bunun yerine elle yazılmış, derleme zamanı kod
  üretimi gerektirmeyen basit bir çeviri haritası (`AppStrings`) kullanıldı
  — 6 dilin her birinde aynı 61 anahtar birebir dolu (otomatik script ile
  doğrulandı).
- ⚠️ **Kapsam:** Bu turda yeni eklenen ekranlar (Ayarlar, Onboarding, dil
  seçimi, yasal metinler) 6 dilde de çalışır. 31 oyunun **içindeki** tüm
  metinleri çevirmek ayrı, büyük bir içerik işidir — istenirse oyun oyun
  ilerlenir. Yeni bir dil eklemek `AppLanguage`'e bir değer ve
  `AppStrings`'e yeni bir `Map` eklemek kadar basit.
- Not: **Arapça bilerek eklenmedi** — Arapça sağdan-sola (RTL) yazım
  gerektirir ve bizim özel `AppStrings` sistemimiz Flutter'ın resmi
  `Directionality`/`Localizations` altyapısına bağlı değil, bu yüzden RTL
  otomatik olarak düzgün çalışmaz (metin solda hizalı kalır). RTL desteği
  ayrı, gerçek bir mühendislik işi — istenirse ayrıca eklenir.

### 7.6 Google Play Games
- [x] Uygulama açılışında otomatik (sessiz) giriş denemesi — `main.dart`
      `runApp()` sonrası `PlayGamesService.instance.signIn()` çağrılıyor;
      önceden sadece Profil/Ayarlar ekranında manuel "BAĞLAN" butonu vardı,
      o da hâlâ duruyor (otomatik giriş başarısız olursa manuel bağlanılabilir)
- [x] Play Console'da liderlik tablosu + başarım oluşturuldu ve ID'ler
      `play_games_service.dart`'a işlendi:
      - Skor tablosu **"Skorboard"** (`CgkIxOrNg4kPEAIQAQ`) — şimdilik
        oyuna özel tablo yok, tüm hızlı oyunların skoru buraya gidiyor
        (`_defaultLeaderboardId`); ileride oyun başına ayrı tablo
        açılırsa `_leaderboardIds` haritasına eklenmesi yeterli
      - Başarım **"İlk"** (`CgkIxOrNg4kPEAIQAw`) → uygulama içi
        `first_step` başarımına eşlendi
- Not: Play Console'da bir de **"Hoşgeldin"** adında bir Etkinlik
  (Events API) oluşturulmuş ama bu, liderlik tablosu/başarımlardan farklı
  bir Play Games özelliği — kodda henüz karşılığı yok, istenirse ayrı bir
  iş olarak eklenir.

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
- [x] Analytics — `AnalyticsService` eklendi (`lib/core/services/analytics_service.dart`);
      `firebase_analytics` bağımlılığı + `MaterialApp.navigatorObservers` ile
      otomatik ekran görüntüleme takibi; `ProfileService.reportGameResult`
      (tek çağrı noktası → 30+ oyunun tamamı otomatik kapsanıyor) ve
      `unlockAchievement` üzerinden oyun/seviye/başarım olayları, IAP satın
      alma akışından `iap_purchase`, tema/dil değişikliklerinden kullanıcı
      özellikleri (`app_language`, `theme_preference`) gönderiliyor
- [x] Crashlytics — `firebaseCrashlytics` bloğu `build.gradle.kts`'de aktif
      hale getirildi (mapping/native symbol upload açık), `main.dart`'ta
      `FlutterError.onError` ve `PlatformDispatcher.instance.onError`
      Crashlytics'e bağlandı — yakalanmayan tüm Flutter/Dart hataları artık
      raporlanıyor

### 7.9 Android manifest / platform ayarları
- [x] Deep link için `intent-filter` (custom scheme `azoyun://`)
- [x] `POST_NOTIFICATIONS` izni (Android 13+)
- [x] FCM meta-data (varsayılan bildirim ikonu/kanalı)

## 8. İkinci endüstriyel tur — kalıcı liste (ASLA UNUTMA)

Bölüm 7 ile aynı kural geçerli: bir madde tamamlandığında ✅ işaretlenir ama
satır silinmez. Bu bölüm, kullanıcının 13 Ağustos 2026 turunda istediği,
"artık gerçek bir oyun mağazası ürünü gibi olsun" kapsamındaki işlerin kaydı.

### 8.1 Dedektif oyunu → çok vakalı kampanya
- [x] "Gece Ekspresi Cinayeti" tek vakadan, kampanya yapısına geçirildi:
      `MysteryCase` veri modeli, `kMysteryCases` sıralı listesi,
      `MysteryCampaignService` (SharedPreferences tabanlı ilerleme kaydı —
      bir vaka bitirilince bir sonraki açılır), vaka seçim ekranı
      (`MysteryLobbyScreen` artık kilit durumlarını gösteren bir hub)
- [x] **5 vaka** yazıldı ve tam oynanabilir, kampanya **tamamlandı**: Vaka 1
      "Gece Ekspresi Cinayeti" (mevcut), Vaka 2 "Galeri Sirius'taki
      Sahtekârlık", Vaka 3 "Borsa Kulesi'nde Ölüm", Vaka 4 "Çember"
      (şok twist finali) ve **Vaka 5 "Gölgenin Yüzü" — gerçek büyük
      final**. Hepsi aynı görünmez ipucunu taşıyor: daire içinde bir göz
      mührü ve "V.K." baş harfleri.
- [x] Vaka 4'te şok twist: oyuncunun çözdüğü tüm vakaların arkasında tek
      bir kişi var — Vedat Korkmaz (V.K.), balo boyunca dedektife
      "yardımcı" olan sıcakkanlı bir tanıdık kılığında dolaşıyor. Onu
      doğru tahmin etsen bile "Merkez Sistem" imzası birkaç dakika önce
      atılmış olur — çok geçsin ve hikaye kasıtlı bir cliffhanger'la
      biter ("İZ SÜRMEYE DEVAM EDECEK...").
- [x] **Vaka 5 "Gölgenin Yüzü" ile gerçek kapanış eklendi** (kullanıcı
      isteği: "sonu gelsin, sonunu merak ediyoruz"). Naz Ilgın'ın balo
      gecesi topladığı kayıtlar + önceki 3 vakanın kanıtları birleşiyor;
      dedektif, Vedat Korkmaz'a en yakın 4 kişiden birini konuşturarak
      onun gerçek kimliğini (yıllar önce "ölmüş" ilan edilen mühendis
      Kerim Vardar) ve "Merkez Sistem"in gerçek amacını (şehrin
      bankacılık/kimlik verisini tek elde toplayan bir kontrol sistemi)
      ortaya çıkarıyor. Doğru şüpheliyi (Selin Kutlu) seçmek tam bir
      zafer sonu veriyor (sistem kapatılıyor, kimlik ifşa oluyor,
      Interpol kırmızı bülten çıkarıyor); diğer 3 seçim de hikayeyi
      kapatıyor ama "eksik bir parçayla" (sistem yine kapatılıyor, şehir
      kurtuluyor, ama V.K.'nın yüzü hiç netleşmiyor) — hiçbir son artık
      "devam edecek" ile bitmiyor, kampanyanın hepsi net bir final
      alıyor. Vaka seçim ekranındaki not güncellendi ("hikaye
      tamamlandı").

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

### 8.4 Firebase oda temizliği (hayalet oda önleme) — tamamlandı
- [x] `RoomService.registerPresence()` eklendi ve 12 online oyunun
      tamamına bağlandı: bir oyuncu/host bağlantısı **crash/ağ kopması
      gibi kontrolsüz** bir şekilde koparsa (uygulamadan düzgün "çık" ile
      değil), oda artık Firebase'de sonsuza kadar kalmıyor
- Not: "Host çıkarsa" / "oyun bitince silinsin" senaryosu zaten TÜM 12
  online oyunda çalışıyordu (`_leave()` + boş oda kontrolü) — eksik olan
  sadece **anormal/kontrolsüz kopma** durumuydu, `onDisconnect()` ile
  kapatılıyor.

### 8.5 Eski 10 oyuna XP/başarım entegrasyonu
- [x] Golf, Serbest Vuruş (soccer), Araba Yarışı, Adam Asmaca, Şehir
      Bulmaca, Kelime Bulmaca, Okey/Okey 101, Dama, Dövüşçüler, Yalancılar
      Kahvesi — hepsinin final ekranına `ProfileService.reportGameResult`
      + `AchievementService.checkAndUnlock` eklendi. Artık online 12
      oyunun (bunlara + Vampir Köylü + Hain Kim? + Gece Ekspresi) TAMAMI
      maç sonunda XP/coin/başarım kazandırıyor.

### 8.6 Oyun içi hata taraması
- [x] Araba Yarışı: araba sprite'ları fizik yönüne göre hep **ters**
      duruyordu (emoji varsayılan olarak sola bakar, hareket matematiği
      açı 0'ı "sağa" kabul eder) — `+pi` düzeltmesiyle çözüldü
- [x] Dövüşçüler, Dama, Okey tarandı. Dövüşçüler/Okey'de açık bir mantık
      hatası bulunmadı (Racing'deki `_finish()`'teki şüpheli görünen
      "kazanan sayısı" hesabı da yakından incelendi — aslında race
      condition YOK, tek bir yerel `players` anlık görüntüsü kullanıldığı
      için hesap doğru).
- [x] **Dama gerçek Türk Dama kurallarına geçirildi:** Önceden
  `checkers/dama_screens.dart` "Türk Dama" diye etiketliydi ama aslında
  uluslararası (diyagonal) dama kurallarıyla çalışıyordu. Kullanıcıya
  soruldu, gerçek kurallara geçirilmesi istendi:
  - Diziliş: taşlar en yakın iki sırada (en arka sıra hariç), **tüm
    sütunlarda** — sadece koyu karelerde değil
  - Er hareketi: **düz** ileri/sağ/sol bir kare (çapraz DEĞİL, geri gidemez)
  - Yakalama: er dört yönde de (ileri/geri/sağ/sol) bitişik rakibi atlar
  - Dama (kral): kale gibi bir yönde istediği kadar ilerler; yakalarken de
    "uçan dama" gibi mesafeden atlayıp arkasındaki boş karelerden
    herhangi birine inebilir
  - Doğrulama: kuralların birebir Python simülasyonu yazılıp çalıştırıldı
    — başlangıç pozisyonunda her iki tarafta 16 taş doğru sırada, **tam 8
    açılış hamlesi** var (gerçek Türk Dama'nın bilinen özelliği), er/dama
    yakalama testleri beklenen sonucu verdi

### 8.7 Google Play Games Services v2 — gözden geçirildi ve tamamlandı
- [x] Google'ın resmi rehberi (`developer.android.com/games/pgs/android/
      android-start` + `android-signin` + `migration_overview`) incelendi.
      **Önemli bulgu:** Google, eski v1 kimlik doğrulama akışını
      (`GoogleSignInClient` tabanlı) 2025'te Play Services Auth SDK'dan
      kaldırdı — hâlâ v1 kullanan uygulamalar çalışmaz hale gelebilirdi.
      Kullandığımız `games_services` Flutter paketi (pub.dev
      changelog'una göre) **4.0.0 sürümünden beri zaten PGS v2'ye migrate
      olmuş** — `pubspec.yaml`'daki `^4.1.1` kısıtlaması bu migrasyonu
      zaten kapsıyor, paket değişikliği gerekmedi.
- [x] Eksik olan, native tarafın kendisiydi — eklendi:
      - `android/app/build.gradle.kts`: `com.google.android.gms:
        play-services-games-v2:+` bağımlılığı (Google'ın resmi adım 1'i)
      - `AndroidManifest.xml`: `com.google.android.gms.games.APP_ID`
        meta-data, `res/values/strings.xml`'deki
        `game_services_project_id` string'ine işaret ediyor
      - `MainActivity.kt`: `PlayGamesSdk.initialize(this)`,
        `super.onCreate()`'den önce çağrılıyor (Google'ın zorunlu kıldığı
        sıra)
- Not: v2'de platform kimlik doğrulaması **otomatik ve sessiz** çalışır
  (kullanıcı payı gerektirmez) — bu da `main.dart`'taki
  `PlayGamesService.instance.signIn()` çağrısının tam olarak istenen
  "dinamik bağlantı" davranışıyla örtüştüğünü doğruluyor.
- [x] **Gerçek proje ID'si girildi:** `res/values/strings.xml`'deki
  `game_services_project_id`, Play Console → Yetkilendirme sayfasındaki
  gerçek "Uygulama kimliği" (`517819561284`) ile güncellendi. Play Games
  Services artık tam olarak aktif.
- [x] Play Console'da liderlik tablosu + başarım oluşturuldu, ID'ler
  `play_games_service.dart`'a işlendi (bkz. bölüm 7.6 için ayrıntı).

### 8.8 Tüm oyunları "çocuksu 2D"den "3D/eğlenceli" hale getirme
- [x] Kullanıcı geri bildirimi: mevcut UI'lar güzel ama oyunların çoğu
      (özellikle strateji/parti oyunları) düz 2D ve "çocuksu" hissettiriyor;
      Araba Yarışı ve Dövüşçüler'deki gibi daha "3D hissi veren" bir
      görsel dile geçilmesi isteniyor
- [x] **Paylaşılan "Rol Açılış Kartı" bileşeni eklendi:**
      `showRoleRevealCard()` (`az_widgets.dart`) — düz `showDialog` yerine
      perspektif döndürme + geri sekmeli ölçek animasyonuyla açılan,
      gradyanlı/gölgeli "3D kart" hissi veren ortak bir bileşen. Hain Kim?
      ve Vampir Köylü'nün rol açıklama ekranları buna geçirildi — aynı
      bileşen ileride her yeni sosyal-tahmin oyununda (ve isteğe göre
      diğer oyunlarda) tekrar kullanılabilir.
- [x] **Hain Kim? (Among Us tarzı) — gerçek hata + görsel geçiş:**
      Hain'in "tekrar eleme" bekleme süresi (`killCooldownUntil`) sadece
      yerel state'te tutuluyordu — ekran yeniden oluşunca ya da başka
      ekrana gidip gelince sıfırlanıyordu; artık Firebase'de
      (`players/$key/killCooldownUntil`) saklanıyor. Görev kartları
      `AnimatedContainer` + gölgeli ikon rozetiyle, üst bilgi çubuğu
      gölge/metin-gölgesiyle derinlik kazandı; rol açılışı artık dramatik
      bir kart animasyonu ile açılıyor (önceden hiç yoktu, sadece sabit
      bir üst bant vardı).
- [x] **Yalancılar Kahvesi:** Tur/rol kartı düz beyaz `Card`'dan,
      gradyanlı + gölgeli + her tur `AnimatedSwitcher` ile canlanan
      (ölçek + solma) bir tasarıma geçirildi.
- [x] **Vampir Köylü:** Gün/gece üst bandı ve rol banner'ına gölge derinliği
      eklendi.
- [x] **Kalan 9 online oyun (Dama, Racing, Okey, Fighter, Golf, Soccer,
      Hangman, City, Word) — görsel derinlik geçişi:**
      - **Türk Dama:** Üst bar gradyan + gölge; tahtanın kendisi artık
        koyu ahşap çerçeveli, gölgeli bir "kutu" içinde (masaya oturmuş
        gibi); taşlar düz renk yerine radyal gradyanlı (üstten ışık alan
        küre hissi) + daha belirgin damla gölgesi.
      - **Araba Yarışı:** Araba sprite'larının altına elips zemin gölgesi
        eklendi (havada süzülüyor hissi yerine pistin üstünde gerçekten
        duruyor hissi), araç gövdesi radyal gradyan aldı; üst HUD ve alt
        kontrol çubuğu gradyan + gölgeyle derinlik kazandı.
      - **Okey:** Skor çubuğu gradyan + gölge, deste/atık kutuları gölge,
        durum rozeti `AnimatedContainer` + parlama gölgesi.
      - **Dövüşçüler:** HUD paneli gradyan + gölge; can barları artık
        siyah kenarlıklı, renk-uyumlu parlama gölgeli "beveled" kapsüller
        içinde.
      - **Mini Golf & Futbol:** Skor çubukları gradyan + gölge, durum
        şeridi gölge (golf/futbol sahası çizimleri zaten önceden gölge/
        parlama detaylarıyla pseudo-3D'ydi, dokunulmadı).
      - **Adam Asmaca:** Üst bar gradyan + gölge, aktif oyuncu rozeti
        parlama gölgesi.
      - **Şehir Bul & Kelime Avı:** Skor çubukları gradyan + gölge; Kelime
        Avı'nda harf karoları artık "kabartma" hissi veren yön değişken
        gölgeyle (kullanılmamış: dışa gölge = kabarık, kullanılmış: içe
        doğru daha yumuşak gölge = basılmış) çiziliyor.
- Not: Bu, **30+ oyunun tamamını** kapsayan çok büyük bir görsel yenileme
  girişimiydi. Sosyal-tahmin/parti oyunları (Hain Kim?, Vampir Köylü,
  Yalancılar Kahvesi) ve şimdi de tüm online oda oyunları (12/12) bu
  turda tamamlandı. Kalan alan: hızlı-oyunlar sekmesindeki tek-kişilik/
  yerel arcade oyunları (XOX, 4'lü Bağlantı, Reversi, Yılan, 2048 vb.) —
  bunlar zaten sade/hızlı oynanış için tasarlandığından düşük öncelikli,
  istenirse ayrı bir turda ele alınabilir.

### 8.9 Tüm oyunlarda kapsamlı hata taraması ("çalışmayanlar/ters çalışanlar var")

Kullanıcı isteği üzerine 29 oyun dosyasının tamamı (12 online + 17 yerel
hızlı oyun) satır satır, kod okuyarak taranıp gerçek mantık hataları arandı
(derleme/çalıştırma yapılamadığından "simülasyon" kod üzerinden zihinsel
yürütmeyle yapıldı). Bulunan ve **düzeltilen** somut hatalar:

- [x] **Yılan (Snake) — geçerli hamle yanlışlıkla "kendine çarpma"
      sayılıyordu:** Çarpışma kontrolü, o hamlede boşalacak kuyruk hücresini
      hesaba katmadan tam yılan gövdesine bakıyordu; yılan yem yemeden kendi
      kuyruğunun o an çekileceği hücreye girdiğinde (ör. dar bir daire
      çizerken) oyun "öldün" diyip erken bitiyordu.
- [x] **Dövüşçüler — maçı kazananı YANLIŞ taraf belirliyordu (KRİTİK):**
      Kazanma eşiği hesaplaması hatalıydı (`maxRounds=3` için pratikte
      "3-0 olmadan asla" tetiklenmiyordu), gerçekte maçı SADECE 3. (son)
      raundu kazanan bitiriyordu — toplam skora bakılmaksızın. Sonuç: 2-0
      önde olan oyuncu 3. raundu kaybederse, daha AZ raunt kazanan rakip
      "🏆 ZAFER!" ekranını görüyordu. Artık kazanan, o ana kadarki toplam
      raunt skoruna göre doğru belirleniyor. Ayrıca Ninja/Paladin özel
      yeteneklerinin "1 saldırı kaçır" / "hasar yok" açıklamaları gerçek
      davranışla (yüksek savunma, hasar azaltma — tam blok değil)
      uyuşmuyordu; metinler gerçeğe uyduruldu.
- [x] **Araba Yarışı — iki ayrı hata:** (1) Lobide her oyuncuya farklı bir
      başlangıç X'i atanıyordu ama oyun ekranı bunu hiç okumadan sabit
      değerlerle başlıyordu — tüm arabalar aynı noktada üst üste
      başlıyordu; artık gerçek başlangıç X'i Firebase'den okunuyor.
      (2) Yarışı 1. sırayı alan oyuncu bitirir bitirmez TÜM oyuncular için
      anında sonlandırıyordu (`pos == 1` koşulu) — pistte hâlâ yarışan 2-3-4.
      oyuncuların fizik motoru zorla durduruluyordu. Artık yarış sadece
      herkes bitirince sona eriyor.
- [x] **Mini Golf — host önce biterse oyun sonsuza kadar kilitleniyordu
      (KRİTİK):** Bir sonraki deliğe geçiş kontrolü sadece host kendi
      topunu bitirdiğinde tetikleniyordu. Host diğerlerinden ÖNCE biterse
      ve daha sonra son oyuncu biterse, bunu tekrar kontrol eden hiçbir
      mekanizma yoktu — oyun "Diğerleri bekleniyor..." ekranında sonsuza
      kadar takılı kalıyordu (4 kişilik oyunda ~%75 olasılıkla
      tetikleniyordu). Artık her Firebase güncellemesinde host tarafında
      yeniden kontrol ediliyor. Ayrıca hiçbir yerde okunmayan ölü bir
      Firebase alanı (`shots`) temizlendi.
- [x] **Şehir Bulmaca — üç ayrı hata:** (1) Türkçe büyütme sorunu: Dart'ın
      `toUpperCase()` Türkçe'ye duyarlı değil (küçük "i" → noktasız "I"
      yapıyor, "İ" değil) — "istanbul" yazan oyuncunun cevabı "İSTANBUL"
      ile eşleşmiyordu (10 şehirden 4'ünü etkiliyordu). Türkçe'ye duyarlı
      bir büyütme fonksiyonu eklendi. (2) "Ekstra ipucu" reklamı, "ilk 2
      harf" vermesi gerekirken şehrin TAM adını da mesaja ekliyordu —
      artık sadece ilk 2 harf gösteriliyor. (3) Cevaplama kilidi
      (`_answered`) her Firebase güncellemesinde (başka oyuncunun ipucu
      istemesi gibi alakasız olaylarda dahi) sıfırlanıyordu, bu da doğru
      cevaptan sonraki kısa gecikme içinde puanın tekrar eklenmesine yol
      açabiliyordu — artık sadece tur gerçekten değişince sıfırlanıyor.
- [x] **Kelime Bulmaca — kelime bankasının dörtte biri asla kurulamıyordu:**
      Harf havuzunda düz "I" (noktasız) hiç yoktu, ama kelime bankasındaki
      59 kelimeden 15'i ("KAPI", "KEDI", "YILDIZ" vb.) bu harfi içeriyordu.
      Harf havuzuna "I" eklendi.
- [x] **Vampir Köylü — yanlış rol grubu sayacı gösteriliyordu:** Doktor/
      Dedektif kendi (tekil) gece eylemini tamamlayıp beklerken, ekranda
      "$X/$Y hazır" sayacı — rolüyle hiç alakası olmayan, dolaylı olarak
      vampir sayısını da ele veren — vampirlerin oy durumunu gösteriyordu.
      Artık bu sayaç sadece gerçek grup oylamalarında (vampir gece oyu,
      gündüz genel oylama) gösteriliyor.
- [x] **Türk Dama — kural metni koddaki gerçek davranışla çelişiyordu:**
      Lobideki "Nasıl Oynanır" metni "piyonlar çapraz ileri hareket eder"
      diyordu, ama kod (bilerek) DÜZ hareket kullanıyor — klasik dama bilen
      biri çapraz hamle bekleyip oyunun "bozuk" olduğunu düşünebilirdi.
      Metin gerçek (düz hareket) kurala uyduruldu.

- [x] **Türk Dama — zorunlu zincirleme (çoklu) yakalama eklendi:** Daha
      önce bir taş art arda birden fazla taş yiyebilecek durumda olsa bile
      tek atlamadan sonra sıra rakibe geçiyordu; artık gerçek Türk Dama
      kuralına uygun olarak, yeni konumdan devam eden bir yakalama
      mümkünse sıra DEĞİŞMİYOR ve oyuncu aynı taşla zincirlemeye devam
      etmek zorunda (`chainR`/`chainC` Firebase alanı ile takip ediliyor,
      UI'da "⚡ Zincirleme yakalama!" uyarısı ve turuncu üst bant ile
      gösteriliyor, başka taş seçmeye çalışırsa engelleniyor). Mantık,
      paralel bir Python simülasyonuyla doğrulandı.

- [x] **Serbest Vuruş (futbol) — top fiziği rakibe senkronize edildi:**
      Daha önce top pozisyonu/hızı tamamen yerel state'ti; sırası gelmeyen
      oyuncu sadece "Rakibin vuruyor..." yazısı görüyor, top animasyonunu
      hiç görmüyor, sonra skor birden değişiyordu. Artık vuran taraf
      (fiziği hesaplayan taraf) topun/kalecinin konumunu saniyede 10 kez
      Firebase'e yazıyor (`ball: {x,y,vx,vy,spin,gkX,moving}`); izleyen
      taraf kendi fizik motorunu hiç çalıştırmadan bu değerleri doğrudan
      görselleştiriyor. Vuruş sonucu (gol/kaleci kurtardı/kaçırdı) da
      `result`/`resultSeq` alanlarıyla senkronize ediliyor — izleyen taraf
      artık gerçek zamanlı GOL/kurtarış/kaçırma animasyonunu görüyor,
      skor "birden" değişmiyor.

- [x] **Okey — gerçek "AÇTIM" el geçerliliği kontrolü eklendi:** Daha önce
      buton her zaman kabul ediyordu ("elini gerçekten grupladın mı?"
      diyaloğu sadece kullanıcının kendi beyanına güveniyordu). Artık
      `isValidOkeyHand()` (backtracking algoritması, `okey_screens.dart`)
      eldeki TÜM taşların (jokerler dahil) 3+ taşlık per (aynı sayı farklı
      renk) ve seri (aynı renk ardışık sayı) gruplarına tam olarak
      ayrılıp ayrılamadığını gerçekten hesaplıyor. Geçersiz bir elle
      "AÇTIM" denenirse artık gerçek bir ceza puanı (-20/-30) uygulanıyor
      — daha önce lobideki "yanlış açarsan puan kaybedersin" uyarısı boş
      bir tehditti. Algoritma paralel bir Python simülasyonuyla (per,
      seri, joker-tamamlama, karma gruplar, 21 taşlık büyük/rastgele
      eller dahil) doğrulandı; performans milisaniyeler seviyesinde.
      Ayrıca "Okey 101" modunun tanıtım metnindeki gerçek dışı "101
      puana ulaşan elenir, çoklu tur" iddiası kaldırıldı, gerçek
      davranışı (küçük/hızlı el, ilk açan kazanır) yansıtacak şekilde
      düzeltildi.

**Bilinen sınırlamalar (bug değil, eksik/basitleştirilmiş özellik — bu
turda düzeltilmedi, kapsamı büyük bir refactor gerektiriyor):**
- "Okey 101" modu hâlâ tek elde bitiyor — gerçek 101-puan çoklu-tur/
  elenme sistemi (skor biriktirme, oyuncu elenmesi, oyunun birden fazla
  el sürmesi) eklenmedi; bu, oyunun round yapısını baştan tasarlamayı
  gerektiren ayrı ve büyük bir iş.

### 8.10 Profil/İstatistik ekranı — Bento-Grid SaaS dashboard yenilemesi

Kullanıcı isteği: eski profil ekranının UI'ını tamamen atıp, Linear/
Vercel kalitesinde bir "dashboard" dili ile sıfırdan inşa etmek — veri
modelleri/servisler (`PlayerProfile`, `ProfileService`,
`AchievementService`, `PlayGamesService`) korunarak.

- [x] **Yeni tasarım token seti** (`lib/core/theme/dashboard_tokens.dart`):
      sabit Slate/Zinc koyu palet (canvas `#09090B`, kart `#18181B`,
      highlight `#27272A`), mikro-kenarlıklar (~%8 beyaz), Elektrik
      İndigo (`#6366F1`) + Zümrüt Nane (`#10B981`) aksan renkleri,
      `GoogleFonts.plusJakartaSans` tipografi hiyerarşisi. Bilerek
      uygulamanın geri kalanındaki `AZTheme`'den ayrı tutuldu — sadece bu
      dashboard yüzeyine özel, kullanıcının seçtiği tema rengine göre
      değişmiyor (kasıtlı "kurumsal analytics" hissi).
- [x] **Modüler Bento-Grid bileşen kütüphanesi**
      (`lib/features/profile/widgets/`): `BentoCard` (glassmorphism
      temel yüzey), `KpiMetricCard` (trend rozetli metrik kartı),
      `ProfileHeroCard` (seviye/XP/coin gradyanlı hero kart),
      `WinRateDonut` (fl_chart `PieChart` ile galibiyet/mağlubiyet
      halkası), `GameVarietyChart` (fl_chart `BarChart` ile Hızlı
      Oyunlar/Online Odalar kapsama grafiği), `AchievementBentoTile`,
      `PlayGamesBanner`, `ProfileDashboardShimmer` (yükleme iskeleti).
      Tüm grafikler **gerçek** `PlayerProfile` verisinden türetiliyor
      (uydurma zaman serisi kullanılmadı — uygulama geçmiş maç
      tarihçesi tutmuyor, bu yüzden "trend" yerine dürüst birer *özet*
      grafiği: galibiyet oranı ve oyun çeşitliliği).
- [x] **Adaptive layout**: `LayoutBuilder` ile 1024px kırılma noktası —
      altında `_buildMobileDashboard` (`SliverAppBar` + tek sütunlu
      `CustomScrollView`), üstünde `_buildDesktopDashboard` (sol geniş /
      sağ dar iki panelli çok sütunlu Bento-Grid, 1240px'de ortalanmış
      içerik).
- [x] **Durum yönetimi**: yükleme (shimmer/skeleton, gerçek layout'un
      kaba bir taklidi), boş durum (`_NewPlayerBanner` — hiç maç
      oynanmamışsa), hata durumu (Play Games bağlantı hatası SnackBar
      ile), başarı durumu (dolu dashboard) ayrı ayrı ele alındı.
      `game_ids.dart`'a `kOnlineGameIds`/`kOnlineGameTitles` eklendi
      (oyun çeşitliliği grafiğinin veri kaynağı).
- Not: İkon paketi olarak kullanıcının istediği `iconsax_flutter`/
  `lucide_icons` yerine Flutter'ın kendi Material Icons (Rounded
  varyant) seti kullanıldı — bu sandbox'ta `flutter pub get`/derleme
  çalıştırılamadığı için üçüncü parti paketlerin tam ikon adlarını
  (WebFetch ile pub.dev/GitHub sorgulandı ama tutarsız sonuçlar geldi)
  güvenilir şekilde doğrulayamadık; yanlış bir sabit isim derlemeyi
  kırardı. `google_fonts` ve `fl_chart` paketleri pub.dev'den
  doğrulanmış sürümleriyle (8.2.1 / 1.2.0) eklendi. **Kullanıcının
  gerçek cihazda `flutter pub get && flutter run` çalıştırıp
  doğrulaması gerekiyor** — bu ortamda derleme testi yapılamadı.

### 8.11 Web platformu desteği + Firebase Hosting + SEO + AdSense

Kullanıcı isteği: AZOyun'u Flutter Web olarak yayınlamak, Firebase
Hosting'e (`azoyun.web.app`) deploy etmek, Google Search Console'da
doğrulamak ve Google AdSense başvurusu için siteyi hazırlamak.

- [x] **Kritik web-uyumluluk taraması ve düzeltmeleri** — proje mobil-
      öncelikli yazıldığı için birkaç native-only paket web'de derlemeyi
      kıracak ya da açılışta çökertecek durumdaydı; pub.dev'den her
      paketin platform desteği tek tek doğrulanıp düzeltildi:
      - `AdService`: `dart:io`'nun `Platform.isAndroid`'i **Web'de hiç
        derlenmez** (dart:io web'de mevcut değil) — web-güvenli
        `defaultTargetPlatform`'a geçirildi. `google_mobile_ads` sadece
        Android/iOS destekliyor; `initialize()`'a `kIsWeb` guard'ı
        eklendi (diğer tüm metodlar zaten `_initialized` üzerinden
        güvenliydi).
      - **`main.dart` — en kritik bulgu:** `firebase_crashlytics` SADECE
        Android/iOS/macOS destekliyor, Web YOK. `FirebaseCrashlytics
        .instance`'a `runApp()`'tan ÖNCE, try/catch'siz erişiliyordu —
        bu Web'de uygulamanın AÇILIŞTA çökmesine (beyaz ekran) yol
        açardı. `if (!kIsWeb)` ile korumaya alındı; aynı şekilde
        `FirebaseMessaging.onBackgroundMessage` da (Web'de karşılığı
        service worker'dır) korundu.
      - `PlayGamesService` (`games_services` — sadece Android/iOS/
        macOS) ve `IAPService` (`in_app_purchase` — sadece Android/iOS/
        macOS): `kIsWeb` guard'ları eklendi, `_iap` alanı `late final`
        yapılıp Web'de hiç resolve edilmeyecek şekilde güvenceye
        alındı.
      - **Web'de sorunsuz çalıştığı doğrulanan** kritik paketler:
        `firebase_database` (bu sayede 12 online oda-oyunun TAMAMI Web'de
        de çalışır), `firebase_analytics`, `app_links`, `permission_handler`,
        `flutter_local_notifications`.
- [x] **Firebase Hosting yapılandırması**: `firebase.json`'a `hosting`
      bloğu eklendi (`site: "azoyun"`, `public: "build/web"`, SPA için
      tüm yolları `index.html`'e yönlendiren `rewrites`, statik
      varlıklar için `Cache-Control` başlıkları). `.firebaserc`
      oluşturuldu (proje: `azoyun-569b2`). `firebase_options.dart`'taki
      `web` bloğu, kullanıcının Firebase Console'da az önce kaydettiği
      YENİ web app bilgileriyle (apiKey, appId, measurementId)
      güncellendi.
- [x] **SEO**: `web/index.html` sıfırdan yazıldı — gerçek başlık/
      açıklama (placeholder "A new Flutter project." yerine), Open
      Graph + Twitter Card etiketleri, `canonical` URL, `lang="tr"`,
      tema rengi. `web/robots.txt` ve `web/sitemap.xml` eklendi (SPA
      olduğu için sitemap bilinçli olarak tek URL'lik — sahte alt
      sayfa URL'leri uydurulmadı). `web/manifest.json` marka
      bilgileriyle (isim, açıklama, `#6C63FF` tema rengi) güncellendi.
- [x] **Google Search Console doğrulaması**: kullanıcının verdiği
      doğrulama kodu `<meta name="google-site-verification" ...>`
      etiketi olarak `index.html`'e eklendi.
- [x] **Google AdSense**: doğrulama script'i (`ca-pub-5779807348211992`)
      `index.html`'e eklendi. `web/ads.txt` ve `web/app-ads.txt` zaten
      doğru yayıncı kimliğiyle mevcuttu, dokunulmadı.
- **Bilinen sınırlamalar / kullanıcının yapması gereken adımlar** (bu
  ortamda Flutter SDK yok, gerçek derleme/deploy/OAuth login
  yapılamadı):
  - `web/favicon.png` ve `web/icons/*.png` hâlâ varsayılan Flutter
    logosu — marka logosu yok, görsel varlık üretilemedi. Kullanıcının
    kendi logosunu sağlaması (ya da bir tasarım aracıyla ürettirmesi)
    gerekiyor.
  - Gerçek `flutter build web`, `firebase login`, `firebase deploy
    --only hosting:azoyun` komutlarının kullanıcının kendi
    makinesinde/CI'da çalıştırılıp doğrulanması gerekiyor.
  - Google Search Console'da "Doğrula" butonuna basmak ve AdSense'te
    "İnceleme iste" butonuna basmak kullanıcı tarafından yapılmalı
    (bu, Google hesabı yetkilendirmesi gerektirir).
  - AdSense onaylandıktan sonra gerçek reklam birimlerinin
    (`<ins class="adsbygoogle">`) sayfaya yerleştirilmesi ayrı bir iş —
    Flutter Web'de bu genelde `HtmlElementView`/platform view ile
    yapılır, henüz eklenmedi.

### 8.12 Web derleme hatası düzeltme + Okey tam yenileme

- [x] **Kritik derleme hatası düzeltildi**: kullanıcının gerçek
      `flutter build web` denemesinde `dart2js` şu hatayla
      duruyordu: `okey_screens.dart:604:9: The method '_snack' isn't
      defined for the type '_OGameState'`. `_snack` yardımcı metodu
      sadece kardeş State sınıflarında (`_OLobbyState`, `_ORoomState`)
      tanımlıydı; `_OGameState`'e kendi `_snack` metodu eklendi. Bu
      hata Web'e özgü değildi — tüm platformlarda derlemeyi
      bozuyordu. (Build log'daki uzun "Wasm dry run findings" listesi
      ise gerçek hata DEĞİL — sadece `--wasm` hedefiyle ilgili
      bilgilendirme uyarıları, normal `flutter build web` derlemesini
      etkilemiyor.)
- [x] **Okey oyunu — kullanıcı geri bildirimiyle uçtan uca yenileme**:
      kullanıcı oyunu "tasarım yok, istaka yok, taşlar rastgele,
      kurallar eksik, 3D his yok" diye tarif etti. Yapılanlar:
  - **Gerçek dağıtım kuralı düzeltildi**: önceden `_mode == '101'`
    için 7, diğer modda 21 taş dağıtılıyordu — ikisi de gerçek Okey
    kuralı değil. Artık her oyuncuya 14 taş, turu açan (ilk sıradaki)
    oyuncuya ekstra 1 taş (15) veriliyor — klasik Okey ve 101 Okey'de
    ortak olan gerçek kural.
  - **`_mustDiscard` artık türetilen bir getter**: önceden elle
    tutulan yerel bir `bool` bayraktı (yeniden bağlanmada/sayfa
    tazelemede yanlış senkronize olabilirdi, örn. turu açan oyuncu
    zaten 15 taşla başladığı halde tekrar çekebilirdi). Artık
    `_isMyTurn && _hand.length.isOdd` olarak sunucudaki el
    uzunluğünden türetiliyor — asla yanlış senkronize olmaz.
  - **İstaka (rack) eklendi**: el artık düz bir kaydırmalı satır değil,
    ahşap gradyanlı, gölgeli, oyuklu bir istaka görselinin üzerinde
    duruyor.
  - **Taşları sürükleyerek yeniden sıralama**: `ReorderableListView`
    ile taşlar uzun basıp sürüklenerek istekediğiniz sıraya
    dizilebiliyor (gerçek Okey'de oyuncuların gruplarını görsel olarak
    düzenlemesi gibi). Sıra, taş atıldığında sunucuya da yazılıyor ki
    düzen korunsun.
  - **Otomatik sıralama butonları**: "Renk" (renge sonra sayıya göre —
    seri/per gruplarını yan yana getirir) ve "Sayı" (sayıya sonra
    renge göre — perleri yan yana getirir) butonları eklendi.
  - **3D/kabartmalı taş tasarımı**: taşlar artık düz renkli kutular
    değil — fildişi/krem gradyanlı, üstte cam parlaklık şeridi, altta
    gerçek okey taşının tabanındaki oyuğu andıran ince bir çizgi,
    seçiliyken yukarı kalkan (transform) ve daha güçlü gölgeli bir
    görünüme kavuştu.
  - **Masa arka planı zenginleştirildi**: düz yeşil yerine, üstten
    aydınlık merkezli radyal keçe gradyanı eklendi.
  - El geçerliliği kontrolü ("AÇTIM") daha önce (bkz. 8.x, görev #67)
    gerçek bir backtracking çözücüyle doğrulanıyordu — bu oturumda
    algoritma incelendi, hatasız bulundu; sorun algoritmada değil,
    yukarıdaki eksik dağıtım kuralı ve görsel/etkileşim eksiklerindeydi.
- **Bilinen sınırlamalar**: Bu ortamda Flutter SDK yok — kullanıcının
  kendi cihazında `flutter build web` / `flutter run` ile test edip
  onaylaması gerekiyor. Gerçek 3D render (WebGL/OpenGL taş modelleri)
  yapılmadı — Flutter'da tam 3D motor entegrasyonu ayrı, çok daha
  büyük bir iş; bunun yerine güçlü kabartma/gölge/gradyan teknikleriyle
  "3D his" hedeflendi.

### 8.13 Dövüşçüler — hasar yarış durumu ve ölüm algılama düzeltmesi

Kullanıcı "oyunlar hatalarla dolu, rekabetsiz, eğlencesiz" geri
bildirimi verdi; Dövüşçüler (1v1 gerçek zamanlı dövüş) önceliklendirilen
3 oyundan biri seçildi. İnceleme sonucu üç gerçek, ciddi hata bulundu:

- [x] **Hasar "kaybolma" yarış durumu**: hasar, "mevcut canı oku → yeni
      değeri hesapla → yaz" şeklinde uygulanıyordu. Aynı oyuncunun normal
      saldırısı ile DoT (zehir/yanma) tiki neredeyse aynı anda tetiklenirse,
      ikinci yazma birincinin üzerine YAZIYOR ve hasarın bir kısmı sessizce
      kayboluyordu — rakip vurulduğunu görüyor ama can barı beklenenden az
      düşüyordu. Çözüm: `ServerValue.increment()` ile ATOMİK, göreli hasar
      uygulaması — artık hangi sırayla gelirse gelsin sunucu doğru toplar.
- [x] **DoT zamanlayıcıları raunt bittiğinde iptal edilmiyordu**: bir
      oyuncu zehir/yanma etkisiyle öldüğünde, geri kalan DoT tikleri
      (`Timer.periodic`) durdurulmuyordu — bu tikler bir SONRAKİ raundun
      taze can havuzuna sinsice hasar veriyor, hatta `_onKill()`'i tekrar
      tetikleyip raundu birden fazla ilerletebiliyordu. Çözüm: yeni raunt
      algılandığında (`_onFB`'de round numarası değişimi) tüm yerel
      zamanlayıcılar iptal ediliyor; ayrıca `_roundEnding` bayrağı ölüm
      işlemenin sadece bir kez olmasını garanti ediyor.
- [x] **Vuruş-yedim animasyonu hiç çalışmıyordu**: `_onFB` içinde
      `prevMyHp`, `_room` zaten YENİ veriyle değiştirildikten SONRA
      okunuyordu — yani "önceki" ve "yeni" değer her zaman aynıydı, bu da
      `myHp < prevMyHp` kontrolünün asla true olmamasına ve ekran
      sarsıntısı/haptic geri bildiriminin asla tetiklenmemesine yol
      açıyordu. `prevMyHp` artık `setState`'ten ÖNCE okunuyor.
- [x] **Kazanan/raunt belirleme artık senkron veriden**: ölüm algılama,
      saldıranın yerel (potansiyel olarak eski) tahmininden değil, her
      iki cihazın da gördüğü SENKRON HP verisinden yapılıyor; çifte
      yazmayı önlemek için raundu sadece kazanan taraf ilerletir (iki
      taraf aynı anda ölürse — double KO — deterministik olarak `p1`
      ilerletir ve raunt berabere sayılır, kimseye puan yazılmaz).
- [x] **Görsel "juice"**: HP barları artık `TweenAnimationBuilder` ile
      350ms'de yumuşak akıyor (önceden anında zıplıyordu); vuruş
      yediğimde ekranda kısa süreli kırmızı bir vinyet flaşı beliriyor.
- **Kapsam dışı bırakılanlar**: gerçek zamanlı 1v1'de teorik olarak
  mümkün ama son derece nadir bir "double KO" kenar durumu dışında,
  round/status geçişleri için ayrı bir Firebase transaction katmanı
  kurulmadı (mevcut deterministik "kazanan ilerletir" kuralı günlük
  oyunda yeterli); bu ortamda Flutter SDK yok, gerçek cihazda test
  edilemedi.

### 8.14 Hain Kim? + Vampir Köylü — parti oyunu güvenilirlik düzeltmeleri

Kullanıcının önceliklendirdiği 3. ve son oyun grubu: sosyal-tahmin parti
oyunları. İkisi de AYNI Firebase oda altyapısını paylaştığı için (kodun
kendi yorumunda da belirtildiği gibi) üç hata her ikisinde de birebir
aynı şekilde bulundu ve düzeltildi:

- [x] **Oda silinince ekran sonsuza dek donuyordu**: aktif oyun
      ekranındaki `_onFB`, gelen Firebase anlık görüntüsü `null` ise
      (host oyundan ayrılıp odayı sildiğinde, ya da bağlantısı
      koptuğunda) sessizce `return` ediyordu — diğer tüm oyuncular
      hiçbir geri bildirim almadan donmuş bir ekranda kalıyordu. Artık
      bu durumda herkes otomatik olarak ana menüye dönüyor.
- [x] **Oy/gece sayımı tek bir oyuncuya (`'p1'`) sabitlenmişti**: hem
      Hain Kim?'in oylama sonuçlanmasını hem Vampir Köylü'nün gece/gündüz
      çözümlemesini SADECE `myKey == 'p1'` olan cihaz yapıyordu. p1
      (genelde oda kurucusu) oyundan ayrılır ya da bağlantısı koparsa,
      oylama/gece asla sonuçlanmıyor, oyun kalıcı olarak kilitleniyordu.
      Artık bu sorumluluk, o an CANLI olan oyuncular arasından
      deterministik olarak en düşük anahtarlıya kayıyor — biri ayrılırsa
      görev otomatik olarak bir sonrakine geçiyor.
- [x] **Aktif oyun ekranında HİÇ çıkış yolu yoktu**: `PopScope` yok, geri
      butonu yok — bir oyuncu Android geri tuşuna basıp uygulamayı arka
      plana alsa bile Firebase kaydı silinmiyordu. Bu, "herkes oy versin/
      hazır olsun" bekleyen mantığı, uygulamayı arka planda bırakan TEK
      bir oyuncu yüzünden sonsuza dek kilitleyebiliyordu. Her iki oyuna da
      onay diyaloglu gerçek bir çıkış eklendi (kendini `players`'tan
      TAMAMEN kaldırır — bu, oy/hazır sayımını ve mürettebat/vampir
      oranını anında düzeltir, ayrıca çıkış anında kazanma koşulu da
      tekrar kontrol edilir).
- **Kapsam dışı bırakılan bilinen mimari sınırlama**: tüm oyuncuların
  rolü (`players/*/role`), Firebase Realtime Database'de TÜM istemcilerin
  aboneliğinde tuttuğu paylaşımlı oda düğümünde saklanıyor — yani
  teorik olarak, tarayıcı geliştirici araçları (özellikle şimdi eklenen
  Web sürümünde) veya ağ trafiği incelemesiyle bir oyuncu diğerlerinin
  gizli rolünü erken görebilir. Bunu tam olarak kapatmak, Firebase Auth +
  özel sunucu tarafı yetkilendirme (Cloud Functions) gerektiren ayrı,
  büyük bir altyapı projesi — bu oturumun kapsamının dışında bırakıldı;
  mevcut mimaride TÜM 30+ oyun aynı deseni paylaşıyor.

### 8.15 Araba Yarışı — senkron başlangıç, foto-finiş ve akıcı rakip hareketi

Kullanıcının önceliklendirdiği 3. oyun. Bulunan ve düzeltilen gerçek
hatalar:

- [x] **"3-2-1-GO" geri sayımı senkronize değildi**: her oyuncu, KENDİ
      ekranı ne zaman açılırsa açılsın bağımsız bir geri sayım
      başlatıyordu — ağ/navigasyon gecikmesi farkı yüzünden oyuncular
      gerçekte aynı anda başlamıyordu (biri diğerinden yüzlerce ms önce
      gaza basabiliyordu). Bu, tam olarak "rekabetsiz" hissinin bir
      kaynağıydı. Artık geri sayım, host'un yarışı başlattığı ANA
      (odaya yazılan `ServerValue.timestamp`) göre hesaplanıyor — TÜM
      oyuncuların "GO!" anı cihaz/ağ farkından bağımsız olarak aynı.
- [x] **Foto-finişte sıralama bozulabiliyordu**: yarışı bitiren oyuncu,
      sırasını KENDİ (potansiyel olarak eski) yerel `_room` verisinden
      okuyup hesaplıyor ve doğrudan `position`/`score` yazıyordu. İki
      oyuncu neredeyse aynı anda bitirirse, ikisi de birbirinin bitişini
      henüz görmemiş olabileceğinden AYNI ANDA "1. sıra" yazabiliyordu.
      Artık her oyuncu sadece sunucu zaman damgalı `finishedAt` yazıyor;
      gerçek sıralama, yarış bittiğinde TÜM zaman damgalarına göre
      türetiliyor — bu asla çakışmaz.
- [x] **Rakip arabalar ışınlanıyordu**: rakip pozisyonu doğrudan 10fps'lik
      Firebase senkron verisinden çiziliyordu, bu da arabaların her
      ~100ms'de bir yerinde "zıplaması"na yol açıyordu (yerel oyuncunun
      arabası 60fps'te akıcı hareket ederken). Artık rakip pozisyonları
      her fizik tikinde hedefe doğru üstel yumuşatmayla (lerp)
      render ediliyor — çok daha akıcı bir arcade hissi.
- [x] **Aktif yarışta hiç çıkış yolu yoktu**: diğer iki oyunla aynı sınıf
      hata — biri bitirmeden ayrılırsa (host odayı silerse de dahil),
      kalan oyuncuların ekranı donuyor ya da "herkes bitirsin" kontrolü
      hiç tetiklenmiyordu. Aynı `PopScope` + onaylı çıkış deseni ve
      null-snapshot → ana menüye dönüş düzeltmesi buraya da eklendi.

### 8.16 Mini Golf + Serbest Vuruş — aynı sınıf güvenilirlik düzeltmeleri

Kullanıcının seçtiği fizik tabanlı spor oyunları. Beklendiği gibi, diğer
gerçek zamanlı oyunlarla aynı mimari kalıptan gelen tanıdık hatalar
bulundu:

- [x] **Golf — oda silinince donma**: `_onFirebase`, null snapshot'ta
      sessizce dönüyordu; artık ana menüye yönlendiriyor.
- [x] **Golf — delik ilerletme sadece `'p1'`e (host) bağlıydı**: host
      kendi deliğini bitirip ayrılırsa, kalan oyuncular bitirse bile
      hiç kimse "sıradaki deliğe geç" kontrolünü tetiklemiyor, oyun
      "Diğerleri bekleniyor..." ekranında sonsuza dek takılı kalıyordu.
      `_hostAdvance()` zaten canlı veriyi tazeden okuyup kendi kendini
      koruduğu (hepsi bitmemişse hiçbir şey yapmaz) için, host kısıtlaması
      tamamen kaldırıldı — artık HERKES tetikleyebilir, güvenli ve
      idempotent.
- [x] **Golf + Serbest Vuruş — aktif oyunda hiç çıkış yolu yoktu**: aynı
      `PopScope` + onaylı çıkış deseni her ikisine de eklendi. Serbest
      Vuruş'ta ekstra bir incelik var: bu oyun tur-tabanlı olduğu için
      (sırası gelen oyuncunun fiziği tek otorite), sırası kendinde olan
      oyuncu ayrılmadan önce sırayı açıkça rakibe devrediyor — yoksa
      rakip "Rakibin vuruyor..." ekranında sonsuza dek beklerdi.
- **Not**: Serbest Vuruş'un top senkronizasyonu (task #66'da
  `ServerValue.increment` ile düzeltilmişti) zaten sağlamdı, bu oturumda
  sadece yukarıdaki iki eksik bulundu.

### 8.17 Kelime tabanlı oyunlar — Kelime Bulmaca, Şehir Bulmaca, Adam Asmaca

Kullanıcının seçtiği son oyun grubu. Her üçünde de null-snapshot donma
hatası bulundu; Kelime Bulmaca ve Adam Asmaca'da ayrıca çok daha ciddi,
oyunu doğrudan bozan hatalar vardı:

- [x] **Kelime Bulmaca — senkron olmayan süre erken kesiyordu**: her
      oyuncu KENDİ ekranı açıldığı anda bağımsız bir 60 saniyelik yerel
      sayaç başlatıyordu. Süresi ilk dolan oyuncu KAYITSIZ ŞARTSIZ
      `status:'finished'` yazıyordu — bu, ağ/navigasyon gecikmesi
      yüzünden henüz kendi süresi dolmamış diğer oyuncuların oyununu
      ERKEN KESİYORDU. Çözüm: geri sayım artık odanın paylaşılan
      `startTime` sunucu zaman damgasından hesaplanıyor (Araba
      Yarışı'ndaki gibi), bitiş de sadece "herkes bitirdi mi" kontrolüyle
      gerçekleşiyor (Golf'teki gibi) — artık kimse erken kesilmiyor.
      Ayrıca "Süren doldu, diğerleri bekleniyor..." bandı eklendi.
- [x] **Adam Asmaca — "Sonraki Tur" butonu misafir oyuncuda çalışmıyordu**:
      `_advanceRound()` eskiden `if (!_isHost) return;` ile SADECE p1'de
      işlev görüyordu. Ama buton HER İKİ oyuncuya da gösteriliyordu —
      p2 (tahminci) kendi "Sonraki Tur" butonuna bassa bile sessizce
      hiçbir şey olmuyordu, oyun sonuç ekranının arkasında sonsuza dek
      donuk kalıyordu (host kendi butonuna basana kadar). Bu, 2 kişilik
      bu oyunda HER TUR GEÇİŞİNDE karşılaşılan, her zaman tekrar eden bir
      hataydı. Çözüm: host kısıtlaması kaldırıldı, artık HERKES
      ilerletebiliyor — tazeden okunan round numarası dialogun
      gösterdiğinden farklıysa (başka oyuncu zaten ilerletmişse) hiçbir
      şey yapmadan çıkıyor, bu da çifte ilerlemeyi önlüyor.
- [x] **Üçünde de oda-silinme donması**: `_onFirebase`, null snapshot'ta
      sessizce dönüyordu; artık ana menüye yönlendiriyor.
- [x] **Üçünde de aktif oyunda çıkış yolu yoktu**: `PopScope` + onaylı
      çıkış eklendi. Adam Asmaca tam 2 kişilik olduğu için (sabit p1/p2
      rolleri), biri ayrılınca oda tamamen siliniyor; diğer ikisinde
      kalan oyuncularla devam ediliyor.
- **Kapsam dışı bırakılan düşük öncelikli not**: Şehir Bulmaca'da iki
  oyuncu aynı anda doğru cevap gönderirse çok dar bir zaman penceresinde
  bir raundun atlanması teorik olarak mümkün — ama bu oyunun "ilk doğru
  cevap turu kazanır" tasarımının doğal, nadir bir kenar durumu, ayrı bir
  transaction katmanı gerektirmeyecek kadar düşük etkili.

### 8.18 Profil "dashboard"u artık kullanıcının seçtiği rengi kullanıyor

Kullanıcı "Home ile Settings'teki renk aynı değil, bağımsız" diye şikayet
etti. İnceleme sonucu gerçek kaynağı bulundu: Home ekranı zaten
`Theme.of(context).colorScheme.primary` üzerinden Ayarlar'daki özel rengi
doğru kullanıyordu — ama Profil ekranının Bento-Grid "dashboard" tasarımı
(task #68) BİLEREK sabit bir indigo/mor palet kullanıyordu
(`DashTokens.indigo`), kullanıcının seçtiği renkten tamamen bağımsız.
Yani kullanıcı Ayarlar'dan turuncu/yeşil/her ne seçerse seçsin, Profil'in
seviye rozeti, XP çubuğu, "kilit açıldı" vurgusu, Play Games banner'ı ve
oyun çeşitliliği grafiği hep aynı mor kalıyordu.

- [x] `DashTokens`'a `accent(BuildContext)`/`accentSoft(BuildContext)`
      eklendi — `Theme.of(context).colorScheme.primary`'den türetiliyor.
      Semantik renkler (`emerald`=başarı, `amber`=uyarı/coin,
      `rose`=mağlubiyet) kasıtlı olarak SABİT bırakıldı — bunlar marka
      rengi değil, anlam taşıyor.
- [x] 6 dosyadaki 18 kullanım yeri (`profile_hero_card.dart`,
      `achievement_bento_tile.dart`, `play_games_banner.dart`,
      `game_variety_chart.dart`, `bento_card.dart`, `profile_screen.dart`)
      sabit `indigo`/`indigoSoft`'tan `accent`/`accentSoft`'a geçirildi.
      Eski sabitler, context'in olmadığı yerler için yedek olarak kaldı.
- **Not**: "Dahbors [dashboard] tasarımları berbat" için kullanıcı
  "hepsini" dedi (Profil, Home, Ayarlar, Liderlik) — bu oturumda somut,
  doğrulanmış renk-tutarsızlığı hatası düzeltildi; kapsamlı bir yeniden
  tasarım (layout/bilgi mimarisi) ayrı, daha büyük bir görev olarak
  bekliyor.

### 8.19 Gerçek AZOyun logosu: uygulama ikonu + Play Games başarım ikonu

Kullanıcı GitHub üzerinden gerçek AZOyun logosunu (`web/icon.jpg`, 512x512,
koyu mor-mavi-camgöbeği gradyan üzerinde beyaz "A"/kanat şekli) yükledi ve
"iconu da AZ oyun ikonu yap, uygulamamızın ikonunu da buna çevir" dedi.

- [x] Android launcher ikonları (5 yoğunluk: mdpi 48, hdpi 72, xhdpi 96,
      xxhdpi 144, xxxhdpi 192) gerçek logodan yeniden üretildi. Proje düz
      PNG kullanıyor (adaptive-icon XML/arka plan rengi yok), o yüzden tek
      katman yeterli.
- [x] iOS `AppIcon.appiconset` içindeki 15 boyutun tamamı (20pt'ten
      1024pt marketing ikonuna kadar, @1x/@2x/@3x) `Contents.json`'daki
      tam dosya adı eşlemesiyle yeniden üretildi.
- [x] Web ikonları yenilendi: `favicon.png` (16x16), `icons/Icon-192.png`,
      `icons/Icon-512.png`, `icons/Icon-maskable-192.png`,
      `icons/Icon-maskable-512.png` — dosya adları aynı kaldığı için
      `index.html`/`manifest.json` referanslarında değişiklik gerekmedi.
- [x] Play Games başarım içe aktarma zip'indeki `icon.png` (7 başarımın
      hepsi için ortak ikon) eski varsayılan Flutter logosu yerine gerçek
      AZOyun logosuyla değiştirildi, zip yeniden oluşturuldu.
- Üretim: bu ortamda Flutter SDK olmadığından (`flutter_launcher_icons`
  çalıştırılamıyor) Python/Pillow ile kaynak JPEG'den doğrudan
  `Image.resize(..., LANCZOS)` kullanılarak üretildi.
- **Not**: Bu sandbox'ta ikonları görsel olarak render edip doğrulayacak
  bir Flutter runtime yok — kullanıcının gerçek bir `flutter build`/
  `flutter run` ile veya deploy edilmiş web uygulamasında görsel kontrol
  yapması gerekiyor.

### 8.20 Kalan repo temizliği: `assets/sounds/` silinmesi + `.firebase/` cache

Kullanıcı GitHub üzerinden `assets/` klasörünü (kullanılmayan 8 ses
dosyası) sildi. Kontrol edildi: bu dosyalara `lib/` içinde hiçbir yerden
referans yoktu (grep ile doğrulandı), silme güvenliydi — ama
`pubspec.yaml` hâlâ var olmayan `assets/sounds/` klasörünü bildiriyordu,
bu da her `flutter build`/`flutter run`'ı kırardı.

- [x] `pubspec.yaml`'daki artık geçersiz `assets:` bloğu kaldırıldı.
- [x] Aynı GitHub yükleme commit'iyle yanlışlıkla repoya eklenen
      `.firebase/hosting.*.cache` (Firebase CLI'nin makineye özel yerel
      önbelleği, kaynak kod değil) `.gitignore`'a eklendi ve
      `git rm --cached` ile takipten çıkarıldı.

### 8.21 `bundleRelease` derleme hatası: google-services eklenti sürümü eski

Kullanıcı Windows'ta `flutter build appbundle` (Gradle `bundleRelease`)
çalıştırdı, şu hatayla düştü:

```
Could not create task ':app:uploadCrashlyticsMappingFileRelease'.
> The Crashlytics Gradle plugin 3 requires Google-Services 4.4.1 and above.
```

- **Kök neden**: `android/settings.gradle.kts` içinde
  `com.google.firebase.crashlytics` eklentisi `3.0.2` (plugin 3 ailesi)
  sabitliyken, `com.google.gms.google-services` hâlâ eski `4.3.15`
  sürümüne sabitti — plugin 3, en az `4.4.1` istiyor.
- [x] `com.google.gms.google-services` sürümü `4.4.2`'ye yükseltildi
      (`android/settings.gradle.kts:24`). Projede bu sürüm tek bir yerde
      tanımlı (Gradle plugins DSL üzerinden), başka bir dosyada
      tekrarlanan/çakışan bir sürüm yoktu.
- **Doğrulama**: Bu sandbox'ta Android SDK/Gradle yok, gerçek bir
  `bundleRelease` çalıştırılamıyor — kullanıcının kendi makinesinde
  tekrar denemesi gerekiyor.
