# AZOyun oyun geliştirme ve ilerleme takibi

## EN YÜKSEK ÖNCELİK · Flutter Android + HTML/CSS/JS web dengesi

- [x] Mevcut dağıtım doğrulandı: Android uygulaması Flutter akışını, web yayını `web/` içindeki özel HTML/CSS/JS salonunu kullanıyor. GitHub Actions `main` push'unda `node scripts/build-web.mjs` çalıştırıp `build/salon` çıktısını Firebase Hosting'e dağıtıyor; Flutter Web derlemesi yapmıyor.
- [x] Tasarım kararı: Android oyunları Flutter içinde kalacak; web sitesi statik HTML/CSS/JS olarak kalacak. Flutter web uygulamasını siteye gömmek yerine ortak backend, oyun kimlikleri, katalog verisi ve kural/sonuç sözleşmeleri kullanılacak.
- [x] Sürüm `1.0.0+21` → `1.0.1+22` yükseltildi ve `b7ad599` commit'i `main`'e gönderildi.
- [x] Web yayını testi, kök sayfanın HTML/CSS/JS girişlerini kullanmasını ve Flutter bootstrap dosyalarını referans etmemesini kontrol edecek şekilde güçlendirildi.
- [x] `b7ad599` için HTML/CSS/JS web CI testi ve Firebase Hosting yayını başarılı oldu: [GitHub Actions](https://github.com/ferdidrgn/AZOyun/actions/runs/44858985585).
- [x] Android iş akışında Flutter testleri ve imzalı AAB üretimi geçti; AAB Actions artefaktına yüklendi. Google Play'e yükleme `The caller does not have permission` ile reddedildi: [GitHub Actions](https://github.com/ferdidrgn/AZOyun/actions/runs/44858985553).
- [x] İlk oyun motoru envanteri çıkarıldı: yedi Three.js oyun modu (`runway`, `drones`, `orbit`, `maze`, `bowling`, `freeKick`, `penalty`) Android Flutter ekranından ve aynı paketli JS motorundan açılıyor.
- [x] Aynı yedi Three.js modu için HTML/CSS oyun sayfaları ve katalog kartları eklendi. Sayfalar mevcut `arcade3d` motorunu açıyor; web reklamları Flutter/WebView içine değil, yalnızca dağıtım değişkeni açtığında web kabuğuna yükleniyor.
- [x] Dart hızlı oyunları, web klasiklerini, çevrimiçi Firebase oyunlarını ve ortak Three.js motorlarını istemci bazında sınıflandır: [GAME_CLIENT_MATRIX.md](docs/GAME_CLIENT_MATRIX.md).
- [x] Web'deki eski Penaltı/Frikik quiz kartlarını kaldır; önceki URL'leri aynı 3D arcade oyun sayfalarına bağla, katalogda aynı adlı çift oyun gösterme.
- [x] XOX için ortak JSON kural vektörleri oluştur; Dart ve JavaScript motorları kazanan çizgisi, galibiyet ve beraberlik sonuçlarını bu sözleşmeye göre hesaplıyor.
- [x] Nim başlangıç yığınları Android ve web'de `[3, 5, 7, 9]` olarak eşitlendi; taş alma sınırları ve son taşla bitiş için ortak geçerli/geçersiz hamle senaryoları eklendi.
- [x] Dörtlü Diz yatay/dikey/çapraz galibiyet ve sütundaki en alt boş yeri Flutter ve web'de ortak test vektörlerine bağlandı.
- [x] 2048 kaydırma/birleşme, puan, hamlesiz durum ve 2048 hedefine ulaşma kurallarını Android ve web'de ortak JSON vektörlerine bağla. Web yayını ve Android CI Flutter testleri geçti; imzalı AAB artefaktı oluştu. Play Console'a yükleme servis hesabı izninden reddedildi.
- [x] Yılan Android/web tahtasını 14×14, başlangıç konumunu ve elma başına 10 puanı eşitle; dönüş, duvar/kuyruk çarpışması ve kuyruğun boşalan hücresine girme kuralları için Dart/JavaScript ortak senaryoları ekle. Web yayını ve Android CI Flutter testleri geçti; AAB üretildi, Play yükleme izni mevcut hesapta başarısız oldu.
- [x] Balon Patlat'ta 20 saniyelik tur, 1,1 saniyelik balon süresi, başarılı dokunuş başına 1 puan ve tur bitince puan verilmeme kurallarını Android/web için ortak JSON senaryolarına bağla.
- [x] Maymun Dokunuşu'nda 3×3 hedef, 700 ms hedef hareketi, 20 saniyelik tur ve doğru dokunuşa 1 puanı Android/web için ortak senaryolara bağla.
- [x] Zıpla Geç web oynanışını mobildeki borulu uçuşa taşı; yerçekimi, zıplama, boru akışı, puan ve çarpışma sınırlarını ortak Dart/JavaScript senaryolarına bağla.
- [x] Scuba Sweep web hedef tıklaması mobildeki dalış sahnesiyle değiştirildi. Sola/sağa sürükleme, atık toplama, köpek balığı/balon balığı/denizanası çarpışması, inci kalkanı ve seviye hızları ortak Dart/JavaScript kural vektörlerine bağlandı.
- [x] Reversi'nin açılış hamleleri, taş çevirme, yasal hamle, zorunlu pas ve bitiş skoru Flutter ve web'de ortak kural modülü ile JSON senaryolarına taşındı.
- [x] Balon, Maymun Dokunuşu, Scuba ve Jump Dash zamanlı oyunlarının süre/puan vektörleri Flutter ve web ortak senaryolarına bağlandı; web CI ve Android Flutter testleri geçti.
- [ ] Aile Masası API'sinin ortak Android/web istemcilerinde manuel/QR katılım, eşzamanlı hamle, bağlantı geri dönüşü, sonuç ve rövanş senaryolarını uçtan uca doğrula.
- [x] Aile Masası ortak API'sine altı oyunculu oda sözleşme testi eklendi: katılım, özel rol bilgisinin korunması, bağlantı sonrası aynı koltuğa dönüş, revizyonlu gece/oylama hamleleri, sonuç ve yeni maç kimliğiyle rövanş CI'da denetleniyor. Mobil QR arayüzü ayrıca Flutter widget testinde doğrulanıyor.
- [x] İlk HTML/CSS oyun kabuğu içinde ortak Three.js motoru gömüldü. Gerçek reklam gösterimi `WEB_ADS_ENABLED` kapalıyken devre dışı kalır; açılınca reklam betiği web sayfasında çalışır.
- [x] CI ayrımı doğrulandı: Flutter Android test/AAB akışı `.github/workflows/play-store-deploy.yml`, statik HTML/CSS/JS CI/yayın akışı `.github/workflows/firebase-hosting-deploy.yml` içinde. Web derleyicisi yalnızca `web/` ile ortak arcade varlıklarını `build/salon` içine alır; Flutter Web üretimi yoktur.
- [ ] Android, web ve oda sunucusunu temsili oyunlarda aynı oda/hamle/sonuç senaryolarıyla doğrula; ardından diğer oyunlara dalgalar halinde yay.
- [x] `46fc3af` için web CI, yayın dosyası doğrulaması ve Firebase Hosting deploy'u başarılı: [GitHub Actions](https://github.com/ferdidrgn/AZOyun/actions/runs/44860597839). Windows'ta yerel entegrasyon testi localhost sunucusuna bağlanamadı (`EACCES 127.0.0.1`); aynı test GitHub Actions'ta geçti.
- [x] Eski Penaltı/Frikik katalog beklentisi düzeltilince `cb26726` web CI ve Firebase Hosting yayını başarıyla tamamlandı: [GitHub Actions](https://github.com/ferdidrgn/AZOyun/actions/runs/44868220304).
- [x] `9ac9fda` Android testleri/AAB iş akışı tamamlandı; Play'e yükleme adımı `The caller does not have permission` hatası verdi. Yeni ortak oyun değişiklikleri için sonraki Android CI bu akışı tekrar doğrulayacak: [GitHub Actions](https://github.com/ferdidrgn/AZOyun/actions/runs/44860486302).

## 21 Kasım 2026 · Tema, profil ve ayarlar

- [x] Uygulama genelindeki Material 3 renk paleti daha oyun odaklı, futuristik elektrik moru ve parlak semantik aksanlara geçirildi. Açık/koyu yüzeyler ile özel renk paleti merkezileştirildi.
- [x] Profil ve liderlik tablosunun sabit koyu renkleri kaldırıldı; kartlar, yazılar ve vurgular artık uygulamanın seçili temasını izliyor.
- [x] Lobi/Play yüzeyleri ortak Material 3 yüzey ve metin renklerine bağlandı. Oyun tahtalarının kendi oynanış renkleri korundu.
- [x] Ayarlarda seçili dil adı bütün mevcut diller için doğru gösteriliyor; bildirim izni durumu görünür, izin sonrası sistem ayarlarına yönlendirme ve uygulamaya dönünce durumu yenileme var. Play Games bağlantı durumu ekrana anlık yansıyor.
- [x] Gizlilik politikası ve kullanım şartları ekranlarının projede mevcut olduğu doğrulandı; tema metin görünümüne uygulanıyor.
- [x] Ana oyun kataloğundaki sabit eski yarış/zeka/dama/dövüş/sosyal kart gradyanları ortak oyun paletine bağlandı. Adam Asmaca lobi ve oda ekranları da aynı canlı kırmızı tema tokenlarını kullanıyor.
- [x] Adam Asmaca lobisi ortak AZOnlineLobby düzenine taşındı; ortak tema yüzeyi, oyuncu adı, oda oluşturma/katılma düğmeleri ve yükleme kilidi kullanılıyor. Ortak lobi düğmeleri erişilebilir dokunma yüksekliğine çıkarıldı.
- [x] Hain Kim, Vampir Köylü ve Kelime Bulmaca lobileri ortak Material 3 lobi düzenine taşındı; oda oluşturma/katılma mantığı, kayıtlı oyuncu adı ve banner reklamları korundu. Ortak lobiye 6 karakterlik davet kodu yardımı, klavyede gönder eylemi ve oyun seçenekleri için ekran okuyucu etiketi eklendi.
- [x] Pişti lobisi de aynı ortak düzene taşındı; Oyuncu/Ortak Masa seçimi tema uyumlu, kumandayla seçilebilir Material 3 segmented control olarak kaldı.
- [x] Dövüşçüler, Araba Yarışı, Dama, Şehir Bulmaca ve Yalancılar Kahvesi lobi ekranları ortak Material 3 AZOnlineLobby düzenine taşındı. Karakter/araba seçimleri odada korunup erişilebilir ChoiceChip’e çevrildi; banner alanı korundu.
- [x] Liderlik tablosu yükleme göstergesi seçili temanın rengini kullanıyor; oyun seçimi Material 3 ChoiceChip’e geçti ve klavye/kumanda odağı aldı.
- [x] Ortak lobi/oda eylemlerinde Android TV kumandasının başlangıç odağını oluştur/başlat düğmesine taşı; oda başlatma hedefini en az 56 dp yap.
- [ ] Oyun dışı sayfaların kalan sabit renk ve yazı stillerini tek tek gözden geçir; ortak lobby/HUD/sonuç/tekli oyun yüzeylerini aynı tasarım sistemine taşı.
- [ ] Telefon ve TV’de açık/koyu tema, büyük yazı, erişilebilir dokunma hedefleri ve kumandayla gezinmeyi gerçek cihaz/emülatörde doğrula.
- [ ] Play Games’i Play Console’daki `com.ferdidrgn.azgame` kaydı ve Play App Signing SHA-1 ile eşleştir; mağaza test kanalında giriş ve Saved Games geri yüklemeyi doğrula. Hesap/sertifika ayarına henüz erişilmedi.
- [ ] Mobile Design becerisi için istenen `npx claude-code-templates@latest --skill creative-design/mobile-design` kurulumunu ağ/DNS erişimi düzeldiğinde tamamla ve kurulu `SKILL.md` ile zorunlu referanslarını oku. Bu oturumda DNS çözümlemesi başarısız oldu.

## 21 Kasım 2026 · Akıllı saat / Wear OS araştırması

- [x] Resmî Android ve Google Play kaynakları araştırıldı. AZOyun için ilk hedef Wear OS saat; küçük ekranda tam masa oyunu yerine aktif oda özeti, oyuncu sayısı, sıra bilgisi ve kısa titreşimli bildirimler öneriliyor. [Wear tasarım kılavuzu](https://developer.android.com/design/ui/wear/guides/get-started/design-for-wearables) · [Wear OS arayüzleri](https://developer.android.com/training/wearables/user-interfaces)
- [x] Oda mantığının tek sahibi Firebase Realtime Database ve mevcut `RoomService` olacak. Bağlantı: Firebase oda olayı (oyuncu katıldı / oda başladı / sıra değişti / maç bitti) → telefondaki mevcut oda akışı → güvenli ve kısa Wear OS durumu/bildirimi → saat ekranı ve titreşim. Saatteki bir eylem → eşlenmiş telefon → mevcut oda/hamle doğrulaması ve Firebase işlemi. Saatte ikinci bir oyun kuralı veya bağımsız oda gerçeği tutulmayacak.
- [x] Veri yolları ayrıştırıldı: FCM ve mevcut `NotificationCompat` bildirimleri bulut kaynaklı davet/olaylar için; eşlenmiş Android telefon ile Wear OS saat arasındaki kısa durum ve uzaktan eylemler için Wearable Data Layer. Data Layer internet/backend yerine kullanılmayacak ve iPhone eşlemesiyle çalıştığı varsayılmayacak. [Data Layer sınırları](https://developer.android.com/training/wearables/data/overview) · [Wear bildirimleri](https://developer.android.com/training/wearables/notifications)
- [x] Uygulama yapısı araştırıldı: mevcut Flutter Android projesinde Wear OS’a özel arayüz için küçük bir yerel Kotlin + Compose for Wear OS modülü gerekir; Wear Compose saat arayüzleri için Google’ın önerdiği araç takımıdır. [Flutter–Android köprüsü](https://docs.flutter.dev/platform-integration/android/call-jetpack-apis) · [Compose for Wear OS](https://developer.android.com/training/wearables/compose)
- [x] Telefon tarafında Wear köprüsünün ilk güvenli dilimi eklendi: Firebase oda akışı yalnızca oyun adı, davet kodu, durum ve oyuncu sayısını whitelisted özet olarak aktarır; el/rol/hedef/oyuncu kimliği aktarılmaz. Oda özeti değişmediğinde gönderim yinelenmez, erişilebilir Wear uygulaması yoksa oda akışı etkilenmez.
- [x] Telefon köprüsü için Flutter testleri ve 58.3 MB imzalı AAB üretimi geçti; [Actions](https://github.com/ferdidrgn/AZOyun/actions/runs/44939471451). Google Play’e son yükleme servis hesabının `The caller does not have permission` hatasıyla reddedildi.
- [ ] Bu telefon köprüsünü tamamlamak için Compose for Wear OS saat uygulamasını, `azoyun_wear_app` capability tanımını ve saatten telefon/oyun açma akışını ekle; saat emülatörü ve gerçek saat testlerini yap.
- [ ] MVP kapsamını sabitle: etkin oda/oyun adı, oda kodu ve doluluk; oyuncu katıldı/oyun başladı/sıra sende olaylarında kısa bildirim ve titreşim; saatten telefonu veya ilgili oyunu açma. Okey taşı/kart hamlesi gibi tam oyun kontrolleri ilk sürüme alınmayacak.
- [ ] Firebase oda akışlarında ortak olay sözleşmesini tanımla: `roomCreated`, `playerJoined`, `roomStarted`, `turnChanged`, `roomFinished`. Her oyun kendi mevcut kural servisini kullanmalı; saat yalnızca gerekli oyuncu/oda özetini görmeli, gizli el/rol/hedef verisi taşımamalı.
- [ ] Android modülleri arasında Wear OS modülünü ve telefondaki Flutter uygulamasına ince bir platform köprüsünü kur. `CapabilityClient` ile eşli saatte uygulamanın bulunmasını algıla; yalnızca etkin oda özetini ve telefon açma/izinli hızlı eylem isteklerini aktar. Hızlı eylemleri telefon tarafında mevcut Firebase transaction ve sıra/koltuk doğrulamasından geçir.
- [ ] Wear OS bildirimlerinde yinelenmeyi önle. Oda daveti ve arka plan olaylarını FCM’den; uygulama aktifken değişen oda özetini Data Layer veya mevcut Firebase akışından göster. Bağlantı kopunca eski durumu açıkça işaretle; yeniden bağlanmada Firebase’den güncel durumu al.
- [ ] Wear OS emülatöründe eşleme, uygulama algılama, oda katılımı, sıra bildirimi, titreşim, bağlantı kesilip gelme, telefon uygulaması kapalı/açık ve yinelenen bildirim senaryolarını dene; ardından en az bir gerçek Wear OS saatte doğrula.
- [ ] Play Console’da Wear OS form faktörünü/ayrı Wear OS test kanalını, TV’den ayrı mağaza ekran görüntülerini ve inceleme adımlarını yapılandır. Gerekli saat modülü ve Wear OS manifesti olmadan mevcut telefon + TV AAB’sinin saati desteklediğini varsayma. [Wear OS yayınlama](https://developer.android.com/training/wearables/packaging) · [Play Console form faktörleri](https://support.google.com/googleplay/android-developer/answer/13295490)

## 22 Kasım 2026 · Vampir Köylü tur sunumu

- [x] Gece, şafak, gündüz oylaması ve akşam geçişini ekranda animasyonlu tur şeridiyle görünür kıl.
- [x] Oyuncu hedef kartlarına ada göre sabit, rolden bağımsız karakter avatarı ekle; gizli rolü avatar veya karttan açığa çıkarma.
- [x] Vampirlerin gece hedef oylaması ve köyün gündüz oylamasında eşitlik olursa harita sırasına bağlı eleme yerine adil biçimde kimseyi eleme.
- [x] Gündüz turu tamamlandığında kişi bazında oy sayısını ve sonuç kartını göster; tek tek oy seçimlerini sonuç özeti olarak saklama.
- [x] Şafak ekranında kurtarılma veya ortak hedef bulunamaması durumunu, akşam ekranında da oylama sonucunu görsel geçiş kartıyla açıkla.
- [ ] Dört ila sekiz Android oyuncusuyla gece/gündüz, eşit oy, rol yetenekleri ve maç sonu akışını fiziksel cihazlarda doğrula.

## 20 Kasım 2026 · 3D oyun görsel turu

- [x] Ortak Three.js motoruna Neon Pist, Sinyal Avı, Yörünge Pilotu, Kristal Labirent, Mini Bowling, Frikik ve Penaltı modları bağlandı. Ortak HUD, duraklatma, yüksek skor, mobil dokunma ve gölge/ışık profili kullanılıyor.
- [x] Flutter oyun sahnelerinde perspektif/gölge/hacim turu: Satranç, Dama, Reversi, Karambol, Dörtlü Diz, Çizgi Doldurma, Sürgülü Bulmaca, Taş Alma, Pac Labirent, Tiger Run, Şerit Yarışı, Mini Golf, Mahalleler, Futbol ve Dövüş. Oyun kuralları ve girişler korundu; çoğu sahne Three.js değil, 2.5D/izometrik CustomPainter çizimi.
- [x] 3D/2.5D görsel turu genişletildi: Renk Hafızası, Balon Patlatma, Maymun Dokunuşu, Çizip Parçalama, Yılan, Tırnak Salonu, Adam Asmaca, Hıçkırık Kulesi, Matematik Bulmacası, Farkı Bul, Scuba Sweep, Refleks Çarpışması, Üçlü Eşle, Sayı Sayma, Mini Bowling, mobil ve web Taş-Kâğıt-Makas, web Zar Oyunu ve Ayna Odası klavye kontrolleri. Oyun kuralları, skor ve giriş akışları korundu.
- [x] Zar Partisi zarlarına perspektifli yuvarlanma, bevel, parlak yüzey ve tutulu zar vurgusu; çocuk oyunlarına özel sahne çizimleri eklendi. Ters Mama seçenekleri kısa ekranlara sığan iki sütunlu, yükseltilmiş dokunma kartlarıyla sunuluyor.
- [ ] Katalogdaki bütün oyunları kategori kategori son kez gözden geçir. Gerçek Three.js kamera dönüşümü bütün oyunlara uygulanmadı; Flutter sahnelerinin çoğu 2.5D/CustomPainter çizimidir.
- [ ] Flutter derlemesi ve PC/Android/iOS gerçek cihaz turu yapılmadı. Three.js WebGL performansı, ekran oranları, dokunma ve bağlam geri yükleme cihazlarda doğrulanmalı.

## 20 Kasım 2026 · PC/web devamı

- [x] Tek kişilik web oyunlarında ortak oyun paneli, tahta, canvas ve yeniden başlatma eylemi masaüstünde ortalandı.
- [x] 2048 PC/web oyununa derinlikli taş görünümü, bevel/ışık/gölge, içe çöken boş hücreler ve puan göstergeleri eklendi; yön tuşu kontrol ipucu korundu.
- [x] Ayna Odası web oyununda 1–4 tuşlarıyla işaret seçimi, kısa klavye yönergesi, odak aktarımı ve erişilebilir kısayol etiketleri eklendi; Tab/Enter/Boşluk davranışı korundu.
- [x] Zar Oyunu web sürümüne hacimli zarlar, zar atma animasyonu ve eldeki puan/son olay paneli eklendi; tur ve puan kuralları korundu.
- [x] Web Taş-Kâğıt-Makas'ta seçim taşları, kazanan vurgusu ve tur özeti derinlikli görsel düzene geçirildi; tıklama akışı korundu.
- [x] Futbol sahnesine daralan ufuk çizgileri, perspektif ceza alanı ve konuma göre ölçeklenen top eklendi; gerçek cihazdaki görsel tur ve tam 3D kamera çalışması hâlâ açık.
- [ ] Değişiklik GitHub'a gönderildikten sonra PC tarayıcısında ve CI'da doğrula.

## 20 Kasım 2026 · Aile oyunları ve yayın hazırlığı

- [x] Kelime Tahtası eklendi. 2–4 telefon, yedi gizli harf, 11×11 ortak tahta, sınırlı Türkçe aile sözlüğü, çapraz kelime doğrulaması, puan, harf değişimi, pas ve sonuç var.
- [x] Gizli Rol eklendi. 4–8 oyuncu, sabotajcı/gözcü/koruyucu/köylü, gizli gece görevleri, gündüz tartışması, açıklanan oylar, elenme ve takım sonucu var.
- [x] Yeni oyunlar mevcut Aile Masası API'sinde çalışıyor. TV ve izleyiciye özel eller, roller ve gece hedefleri gönderilmiyor. Mobil ve web menüleri eklendi. Rövanş yeni maç kimliğiyle açılıyor.
- [x] GitHub Linux CI'da 19 API/web senaryosu gerçek HTTP bağlantılarıyla, beş Firebase temizlik testi ve 61 Flutter testi geçti. Web sürümü Firebase Hosting'e yayınlandı.
- [x] Sürüm `1.0.0+21` için ARM 32/64 bit imzalı AAB üretildi ve Actions çıktısına kaydedildi. Dahili test kanalına yükleme, Play servis hesabı izin hatası (`The caller does not have permission`) nedeniyle tamamlanmadı; mağazadaki sürüm hâlâ 20.
- [x] Play Console'da Saved Games'in ve yedi başarımın yayınlanmış olduğu görüldü. Uygulamadaki yedi başarımın gerçek kimlikleri eşlendi. Total XP tablosu `CgkIxOrNg4kPEAIQEA` kimliğiyle yayınlandı. Play Games yayın ekranında bekleyen değişiklik kalmadığı doğrulandı.
- [x] 100 Matches (`CgkIxOrNg4kPEAIQEQ`) ve Game Explorer (`CgkIxOrNg4kPEAIQEg`) başarımları oluşturuldu ve yayınlandı. Dokuz başarımın kod varsayılanları gerçek kimliklerle tamamlandı.
- [ ] Aynı hesapla iki fiziksel Android cihazında bulut geri yüklemeyi, başarımları ve XP tablosunu açmayı test et.
- [ ] Üretim HTTPS API'si ve temizlik fonksiyonunu yayınla. Firebase Console'da proje Spark planında ve ilk Functions yayını bekleniyor. Blaze/faturalandırma adımı tamamlanmalı veya HTTPS API için mevcut bir kalıcı sunucu kullanılmalı.
- [x] Oyun değişiklikleri main'e `77809cc` ile gönderildi. Telefon katılım alanlarının gizlenmesi ve güvenli depolama beklemesi `d8a3272` ile düzeltildi; 61 Flutter testi geçti. [Doğrulama](https://github.com/ferdidrgn/AZOyun/actions/runs/44665962774).
- [x] Hesap, HTTPS, Android TV, 16 KB, AAB, test kanalı ve cihaz kontrolleri [yayın kontrol dosyasında](docs/RELEASE_CHECKLIST.md) toplandı.
- [x] Play Console'da Chromecast HD'nin kaydolunmamış TV durumu ve eski test kanallarının `android.hardware.faketouch` zorunluluğu görüldü. Özellik isteğe bağlı yapıldı (`e1ec469`). Android TV form faktörü eklendi; ekran görüntüleri ve inceleme adımları bekliyor. RK3326/sgo tüm cihaz aramalarında bulunamadı.
- [x] İmzalı AAB için ABI, ARM64 ELF/RELRO 16 KB hizalama ve derlenmiş TV manifest denetimi `scripts/check-android-bundle.py` içine eklendi. Yeni AAB üzerinde çalıştırılıp raporu saklanacak.

## Aile oyunları ve Firebase odaları

- [x] Klasik Okey ve 101 Okey, diğer mobil oyunlarla aynı Firebase Realtime Database oda akışını kullanıyor. Telefon oda kurabiliyor. Tablet veya Android TV, dört telefon için QR daveti veren ortak ekran olabiliyor. Yeni Okey odalarında tüm katılımcılar güncel sürümü kullanmalı.
- [x] 106 taş karıştırılıyor ve gösterge ayrılıyor. Klasik Okey 14, 101 Okey 21 taşla başlıyor. İlk oyuncu bir fazla taş alıyor. Hamleler sıra ve revizyon kontrolüyle kaydediliyor.
- [x] Istakayı sürükleyerek dizme, taş seçme, kapalı veya önceki oyuncunun attığı taşı çekme ve seçili taşı atma ayrıldı. 101’de 101 puan veya beş çiftle açma, işleme ve yerden alınan taşı kullanma ya da geri bırakma var.
- [x] Pişti’nin mevcut Firebase masa modu ortak ekran menüsüne eklendi. Aynı koltuğu iki kez ayırma ve çakışan dağıtımlar Firebase işlemiyle engelleniyor.
- [x] İstasyon 90’ın sayı sorusu yerine ibreyle zamanlama ve terminal onarımı eklendi.
- [x] Kim Bilir? ve Quiz Eliti mobil katalogda Hedef Atışı ve Denge Hattı oldu. Aynı telefonda 1–6 kişi sırayla nişan ve top kontrolü oynayabiliyor.
- [x] Altı Okey kural testi geçti. Rastgele ve tekrarsız dağıtım, dört koltukta sıra devri, çift çekmenin reddi, yerden alınan taşı geri bırakma, 101 açılışı ve klasik bitiş doğrulandı.
- [x] Okey’de keçe masa, yönlere yerleşen oyuncular, açık ve kapalı taş yığınları ve ahşap istaka eklendi. Taşlar boş gözler bırakılarak sürüklenebiliyor. Sıra üzerindeki koltuk ve yeni çekilen taş işaretleniyor.
- [x] Mahalleler’in mobil ve Android TV sürümü Firebase odalarına bağlandı. 16 kareli tahta, hareket eden piyonlar, zar, mülk alımı, kira, ihale, geliştirme, satış teklifi, iflas ve on tur sonunda sonuç var.
- [x] Beş Mahalleler kural testi geçti. Kira, ihale sonrası sıra devri, satış ve geliştirme, iflas, tahta turu ve oyun sonu doğrulandı. Flutter web derlemesi tamamlandı. Okey ve Mahalleler tahtaları dar ekran önizlemesinde taşma vermedi.
- [ ] İki ve dört Android cihazla Firebase oda kurma, QR ve manuel katılım, sıra devri ve tam el testi. TV kumandası ve Pişti ortak ekranı teste dahil.
- [x] Batak için Firebase lobisi, 52 kart dağıtımı, koz, ihaleli tur, renge uyma ve el skorları. Eşsiz dört kişilik masa dört dağıtımda tamamlanıyor. Kartlar dokunarak veya masaya sürüklenerek oynanıyor.
- [x] Batak’ın on bir senaryo testi doğrudan Dart ile geçti. Bunların içinde yirmi tam maç ve toplam seksen dağıtım var. Yanlış sıra, eski revizyon, pas, zorunlu koz, büyütme, el toplama, puanlama ve QR daveti doğrulandı. Tekrar katılım aynı cihazın koltuğunu ve kartlarını koruyor. Standart Flutter test koşucusu ortamın localhost soketine bağlanamadığından aynı senaryolar geçici bir Dart koşucusuyla çalıştırıldı.
- [x] Batak masası 300 ve 360 piksel genişlikte Flutter motoruyla çizildi. Yerleşim taşması görülmedi.
- [x] Batak eklenmiş Flutter web sürümü başarıyla derlendi.
- [ ] Batak’ı dört telefonla canlı Firebase üzerinde dene. TV’de QR katılımı, kumandayla başlatma, dört dağıtım ve bağlantı kesilip geri gelme senaryolarını tamamla.
- [ ] Mahalleler’i iki ve dört cihazla canlı Firebase üzerinde dene. Özellikle ihale sırası, piyon hareketi ve Android TV ile telefon arasındaki QR katılımı.
- [x] Frikik Ustası ve Penaltı Antrenmanı için Three.js ile 3D kale, kaleci, baraj, top uçuşu ve altı vuruş akışı eklendi. Çevrimiçi Futbol oyunu ayrı 2.5D sahne; cihaz kontrolü bekliyor.
- [x] Futbolcuyu Bil ipucu/tek tahmin, Takımı Bul ise renkli armalı kart eleme ve ek ipucu akışı kullanıyor. Hedef Atışı ve Denge Hattı da soru ekranı yerine refleks/top kontrolü oynanışına sahip. Katalogdaki diğer soru oyunları ayrıca taranmalı.

## 18 Kasım 2026 · Çevrimiçi oyunların onarımı

- [x] Çevrimiçi ve Masa sekmelerine uygulama içi QR taraması eklendi. Geçerli bir davet doğru oyunu açıyor ve kayıtlı oyuncu adıyla katılmayı deniyor. İlk katılımda oyuncu adı isteniyor. Normal oda koduyla katılım da kullanılabiliyor.
- [x] Ortak oda daveti bileşeni düzenlendi. Kod kopyalama ve QR daveti ayrı eylemler oldu. QR pencere olarak açılıyor, böylece dar telefon ekranında oyuncu listesi ile başlat düğmesine yer kalıyor.
- [x] Mini Golf, ilk onarım oyunu olarak seçildi. Oda katılımı boş koltuğu işlem içinde seçiyor. Skor ve delik geçişi tek işlemde yazılıyor. Topun hareketi ekran yenileme hızından bağımsız adımlarla hesaplanıyor.
- [x] Android Play Games girişinde profil resmi yüklemesini bekleyen yol kaldırıldı. Uygulama resmi v2 SDK üzerinden oyuncu bilgilerini alıyor ve giriş hatasını durum koduyla gösteriyor. Mevcut proje kimliği `517819561284` korunuyor.
- [ ] İki fiziksel Android cihazıyla kamera taraması, QR üzerinden koltuk alma, Mini Golf’te beş delik, maç ortasında ayrılma ve sonuç ekranı testi. Mağazadaki sürümle yeni sürümün aynı odaya katılması da bu testin parçası.
- [x] Penaltı Düellosu yeni odalarında 2D kaleye nişan, şut gücü, falso, kaleci dalışı, animasyonlu tekrar ve iki tarafın onayıyla rövanş. Yeni sürüm eski odalara mevcut kurallarla katılabilir. Yeni 2D odalar iki oyuncuda da güncel sürümü gerektirir.
- [x] Serbest Vuruş’ta 2D top fiziği sabit zaman adımıyla ilerliyor. Kale çizgisi ve kaleci teması şutu sonuçlandırıyor. Firebase oda katılımı, şut sonucu ve sıra geçişi çakışan işlemlere karşı korunuyor.
- [x] Mini Golf ve Serbest Vuruş’un giriş ve oda bekleme ekranları aynı açık/koyu tema bileşenlerini kullanıyor.
- [ ] Penaltı Düellosu ve Serbest Vuruş’u iki fiziksel Android cihazında QR davetinden maç sonucuna kadar test et. Penaltı’da rövanşı ve Serbest Vuruş’ta ağ kesintisi sonrası skor tekrarını doğrula.
- [ ] Play Console’da Play Games Android kimlik bilgisinin `com.ferdidrgn.azgame` ve **Play App Signing** sertifikasının SHA-1 değeriyle eşleştiğini doğrula. Play Games Services yapılandırması yayınlanmadıysa dahili test hesabına erişim ver. Oyunu Play Store test kanalından kurup giriş ve Saved Games geri yüklemesini doğrula. [Android Developers](https://developer.android.com/games/pgs/android/troubleshooting)
- [x] Aile Masası mobil ve TV ekranı, API adresini yayınlanan web yapılandırmasından okuyabiliyor. Özel sunucular için elle adres girişi var. HTTPS sunucusu ve kalıcı oda/profil dosyaları için Docker Compose eklendi.
- [ ] Aile Masası API’sini gerçek HTTPS adresine yayınla, GitHub `FAMILY_API_URL` değişkenini ayarla ve web yapılandırmasını yayınla. Mağazadaki sürüm için HTTPS adresini elle girerek test et. Yayınlanabilir VPS/domain henüz sağlanmadı; Firebase projesi Spark planında.
- [ ] Play Console Android TV form faktörü, mağaza varlıkları, TV incelemesi ve Cihaz Kataloğu’ndaki Chromecast HD / RK3326 uyumsuzluk nedenleri. 32/64 bit AAB, 16 KB sayfa uyumu ve kumandayla gerçek cihaz testi. [Yayın adımları](docs/FAMILY_TABLE.md#chromecast-with-google-tv-hd)

## Oyun geliştirme sırası

| Sıra | Oyunlar | Oynanış ve tamamlanma ölçütü |
| --- | --- | --- |
| 1 | Mini Golf, Penaltı Düellosu, Serbest Vuruş | Mini Golf’te top fiziği ve vuruş güvenilirliği. Penaltıda nişan, güç, falso ve kaleci hamlesi. İki telefonda QR ile katıl, maç bitir ve rövanşı başlat. |
| 2 | Araba Yarışı, Dövüşçüler | 2D yarış pisti, dönüş, fren, kontrol noktaları ve geri sayım. Dövüşte hareket, menzil, blok ve dayanıklılık. Gecikme ve bağlantı kopmasıyla tur ve skor tutarlılığını ölç. |
| 3 | Pişti, Dama, Okey, 101 Okey, Son Kart, Aile Masası | Dokunarak veya sürükleyerek hamle, geçerli hedefleri gösterme, sıra zamanlayıcısı ve sonuç. Eldeki kart ve taşlar yalnızca ilgili oyuncuya gönderilir. |
| 4 | İstasyon 90, Hain Kim, Vampir Köylü, Yalancılar Kahvesi | Zamanlı görev, gizli roller ve oyuncuların hamleleriyle değişen sonuçlar. Rol dağıtımı, tur ilerlemesi ve oy verme doğrulanır. |
| 5 | Adam Asmaca, Kelime Bulmaca, Şehir Bulmaca | Süreli harf tahtası, hamle geri bildirimi, seri puanı ve rövanş. Etkileşimler her oyunun kendi kurallarına uygun olur. |
| 6 | Tekli oyunlar | Önce Yılan, Pac Labirent, Jump Dash ve yarış modu. Ardından bulmacalar ve çocuk oyunları. Her oyunda kontrol, zorluk eğrisi, duraklatma, sonuç ve tekrar oyna akışı. |

- [ ] Oyun 2D sahnesi için ilk örnek Mini Golf. Mevcut Flutter `Ticker` ve `CustomPainter` sahnesini kullanıyor. Yarış ve dövüşte ortak sahne döngüsü, çarpışma ve dokunma girdileri tekrar etmeye başladığında Flame üzerinde prototip ve düşük donanımlı Android’de kare süresi karşılaştırması yapılacak. Mevcut Three.js 3D sahneleri kamera ve üç boyutlu hareket gereken oyunlarda değerlendirilecek.
- [ ] Ortak sayfa düzenini kalan çevrimiçi lobiler, oyun HUD’ı, sonuç ekranları ve tekli oyunlara tamamla. Profil, ayarlar ve temel Material 3 tema düzenlendi; kalan sayfalarda açık/koyu yüzeyler, yazı stilleri, oda durumları, düğmeler ve boş ekranlar tutarlılaştırılacak. Oyun tahtaları ve sahneler oynanış işaretlerini koruyacak.
- [ ] Her çevrimiçi oyunda manuel kod ve QR, oda dolu/kapalı, aynı anda katılım, zayıf bağlantı, geri tuşu, arka plana alma, sonuç ve rövanş doğrulanacak. Her tekli oyunda küçük ekran, büyük yazı, çevrimdışı oynama, duraklatma ve tekrar deneme doğrulanacak.
- [ ] İmzalı AAB’yi dahili test kanalında deneyip temiz kurulum ve mevcut sürümden yükseltmeyi doğrula. Fiziksel cihaz ve test kanalı sonuçlarından sonra üretim yayınını değerlendir.

## Aile Masası geçmişi

- [x] Mevcut Masa, Pişti, Okey ve 101 akışlarını inceledim.
- [x] İkinci ekran örneklerini araştırdım. Jackbox oda kodu ile tarayıcıdan katılımı, TV-Top Games ortak tahta ve telefon kumandasını kullanıyor. [Jackbox](https://www.jackboxgames.com/how-to-play) · [TV-Top Games](https://tvtop.games/)
- [x] TV’de oda kurma, QR daveti ve ortak masa. Geniş tarayıcı görünümünde QR ve tahta, Flutter testinde davet kodunun telefon katılımına aktarımı doğrulandı.
- [x] Sunucuda hamle doğrulama, eski hamleyi reddetme ve her telefona kendi elini gönderme. Dört oyuncu ve TV görünümüyle API testi geçti.
- [x] Klasik Okey ve 101 Okey aile masaları. Dağıtım, sıra, yedi çift, 101 açılışı ve masaya taş işleme testleri geçti.
- [x] Mahalleler mülk, kira, açık artırma, geliştirme ve takas oyunu. Gizli teklif, geliştirme, kira ve iflas testleri geçti.
- [x] Mobil, tablet ve web için Flutter ekranları ile Android TV başlatıcı girişi eklendi.
- [x] [Yerel kurulum ve yayın yönergeleri](docs/FAMILY_TABLE.md) hazırlandı.
- [x] Web ve Android sürüm 18 APK/AAB derlemelerini doğruladım. Android emülatöründe temiz telefon kurulumu, TV ekranının açılışı ve yön/OK tuşuyla oyun seçimi geçti.
- [ ] Gerçek Android TV kumandası, iPhone/iPad ve Tizen/webOS tarayıcılarında cihaz testi.
- [ ] Aile Masası sunucusunu herkese açık HTTPS adresinde yayınla ve uygulama paketine adresi tanımla.

## Web oyun salonu

- [x] Web dağıtımını bağımsız HTML, CSS ve JavaScript’e taşı.
- [x] Oyun kataloğunu, Aile Masası’nı ve telefon kumandasını yeniden tasarla.
- [x] PC ve TV tarayıcısında ortak ekran, QR ve manuel oda kodu akışını kur. Tarayıcıda iki oyuncuyla Mahalleler başladı ve telefondaki zar hamlesi ortak tahtaya yansıdı.
- [x] 390 piksel telefon ve 768 piksel tablet düzenlerini tarayıcıda incele. Sayfa yenilendiğinde TV odası ve oyuncu koltuğu geri yüklendi.
- [x] Yörünge Pilotu ve Kristal Labirent’i Three.js ile çalıştıran tarayıcı sayfalarını taşı. Ayna Odası hafıza oyununu ekle.
- [x] Web kataloğuna 32 tarayıcı oyunu, oyun araması ve yerel çok oyunculu filtresi ekle. 32 oyun ekranı tarayıcıda açıldı. XOX, Dörtlü Diz, 2048 ve Penaltı hamleleri doğrulandı.
- [x] AdSense ve Search Console kimliklerini, ads.txt ve app-ads.txt dosyalarını koru. 38 oyun için statik sayfa, canonical, sosyal paylaşım verileri ve sitemap üret.
- [x] Firebase yayın çıktısında .well-known dosyalarını ve web davet yönlendirmesini hazırla.
- [ ] Canlı Search Console sitemap gönderimi, AdSense site onayı ve cihazda Android/iOS bağlantı doğrulaması.
- [ ] Fiziksel TV tarayıcılarında yön tuşlarını ve okunabilirliği doğrula.

## Oda ömrü ve oyuncu ilerlemesi

- [x] Aile Masası’nda boş ve bitmiş odaları otomatik kaldır. Yeniden bağlanma, TV tek başına açık kaldığında silme ve diskten kalıcı silme testleri geçti.
- [x] Web’de profil, XP, seviye, rozet hedefleri ve sıralama ekle. Tamamlanan maçtan tek seferlik puan ve anahtarla geri yükleme test edildi.
- [x] Firebase’deki mobil odalar için zamanlanmış temizlik ve bağlantı takibi ekle. Boş ve bitmiş oda kuralları yerelde test edildi.
- [x] Mobilde tamamlanan maç XP’sini, rozet hedeflerini, profil vitrini ve Google Play Games Saved Games bağlantısını ekle.
- [ ] HTTPS Aile Masası ve Firebase temizlik fonksiyonunu üretimde yayınla.
- [ ] Play Console Saved Games, başarımlar ve XP sıralamasını yapılandır. Aynı hesapla iki Android cihazında geri yüklemeyi doğrula.

## Aile oyunu uygulamaları

- [x] **Batak.** Firebase masa ve telefon ekranları uygulandı. Canlı dört telefon ve TV kumandası testi bekliyor.
- [x] **Kelime tahtası.** TV ortak tahta ve puanları gösteriyor. Telefonda yedi gizli harf ve hamle onayı var. Üretim API yayını bekliyor.
- [x] **Gizli rol.** TV gece/gündüz ve açıklanan oyları gösteriyor. Rol, görev ve gizli seçimler oyuncuya özel API görünümünde. Üretim API yayını bekliyor.
