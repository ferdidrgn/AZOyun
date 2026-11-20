# AZOyun yayın ve gerçek cihaz kontrolü

Bu dosya 20 Kasım 2026 tarihinde kontrol edilen hesap durumunu ve cihazda tamamlanacak adımları saklar. Yerel kural testi, mağazadan kurulum ve fiziksel TV testi ayrı sonuçlardır.

## Mevcut hesap durumu

- Firebase projesi `azoyun-569b2`. Console proje özetinde Spark planı, Functions ekranında ilk yayının beklendiği görüldü. Zamanlanmış temizlik için Blaze planı ve faturalandırma gerekir. Üretimde temizlik fonksiyonu henüz doğrulanmadı.
- Play Games projesi `517819561284`. Saved Games etkin ve yayınlanmış. Android kimlik bilgisinin paket adı `com.ferdidrgn.azgame` ve durumu yayınlanmış.
- `Total XP` tablosu `CgkIxOrNg4kPEAIQEA` kimliğiyle yayınlandı. Sayı biçimi tam sayı, sıralaması büyükten küçüğe. Play Games yayın ekranında işlemin ardından yayınlanacak değişiklik kalmadığı görüldü. Cihazda skor gönderme ve listeyi açma testi bekliyor.
- Yedi mevcut başarım yayınlanmış. Uygulamanın `PlayGamesService` eşlemeleri Console'da görülen kimliklerle güncellendi. `hundred_games` ve `ten_game_types` için yeni kayıtların tamamlanması bekliyor.
- Yerel `gh auth status` geçersiz GitHub oturumu bildirdi. GitHub bağlantısı okuma yapabildi, yeni Git ağacı ve dal yazımlarını HTTP 403 ile reddetti. Main'e gönderme bu erişim sorunu çözülmeden tamamlandı sayılmamalı.

## HTTPS Aile Masası

Klasik Okey, 101, Pişti, Batak ve mobil Mahalleler Firebase Realtime Database odalarını kullanır. Kelime Tahtası, Gizli Rol ve tarayıcı masası, telefonlara özel veri gönderen `family-server` API'sini kullanır.

1. `docs/FAMILY_TABLE.md` içindeki Docker Compose adımlarıyla kalıcı diski ve HTTPS'i olan tek sunucu örneğini yayınla. Örnek alan adını gerçek alan adıyla değiştir.
2. PowerShell'de `Invoke-RestMethod https://GERCEK-ALAN-ADI/api/family/health` çalıştır. Sonuçta `ok` alanı `true` olmalı. HTML dönüyorsa o adreste API çalışmıyordur.
3. GitHub deposunda **Settings → Secrets and variables → Actions → Variables → New repository variable** yolundan `FAMILY_API_URL` değişkenini yalnızca HTTPS kök adresiyle kaydet. Örneğin `https://masa.alanadiniz.com`. Sonuna `/api/family` ekleme.
4. **Actions → CI ve web yayını → Run workflow → main** çalıştır. `deploy` işi başarılı olmalı.
5. `https://azoyun.web.app/salon/family-api.json` dosyasında `origin` alanı gerçek API adresini göstermeli. Dosyayı tarayıcıda açarak kontrol et.
6. Mağazadaki eski sürümde **Sunucu ayarı** alanına aynı HTTPS adresini yaz. Oda kur, başka bir ağdaki telefonla QR veya kod üzerinden katıl. Yeni sürümde Kelime Tahtası ve Gizli Rol menüleri bulunur.
7. Sunucuyu yeniden başlat. Odanın, oyuncu koltuğunun ve profilin kalıcı dosyalardan geri geldiğini kontrol et.

## Firebase temizliği

Blaze etkinleştirildikten sonra **Actions → Firebase oda temizliğini yayınla → Run workflow** kullanılabilir. GitHub'daki mevcut `FIREBASE_SERVICE_ACCOUNT_AZOYUN` hesabının Functions, Scheduler ve ilgili dağıtım kaynakları için gereken yetkileri bulunmalı. İş akışı yetki hatası verirse hata mesajındaki izin yönetici hesabında düzeltilir.

Console → Functions içinde `sweepLegacyGameRooms` görünmeli. Cloud Scheduler işi beş dakikada bir çalışmalı. Deneme odasında tüm oyuncuları çıkar. On dakikalık boş oda toleransı ve sonraki tarama sonrasında oda silinmeli. Biten odalar iki saat korunur. Bir oyuncu geri dönerse boş oda süresi iptal olmalı. Canlı ve eski sürüm odalarının silinmediğini de doğrula.

## Android TV ve Cihaz Kataloğu

