# Aile Masası kurulumu

## Ev ağında tarayıcıyla

1. Proje dizininde `flutter pub get` ve `flutter build web --release` çalıştır.
2. `node family-server/server.mjs` ile masayı aç. Node.js 22 veya daha yeni bir sürüm kullan.
3. TV veya TV'ye bağlı bilgisayarda `http://BILGISAYAR_IP:8780/?family=tv` adresini aç. IP, sunucuyu çalıştıran bilgisayarın yerel ağ adresi olmalı. Telefon ve TV aynı ağda olmalı.
4. TV'de oyunu seç. Oyuncular QR kodunu okutup tarayıcıdan adlarını yazsın. TV'de **Başlat** düğmesine bas.
5. TV ortak masayı gösterir. Oyuncular taş çekme, taş atma, zar atma, alım ve teklif gibi hamleleri telefonlarından yapar. Telefon sayfası yeniden açılırsa aynı tarayıcıdaki oturumla koltuğu geri yükler.

## Android TV, telefon ve tablet

Android TV ana ekranındaki **AZOyun** simgesi doğrudan Aile Masası'nı açar. Menüde yön tuşları ve OK kullanılır. Telefon veya tablette **Masa → Aile Masası aç** ya da **Aile Masası’na katıl** seçilir. Kurulumda sunucunun HTTPS adresi girilebilir. Bir yayın için APK ve AAB'yi `--dart-define=FAMILY_API_URL=https://masa.ornek.com` ile oluştur. QR başka bir web adresine gidecekse ayrıca `--dart-define=FAMILY_WEB_URL=https://oyun.ornek.com` ekle.

Geliştirici Android emülatöründe `flutter build apk --debug --dart-define=FAMILY_API_URL=http://10.0.2.2:8780 --dart-define=FAMILY_WEB_URL=http://BILGISAYAR_IP:8780` kullanabilir. Release uygulamasında sunucu için HTTPS kullan. iPhone ve iPad'de Flutter web katılımı tarayıcıdan yapılabilir.

## Yayın ve test

- `node --test family-server/server.test.mjs` sunucu ve çok istemcili API testlerini çalıştırır. `flutter test` uygulama testlerini çalıştırır.
- Flutter web çıktısı hazırken `docker build -f family-server/Dockerfile -t azoyun-family .` komutuyla sunucu ve web'i tek pakete al. Varsayılan port 8780. `PORT` ile değiştirilebilir.
- İnternetten erişim için HTTPS altında tek sunucu örneği kullan. `FAMILY_STATE_FILE` değişkenini kalıcı, yazılabilir bir dizindeki dosyaya ayarla. Bu ayar kapalıyken odalar sunucu belleğinde tutulur ve yeniden başlatmada kapanır. Odalar sekiz saat işlem görmezse sona erer.
- Firebase Hosting ayrı kalacaksa GitHub depo değişkeni `FAMILY_API_URL` ile HTTPS sunucu adresini ve `FAMILY_WEB_URL` ile QR adresini tanımla. Sunucuda `FAMILY_ORIGINS` değişkenine izin verilen web adreslerini virgülle ayırarak gir. Eski Firebase oda yapısı Aile Masası'nın gizli verileri için kullanılmaz.
- Okey dört oyuncuyla, Mahalleler iki ila dört oyuncuyla başlar. Klasik Okey tek el ve yedi çift bitişi içerir. 101 tek el oynanır. İlk açılış 101 puan veya beş çifttir ve daha sonra masaya taş işlenebilir. Mahalleler on turda veya bir oyuncu ayakta kalınca sona erer.

Samsung Tizen ve LG webOS için giriş, cihazın Flutter web uygulamasını açabilen tarayıcısına veya TV'ye bağlı bir bilgisayara dayanır. Android TV için yerel başlatıcı girişi bulunur.
