# AZ Oyun — Yol Haritası

Bu doküman AZ Oyun'u "arkadaşlarla eğlenmek için basit, çok oyunculu oyun
koleksiyonu" vizyonuna göre nasıl büyüteceğimizi anlatır. Hedef: **çok kazanmak
değil, insanları eğlendirmek — az ve dürüst bir gelir modeliyle sürdürülebilir
kalmak.**

## 1. Şu an elimizde ne var?

Proje zaten olgun bir temele sahip:

- **11 online oda-tabanlı oyun** (Firebase Realtime Database, 6 haneli oda
  kodu ile arkadaş davet etme): Mini Golf, Serbest Vuruş (futbol), Araba
  Yarışı, Adam Asmaca, Şehir Bulmaca, Kelime Bulmaca, Okey, Okey 101, Dama,
  Dövüşçüler, Vampir Köylü, Yalancılar Kahvesi.
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
18. Flappy tarzı "Zıpla Geç" — gelecek
19. Kayan Yapboz (15-puzzle) ✅ *seçildi (Faz 2)*
20. Renk Eşleştir / Simon Says hafıza dizisi — gelecek
21. Meyve Kesme tarzı dokunma oyunu — gelecek

### D) 3D / fizik tabanlı (orta-uzun vadeli, Flame/Forge3D veya basit 3D gerektirir)
22. 3D Bowling (mini bovling) — gelecek
23. 3D Air Hockey — gelecek
24. Top Toplama / Labirent (tilt/dokunma kontrollü 3D top) — gelecek
25. Basit araba park etme (3D perspektif) — gelecek

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
