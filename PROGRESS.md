# Aile Masası ilerleme takibi

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

## Sonraki oyun fikirleri

- **Batak.** TV koz, açık kartlar ve alınan elleri gösterir. Her telefon kendi kartlarını ve teklifini taşır. Mevcut Pişti masası da Masa sekmesinden açılabilir.
- **Kelime tahtası.** TV ortak tahtayı ve puanları gösterir. Telefonda yedi gizli harf ve hamle onayı bulunur.
- **Gizli rol.** TV gece ve gündüz akışını ve açıklanan oyları gösterir. Roller, görevler ve gizli seçimler telefonlarda kalır.
