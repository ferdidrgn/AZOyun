# AZOyun oyun geliştirme ve ilerleme takibi

## 20 Kasım 2026 · Aile oyunları ve yayın hazırlığı

- [x] Kelime Tahtası eklendi. 2–4 telefon, yedi gizli harf, 11×11 ortak tahta, sınırlı Türkçe aile sözlüğü, çapraz kelime doğrulaması, puan, harf değişimi, pas ve sonuç var.
- [x] Gizli Rol eklendi. 4–8 oyuncu, sabotajcı/gözcü/koruyucu/köylü, gizli gece görevleri, gündüz tartışması, açıklanan oylar, elenme ve takım sonucu var.
- [x] Yeni oyunlar mevcut Aile Masası API'sinde çalışıyor. TV ve izleyiciye özel eller, roller ve gece hedefleri gönderilmiyor. Mobil ve web menüleri eklendi. Rövanş yeni maç kimliğiyle açılıyor.
- [x] GitHub Linux CI'da 19 API/web senaryosu gerçek HTTP bağlantılarıyla, beş Firebase temizlik testi ve 61 Flutter testi geçti. Web sürümü Firebase Hosting'e yayınlandı.
- [x] Sürüm `1.0.0+21` hazırlandı. Main iş akışı ARM 32/64 bit imzalı AAB'yi dahili test kanalına gönderecek şekilde değiştirildi. AAB ayrıca Actions çıktısı olarak saklanıyor.
- [x] Play Console'da Saved Games'in ve yedi başarımın yayınlanmış olduğu görüldü. Uygulamadaki yedi başarımın gerçek kimlikleri eşlendi. Total XP tablosu `CgkIxOrNg4kPEAIQEA` kimliğiyle yayınlandı. Play Games yayın ekranında bekleyen değişiklik kalmadığı doğrulandı.
- [x] 100 Matches (`CgkIxOrNg4kPEAIQEQ`) ve Game Explorer (`CgkIxOrNg4kPEAIQEg`) başarımları oluşturuldu ve yayınlandı. Dokuz başarımın kod varsayılanları gerçek kimliklerle tamamlandı.
- [ ] Aynı hesapla iki fiziksel Android cihazında bulut geri yüklemeyi, başarımları ve XP tablosunu açmayı test et.
- [ ] Üretim HTTPS API'si ve temizlik fonksiyonunu yayınla. Firebase Console'da proje Spark planında ve ilk Functions yayını bekleniyor. Blaze/faturalandırma adımı tamamlanmalı veya HTTPS API için mevcut bir kalıcı sunucu kullanılmalı.
- [x] Oyun değişiklikleri main'e `77809cc` ile gönderildi. Telefon katılım alanlarının gizlenmesi ve güvenli depolama beklemesi `d8a3272` ile düzeltildi; 61 Flutter testi geçti. [Doğrulama](https://github.com/ferdidrgn/AZOyun/actions/runs/44665962774).
- [x] Hesap, HTTPS, Android TV, 16 KB, AAB, test kanalı ve cihaz kontrolleri [yayın kontrol dosyasında](docs/RELEASE_CHECKLIST.md) toplandı.

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
- [ ] Futbolda kale, oyuncu ve topa derinlik veren 3D kamera ve şut sahnesi. Bu çalışma masa oyunlarından sonraki aşamada.
- [ ] Futbol tahmin ekranlarını ve katalogdaki diğer soru temelli oyunları ayrı oynanışlara dönüştür.

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
- [ ] Aile Masası API’sini gerçek HTTPS adresine yayınla, GitHub `FAMILY_API_URL` değişkenini ayarla ve web yapılandırmasını yayınla. Mağazadaki sürüm için HTTPS adresini elle girerek test et.
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
- [ ] Ortak sayfa düzeni çevrimiçi lobilerden başlayarak oyun HUD’ı, sonuç, profil, ayarlar ve tekli oyunlara uygulanacak. Açık ve koyu temada aynı yüzeyler, yazı stilleri, oda durumları, düğmeler ve boş ekranlar kullanılacak. Oyun tahtaları ve sahneler oynanış işaretlerini koruyacak.
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
