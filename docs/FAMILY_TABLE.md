# Aile Masası kurulumu

Güncel hesap durumu ve üretim kontrolleri [yayın kontrol dosyasında](RELEASE_CHECKLIST.md) tutulur. Kelime Tahtası ve Gizli Rol, oyuncuya özel API görünümüyle çalışır. **Masa → Aile Masası aç** menüsünden seçilir. Oyuncular QR veya **Masa → Kelime Tahtası / Gizli Rol → Odaya katıl** üzerinden bağlanır. Üretimde bu API Firebase Cloud Functions üzerinden sunulur.

## Firebase üzerinden ortak ekran

Android TV’de **AZOyun**, telefonda veya tablette **Masa → Aile Masası aç** menüsünü aç. Buradan **101 Okey**, **Klasik Okey**, **Pişti**, **Batak** veya **Mahalleler** seç. Masadaki QR kodunu oyuncular telefonlarından **Masa → QR ile odaya katıl** ile okutur. İlgili lobiye altı karakterli kod da girilebilir.

Bu oyunlar mevcut Firebase Realtime Database projesini kullanır. Ortak ekran için ayrı adres girişi gerekmez. Telefon lobisinden oda açan kişi de oyuncu olur. TV modunda Okey’e dört, Mahalleler’e iki ile dört oyuncu telefonla katılır.

Yeni Okey masalarında ortak ekran ve oyuncu telefonları güncel AZOyun sürümünü kullanmalı.

## İhaleli Batak masası

**Masa → Batak** ile telefondan oda açılabilir. Ortak ekran menüsündeki Batak odasına dört oyuncu telefonlarından katılır. Her oyuncuya rastgele 13 kart dağıtılır. İhale en az 5 ile açılır. Pas diyen tekrar teklif veremez. Herkes pas derse dağıtıcının sağındaki ilk oyuncuya 4 kalır. İhaleci kozu seçer ve eli açar. Renge uyulur ve mümkünse yerdeki kart büyütülür. O renk yoksa koz atılır ve mümkünse koz büyütülür. El kozla kesilmişse renge uymak yeterlidir. Koz kırılana kadar diğer renklerle açılır. Elde yalnızca koz kalmışsa kozla açılabilir.

Oynanabilir kartlar aydınlık görünür. Kartı dokunarak veya masaya sürükleyerek oyna. Dört kart masada kısa süre kalır. Kazanan oyuncunun telefonu eli otomatik toplar ve sonraki eli o oyuncu açar. Otomatik ilerleme aksarsa **Eli topla ve devam et** düğmesi kullanılabilir. Son el ayrıca açılır bölümden görülebilir.

İhaleci hedefini tutturamazsa ihale kadar eksi alır. Diğer oyuncular hiç el alamazsa aynı cezayı alır. Başarılı oyuncular aldıkları el sayısı kadar puan kazanır. Bu sürümde aile maçı dört dağıtım sürer. Herkes bir kez dağıtıcı olur. En yüksek puan eşitse galibiyet paylaşılır. Yazboz her dağıtımın el sayılarını ve puanlarını saklar.