1. Play Console'da AZGame uygulamasını seç. **Gelişmiş ayarlar → Form faktörleri** altında Android TV'nin ekli ve inceleme sonucunun onaylı olduğunu kontrol et. Paneldeki arama kutusuna `Form faktörleri` yazılarak da bulunabilir.
2. Mağaza girişinde en az bir gerçek Android TV ekran görüntüsü ve TV banner'ı ekle. Uygulama açıklamasında Android TV desteğini anlat. Launcher banner'ı için 320×180 kaynak bulunmalı.
3. **İzleyin ve geliştirin → Erişim ve cihazlar → Cihaz kataloğu** yolunu aç. `Chromecast` ve `RK3326` aramalarını ayrı yap. Tam marka, cihaz kodu ve varyantı seç.
4. Cihazın **Desteklenmiyor** veya **Hariç tutuldu** gerekçesini, seçili AAB sürüm koduyla birlikte kaydet. `ABI`, zorunlu donanım, minimum Android sürümü ve elle/RAM/SoC kurallarıyla dışlama nedenlerini kontrol et. Donanımda 64 bit işlemci bulunması cihazın işletim sistemi ABI'sini tek başına belirlemez.
5. Yüklenen AAB'de hem `base/lib/armeabi-v7a/` hem `base/lib/arm64-v8a/` olmalı. ZIP aracıyla açıp her iki klasördeki `.so` dosyalarını incele. CI her iki ARM mimarisiyle AAB üretir.
6. AAB'den üretilen APK'yı Android Studio'da **Build → Analyze APK** ile aç. `lib` altındaki `.so` dosyalarının **Alignment** sütununda 16 KB uyarısı bulunmamalı. Paket hizalamasını ayrıca `bundletool dump config --bundle=app-release.aab` çıktısında `PAGE_ALIGNMENT_16K` ile kontrol et.
7. 16 KB sistem görüntülü Android emülatöründe `adb shell getconf PAGE_SIZE` sonucu `16384` olmalı. Uygulamayı burada da çalıştır. 4 KB kullanan bir TV'deki başarılı açılış 16 KB testinin yerine geçmez.
8. Fiziksel TV kumandasıyla yönler, OK ve Geri tuşlarını dene. Oyun seçimi, oda kurma, başlatma, sonuç, diyalog kapatma ve reklamdan çıkma akışlarında odak görünür olmalı. Telefon kumandası için QR'yı okut ve tam maç bitir.

[TV dağıtımı](https://developer.android.com/training/tv/publishing/distribute) · [TV kalite kuralları](https://developer.android.com/docs/quality-guidelines/tv-app-quality) · [Cihaz kataloğu](https://support.google.com/googleplay/android-developer/answer/7353455?hl=tr) · [16 KB kontrolü](https://developer.android.com/guide/practices/page-sizes)

## Dahili kanal ve iki cihazda Saved Games

1. Main'e gönderilen kod `1.0.0+21` AAB üretir. Varsayılan Play kanalı `internal`. Servis hesabının dahili sürüm yayınlama izni gerekir. Başarısız yüklemede imzalı AAB, Actions'ın `azoyun-signed-aab` çıktısından alınabilir.
2. Play Console → Dahili test bölümüne iki test hesabını ekle. Play Games → Test kullanıcıları altında da bu hesapların yetkili olduğunu doğrula.
3. Bir test cihazında temiz kurulum, diğerinde mevcut mağaza sürümünden yükseltme yap. Uygulama verilerini temizleme testini kişisel ana cihaz yerine test cihazında uygula.
4. Birinci cihazda Play Games'e bağlan. Maç bitirip XP, seviye ve başarımları kaydet. Profilde bulut eşitlemesinin tamamlandığını gör.
5. İkinci cihazda aynı Play Games hesabıyla giriş yap. XP, oynanan maçlar, rozetler ve seviye ilk cihazla eşleşmeli. İki cihazda ayrı maçlar bitirip senkronize et. Aynı maç sonucu iki kez XP vermemeli.
6. Play Games → Skor tabloları bölümünde yayınlanan Total XP tablosunun cihazda açıldığını doğrula. Kaydedilmiş oyunlar özelliği zaten etkin. Android kimlik bilgisindeki SHA-1, **Uygulama bütünlüğü → Play Uygulama İmzalama** sertifikasıyla eşleşmeli.
7. Play Games → Hedefler bölümünde Yüz Maç ve Oyun Gezgini başarımlarını tamamla. Üretilen gerçek kimlikleri `PGS_ACHIEVEMENT_HUNDRED_GAMES` ve `PGS_ACHIEVEMENT_TEN_GAME_TYPES` depo değişkenlerine yaz.
8. Üretim kanalını gerçek cihaz sonuçları tamamlandıktan sonra manuel iş akışında seç.

## Oyun test matrisi

| Alan | Kontroller | Mevcut durum |
| --- | --- | --- |
| Bütün çevrimiçi oyunlar | Kod, QR, dolu/kapalı oda, eşzamanlı katılım, zayıf ağ, Geri, arka plan, sonuç, rövanş | Otomatik testler var, her oyunun fiziksel cihaz turu bekliyor |
| Tekli oyunlar | Küçük ekran, büyük yazı, çevrimdışı açılış, duraklatma, tekrar deneme | Tam katalog cihaz turu bekliyor |
| Yeni aile oyunları | Gizli veri projeksiyonu, sekiz kişilik rol katılımı, kelime kuralları, oylar ve sonuç | 19 API/web testi süreç içi HTTP aktarımıyla geçti |
| Firebase odaları | Canlı oyuncuyu koruma, yeniden bağlanma, boş/biten oda ömrü | Beş politika testi geçti, üretim yayını bekliyor |
| Sahne motoru | Mini Golf kare süreleri, yarış/dövüşte ortak döngü ihtiyacı, Flame karşılaştırması | Düşük donanımlı fiziksel Android ölçümü bekliyor |
| Ortak UI | Lobiler, HUD, sonuç, profil, ayarlar, tekli oyunlar, açık/koyu tema | Ortak tema ve lobi bileşenleri var, bütün ekranların görsel turu bekliyor |
