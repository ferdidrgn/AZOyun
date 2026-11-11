# Aile Masası kurulumu

## Ev ağında tarayıcıyla

1. Proje dizininde `node scripts/build-web.mjs` çalıştır. HTML, CSS ve JavaScript salonu `build/salon` dizinine hazırlanır.
2. `node family-server/server.mjs` ile masayı aç. Node.js 22 veya daha yeni bir sürüm kullan.
3. Bilgisayar, akıllı TV tarayıcısı veya TV’ye bağlı bilgisayarda `http://BILGISAYAR_IP:8780/?family=tv` adresini aç. QR’ın telefonda çalışması için sunucunun yerel ağ IP’sini kullan. `localhost` yalnızca aynı bilgisayardaki denemeler içindir. TV, telefonlar ve sunucu aynı ağda olmalı. Gerekirse Windows güvenlik duvarında özel ağ için TCP 8780’e izin ver.
4. TV'de oyunu seç. Oyuncular QR kodunu okutup tarayıcıdan adlarını yazsın. TV'de **Başlat** düğmesine bas.
5. TV ortak masayı gösterir. Oyuncular taş çekme, taş atma, zar atma, alım ve teklif gibi hamleleri telefonlarından yapar. Telefon sayfası yeniden açılırsa aynı tarayıcıdaki oturumla koltuğu geri yükler.

## Android TV, telefon ve tablet

Android TV ana ekranındaki **AZOyun** simgesi doğrudan Aile Masası'nı açar. Menüde yön tuşları ve OK kullanılır. Telefon veya tablette **Masa → Aile Masası aç** ya da **Aile Masası’na katıl** seçilir. Kurulumda sunucunun HTTPS adresi girilebilir. Bir yayın için APK ve AAB'yi `--dart-define=FAMILY_API_URL=https://masa.ornek.com` ile oluştur. QR başka bir web adresine gidecekse ayrıca `--dart-define=FAMILY_WEB_URL=https://oyun.ornek.com` ekle.

Geliştirici Android emülatöründe `flutter build apk --debug --dart-define=FAMILY_API_URL=http://10.0.2.2:8780 --dart-define=FAMILY_WEB_URL=http://BILGISAYAR_IP:8780` kullanabilir. Release uygulamasında sunucu için HTTPS kullan. iPhone ve iPad'de Flutter web katılımı tarayıcıdan yapılabilir.

## Yayın ve test

- `node --test family-server/server.test.mjs` sunucu ve çok istemcili API testlerini çalıştırır. `flutter test` uygulama testlerini çalıştırır.
- Web salonu çıktısı hazırken `docker build -f family-server/Dockerfile -t azoyun-family .` komutuyla sunucu ve web'i tek pakete al. Varsayılan port 8780. `PORT` ile değiştirilebilir.
- İnternetten erişim için HTTPS altında tek sunucu örneği kullan. `FAMILY_STATE_FILE` ve `PROGRESSION_STATE_FILE` için kalıcı, yazılabilir bir dizinde iki ayrı dosya seç. Ayar verilmezse ilgili veriler bellekte tutulur ve yeniden başlatmada kaybolur.
- Son oyuncunun bağlantısı koptuğunda masa iki dakika boyunca yeniden bağlanmaya açık kalır. Sonuç ekranı bir dakika sonra silinir. TV ve izleyiciler oyuncusu kalmayan masanın ömrünü uzatmaz. Açık odalar için sekiz saatlik üst sınır vardır.
- Salonun **Oyuncu profili ve sıralama** bölümünden profil oluştur. Bir maçı bitirince 1 XP, kazanınca 3 XP kazanılır. Günde ilk 10 tamamlanmış maç XP verir. Her 20 XP bir seviye kazandırır. Profil anahtarı, aynı sunucuda başka bir tarayıcıdan profili açmak veya mobil Aile Masası’na bağlamak için kullanılır. Anahtarı güvenli sakla.
- Firebase Hosting ayrı kalacaksa GitHub depo değişkeni `FAMILY_API_URL` ile HTTPS sunucu adresini ve `FAMILY_WEB_URL` ile QR adresini tanımla. Sunucuda `FAMILY_ORIGINS` değişkenine izin verilen web adreslerini virgülle ayırarak gir. Eski Firebase oda yapısı Aile Masası'nın gizli verileri için kullanılmaz.
- Okey dört oyuncuyla, Mahalleler iki ila dört oyuncuyla başlar. Klasik Okey tek el ve yedi çift bitişi içerir. 101 tek el oynanır. İlk açılış 101 puan veya beş çifttir ve daha sonra masaya taş işlenebilir. Mahalleler on turda veya bir oyuncu ayakta kalınca sona erer.

Samsung Tizen ve LG webOS için giriş, JavaScript modülleri ve Fetch API destekleyen cihaz tarayıcısından veya TV’ye bağlı bir bilgisayardan yapılır. Android TV için yerel başlatıcı girişi de bulunur. Google Play TV dağıtımı için Play Console’da Android TV form faktörüne katılım ve TV kalite incelemesi gerekir.
