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

## Sonraki oyun fikirleri

- **Batak.** TV koz, açık kartlar ve alınan elleri gösterir. Her telefon kendi kartlarını ve teklifini taşır. Mevcut Pişti masası da Masa sekmesinden açılabilir.
- **Kelime tahtası.** TV ortak tahtayı ve puanları gösterir. Telefonda yedi gizli harf ve hamle onayı bulunur.
- **Gizli rol.** TV gece ve gündüz akışını ve açıklanan oyları gösterir. Roller, görevler ve gizli seçimler telefonlarda kalır.