İhale ve zorunlu kart kuralları için oyun işletmecisinin açıklaması incelendi. Dört dağıtımlık maç ve eşitlikte ortak galibiyet bu uygulamanın masa ayarlarıdır. [Joker Games Batak kuralları](https://joker.games/support-center/ihaleli-batak-oyun-kurallari/)

Firebase oda işlemleri diğer kart oyunlarıyla aynı projeyi kullanır. Aynı cihazdan oda kodunu yeniden girince mevcut koltuk ve kartlar korunur. Katılımın yeniden denenmesi ikinci bir koltuk ayırmaz. Uygulamanın yerel verileri silinirse cihaz kimliği de silinir. Canlı dört telefon ve Android TV kumandası doğrulaması bekliyor.

Aşağıdaki HTTPS ayarları eski tarayıcı masası içindir.

## Ev ağında tarayıcıyla

1. Proje dizininde `node scripts/build-web.mjs` çalıştır. HTML, CSS ve JavaScript salonu `build/salon` dizinine hazırlanır.
2. `node family-server/server.mjs` ile masayı aç. Node.js 22 veya daha yeni bir sürüm kullan.
3. Bilgisayar, akıllı TV tarayıcısı veya TV’ye bağlı bilgisayarda `http://BILGISAYAR_IP:8780/?family=tv` adresini aç. QR’ın telefonda çalışması için sunucunun yerel ağ IP’sini kullan. `localhost` yalnızca aynı bilgisayardaki denemeler içindir. TV, telefonlar ve sunucu aynı ağda olmalı. Gerekirse Windows güvenlik duvarında özel ağ için TCP 8780’e izin ver.
4. TV'de oyunu seç. Oyuncular QR kodunu okutup tarayıcıdan adlarını yazsın. TV'de **Başlat** düğmesine bas.
5. TV ortak masayı gösterir. Oyuncular taş çekme, taş atma, zar atma, alım ve teklif gibi hamleleri telefonlarından yapar. Telefon sayfası yeniden açılırsa aynı tarayıcıdaki oturumla koltuğu geri yükler.

## Eski Flutter web masası

Tarayıcıdaki eski Mahalleler masası varsayılan API adresini `https://azoyun.web.app/salon/family-api.json` üzerinden okuyabilir. Eski mağaza sürümlerinde adres **Sunucu ayarı** alanına elle girilebilir. Bu yolu test ederken `FAMILY_API_URL` ile API adresi ve gerekirse `FAMILY_WEB_URL` ile QR’ın web adresi seçilir.

Geliştirici Android emülatöründe `flutter build apk --debug --dart-define=FAMILY_API_URL=http://10.0.2.2:8780 --dart-define=FAMILY_WEB_URL=http://BILGISAYAR_IP:8780` kullanabilir. Release uygulamasında sunucu için HTTPS kullan. iPhone ve iPad'de Flutter web katılımı tarayıcıdan yapılabilir.

## Yayın ve test

- `node --test family-server/server.test.mjs` sunucu ve çok istemcili API testlerini çalıştırır. `flutter test` uygulama testlerini çalıştırır.
- Web salonu çıktısı hazırken `docker build -f family-server/Dockerfile -t azoyun-family .` komutuyla sunucu ve web'i tek pakete al. Varsayılan port 8780. `PORT` ile değiştirilebilir.
- İnternetten erişim için HTTPS altında tek sunucu örneği kullan. `FAMILY_STATE_FILE` ve `PROGRESSION_STATE_FILE` için kalıcı, yazılabilir bir dizinde iki ayrı dosya seç. Ayar verilmezse ilgili veriler bellekte tutulur ve yeniden başlatmada kaybolur.
- Son oyuncunun bağlantısı koptuğunda masa iki dakika boyunca yeniden bağlanmaya açık kalır. Sonuç ekranı bir dakika sonra silinir. TV ve izleyiciler oyuncusu kalmayan masanın ömrünü uzatmaz. Açık odalar için sekiz saatlik üst sınır vardır.
- Salonun **Oyuncu profili ve sıralama** bölümünden profil oluştur. Bir maçı bitirince 1 XP, kazanınca 3 XP kazanılır. Günde ilk 10 tamamlanmış maç XP verir. Her 20 XP bir seviye kazandırır. Profil anahtarı, aynı sunucuda başka bir tarayıcıdan profili açmak veya mobil Aile Masası’na bağlamak için kullanılır. Anahtarı güvenli sakla.
- Yerel Docker geliştirmesinde Firebase Hosting ayrı kalabilir; `FAMILY_API_URL` ve `FAMILY_WEB_URL` değişkenleri yalnızca bu özel geliştirme sunucusu için kullanılır. Üretimde Aile Masası Cloud Functions ve Realtime Database'i kullanır.
- Okey dört oyuncuyla, Mahalleler iki ila dört oyuncuyla başlar. Klasik Okey tek el ve yedi çift bitişi içerir. 101 tek el oynanır. İlk açılış 101 puan veya beş çifttir ve daha sonra masaya taş işlenebilir. Mahalleler on turda veya bir oyuncu ayakta kalınca sona erer.

Samsung Tizen ve LG webOS için giriş, JavaScript modülleri ve Fetch API destekleyen cihaz tarayıcısından veya TV’ye bağlı bir bilgisayardan yapılır. Android TV için yerel başlatıcı girişi de bulunur. Google Play TV dağıtımı için Play Console’da Android TV form faktörüne katılım ve TV kalite incelemesi gerekir.

### Firebase'de Aile Masası API'sini yayınlama

Ayrı VPS gerekmez. Oda ve profil verileri Firebase Realtime Database'de tutulur; `family-server` içindeki Firebase Function hamleleri ve oyuncuya özel görünümü yönetir. Firebase Hosting, `/api/**` isteklerini aynı Firebase projesindeki işleve yönlendirir. Web ve uygulama `azoyun.web.app` adresini kullanır; `FAMILY_API_URL` tanımlamak gerekmez.

1. Cloud Functions yayını için Firebase projesi Blaze planında olmalı ve bir faturalandırma hesabı bağlı olmalı. Spark planında Functions dağıtılamaz. Ücretsiz kullanım sınırları vardır; sınırlar aşılırsa ücret doğabilir. Firebase Console'da bütçe uyarısı kur.
2. Yayına izin verildikten sonra GitHub deposunun **Settings → Secrets and variables → Actions → Variables** bölümünde `FAMILY_FUNCTIONS_DEPLOY_ENABLED=true` değişkenini oluştur.
3. `main` dalındaki Firebase web yayını iş akışı `familyApi` ve `cleanupFamilyRooms` işlevlerini, ardından Hosting dosyalarını yayınlar. `https://azoyun.web.app/api/family/health` adresi `{"ok":true}` döndürmeli.
4. Realtime Database güvenlik kurallarında `family_api` verilerinin istemci SDK'sından doğrudan okunup yazılmadığını doğrula. Bu alan özel rol, el ve oyuncu anahtarı verileri içerir; istemci doğrudan erişmemeli. Mevcut kuralları görmeden tüm veritabanı kurallarını değiştirme.
5. Google TV'de Kelime Tahtası veya Gizli Rol aç; farklı telefonlarla QR/kod üzerinden katıl. Gizli rol ve harflerin diğer oyunculara görünmediğini, kopup yeniden bağlanınca oyuncu koltuğunun korunduğunu, sonuç ve rövanşın doğru çalıştığını doğrula.

### Chromecast with Google TV HD

Play Console’da **Gelişmiş ayarlar → Form faktörleri → Android TV** ekle. Android TV ekran görüntüsü ve TV banner’ını mağaza sayfasına koy. TV destekli AAB yükle ve inceleme durumunu kontrol et. Cihaz hâlâ uyumsuz görünürse **Cihaz Kataloğu**’nda Chromecast HD ve RK3326 için sürüm, cihaz dışlama ve manifest filtrelerinin gösterdiği nedeni ayrı kontrol et. Android TV sürümünde 32/64 bit ABI ve 16 KB sayfa uyumu da doğrulanmalı. [Android TV dağıtımı](https://developer.android.com/training/tv/publishing/distribute) · [Android TV kalite kriterleri](https://developer.android.com/develop/adaptive-apps/quality-guidelines/tv-app-quality)
