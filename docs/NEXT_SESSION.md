# AZOyun devam noktası

## PC/web çalışması — 20 Kasım 2026

- `web/salon/style.css` içinde klasik tek kişilik oyun paneli, tahta, canvas ve yeniden başlatma düğmeleri geniş ekranda ortalandı. 2048 ekranına yön tuşu ipucu eklendi. İlgili ilerleme maddeleri `PROGRESS.md` başında.
- Futbol `CustomPainter` sahasında perspektif yan çizgiler/çim şeritleri, yamuk ceza alanı ve topun derinliğe göre ölçeklenmesi eklendi. Bu hâlâ 2.5D çizimdir; fiziksel cihaz incelemesi ve tam 3D kamera işi tamamlanmadı.
- Bu oturumdaki düzenleme henüz commit edilmedi veya yayımlanmadı. `.git` yazma izni engelleniyor; GitHub yazma API'si 403 döndürdü.
- Yerel `codex/web-oyun-salonu` HEAD'i `96825a4`; uzaktaki `main` önceki kontrolde `29c55e0` idi. Mevcut geniş çalışma ağacını doğrudan göndermekten önce main ile farkı karşılaştır; eski değişikliklerin çoğu zaten main'de bulunuyor.
- PC/web tarafındaki sonraki yazılım işi: kalan tek kişilik oyun HUD/sonuç, profil ve ayar ekranlarında ortak düzeni gözden geçir. Cihaz/hesap isteyen maddeleri gerçek test olarak işaretleme.

## Bu oturumda devam — 21 Kasım 2026

- Çocuk oyunlarının kalan ekranları ve Parti Zarı görsel olarak incelendi. Ters Mama seçenekleri kısa ekranda taşmadan kullanılabilsin diye iki sütunlu, yükseltilmiş dokunma kartlarına alındı; oyun kuralları değişmedi.
- Katalog çapında son kategori taraması, Flutter/cihaz turu ve yayın adımları hâlâ açık. Yerel ChatGPT sohbet geçmişi şu an hız sınırı nedeniyle okunamadı; kod çalışması bu depodaki notlar ve dosyalar üzerinden sürdürüldü.

Önce `PROGRESS.md`, `docs/RELEASE_CHECKLIST.md` ve bu dosyayı oku. Öncelik aile masa oyunları. Kullanıcı Firebase odalarını istiyor ve tamamlanan değişikliklerin main'e gönderilmesini yetkilendirdi.

## Kod

- Çalışma dizini `C:\Users\ferdi\OneDrive\Belgeler\GitHub\AZOyun`. Kaynak çalışma dalı `codex/web-oyun-salonu`.
- Klasik Okey ve 101 için keçe masa, boş gözlü ahşap istaka, sürükleme, çekme/atma, 101 açma/işleme ve sıra kontrolü var.
- Firebase üzerinden Batak ve Mahalleler eklendi. Pişti ortak ekran menüsünde. Bu oyunların fiziksel çok cihazlı testi bekliyor.
- Kelime Tahtası ve Gizli Rol, `family-server/party-games.mjs` içinde. Telefonlara özel eller ve roller `partyView` projeksiyonu üzerinden gönderiliyor. Flutter arayüzü `lib/features/family/party_table.dart`, web arayüzü `web/salon/party-tables.mjs`.
- Kelime Tahtası 2–4 kişi, yedi harf, 11×11 tahta ve kod içinde sınırlı bir aile sözlüğü kullanıyor. Genel Türkçe sözlüğün tamamını desteklediği iddia edilmemeli.
- Gizli Rol 4–8 kişi. Her yaşayan oyuncu gece görevi veya dinlenme, gündüz oy onayı gönderiyor. Sabotajcı, koruyucu, gözcü ve köylü var. Tartışma ve sonraki geceyi TV kurucusu ilerletiyor.
- Yeni iki oyun için gerçek HTTPS API yayını bekliyor. Firebase Hosting tek başına Node API'yi çalıştırmaz.
- Sürüm `1.0.0+21`. Play workflow varsayılanı dahili test. İmzalı AAB artifact olarak saklanıyor. ARM 32/64 bit derleme seçili.

## Test sonuçları

- GitHub Linux CI'da 19 API/web testi gerçek HTTP soketleriyle, beş Firebase temizlik politikası testi ve 61 Flutter testi geçti. [Tam Flutter doğrulaması](https://github.com/ferdidrgn/AZOyun/actions/runs/44665962774).
- Flutter web derlemesi tamamlandı. Kod analizinde yeni hatalar çıkmadı. Şehir/Adam Asmaca'da iki kullanılmayan metot ve `main.dart` içinde önceden bulunan bir uyarı var.
- Önceki aşamada Okey'in altı, Mahalleler'in beş, Batak'ın on bir Dart senaryosu geçti. Batak testleri yirmi tam maçı kapsıyor.
- Yerel Flutter test koşucusu localhost soket hatası veriyor; gerçek test sonucu GitHub Linux koşucusunda doğrulandı. QR telefon katılım alanlarının gizlenmesi ve güvenli depolamada sınırsız bekleme giderildi.

## Hesap durumu

- Firebase Console açıldı. `azoyun-569b2` Spark planında. Functions ekranı ilk yayını bekliyor. Zamanlanmış temizlik için Blaze/faturalandırma gerekiyor. Kullanıcı bir mevcut VPS verirse HTTPS API Docker Compose ile orada da çalışabilir.
- Play Console geliştirici hesabı `8029085725143571520`, uygulama `4975804818976454127`, paket `com.ferdidrgn.azgame`.
- Play Games projesi `517819561284`. Saved Games ve Android kimlik bilgisi zaten yayınlanmış.
- Yedi mevcut başarımın gerçek kimlikleri `PlayGamesService` içindeki varsayılanlarla eşlendi. Boş CI değişkenleri bu varsayılanları ezmeyecek şekilde build argümanları düzeltildi.
- Total XP `CgkIxOrNg4kPEAIQEA`, 100 Matches `CgkIxOrNg4kPEAIQEQ` ve Game Explorer `CgkIxOrNg4kPEAIQEg` yayınlandı. Play Games yayın ekranında bekleyen değişiklik kalmadığı doğrulandı. İki fiziksel Android cihazıyla bulut geri yükleme henüz denenmedi.

## Main'e gönderim

Oyun kodları main'e `77809cc094fe18af15cc3d9e75e2a7a892900090` ile gönderildi. QR telefon düzeltmesi `d8a327278a6e9889a240a6c12fee67944bc2b76c` ile main'de. [Web yayını](https://github.com/ferdidrgn/AZOyun/actions/runs/44665021186) başarılı. Son Play Games kimlikleri `b214ea53b6ede35bc94a589a6958fe0fb101920e` ile main'e gönderildi. [İmzalı AAB dahili kanal işi](https://github.com/ferdidrgn/AZOyun/actions/runs/44666860253) tamamlandı: test/derleme ve artifact saklama başarılı; Play yüklemesi `The caller does not have permission` ile başarısız. Artifact ID `14598192802`, SHA-256 `6508d1ff2d4754740529bc06b7f2761e3bbad1b8c46d4a60f83d0d91bb0312c8`.

Son oyun/UI çalışmaları `71182cf` ile `codex/web-oyun-salonu` dalında saklı. `codex/release21-transfer` yalnızca tek seferlik AAB doğrulama iş akışı ve eski bir Git bundle içerir; çalışan kaynak değişiklikleri main'de ayrıca bulunduğundan o dalı main'e birleştirme. Yerel kurtarma kopyası `build/release21/azoyun-release21.bundle` içinde tutulur; son QR/Play Games düzeltmelerini içermez.

## Bekleyen sonraki adımlar

1. HTTPS API, GitHub `FAMILY_API_URL`, web yapılandırması ve Firebase temizlik fonksiyonunun üretim yayınını tamamla.
2. Play servis hesabına AZGame için sürüm yayınlama yetkisi tanımlandıktan sonra dahili AAB yüklemesini yeniden çalıştır. Sonra iki cihazla Saved Games, XP tablosu ve Play App Signing SHA-1 eşleşmesini doğrula. Dokuz başarımın kimlikleri artık kodda tanımlı.
3. Android TV form faktörü eklendi; gerçek TV mağaza ekran görüntüleri ve ardından inceleme/dağıtımı etkinleştirme adımı bekliyor. Chromecast HD `google boreal` ARM32 ve Kaydolunmadı durumunda; eski test kanallarının fake touch zorunluluğu `e1ec469` ile kaldırıldı. RK3326 ve sgo tüm cihaz aramasında bulunamadı. Son AAB işi `44666860253`; `scripts/check-android-bundle.py` ile ABI, 16 KB ve derlenmiş manifest kontrol raporunu incele. Eski yerel AAB kanıt sayılmaz.
4. Bütün oyunların QR, dolu oda, eşzamanlı katılım, zayıf ağ, arka plan, sonuç ve rövanş cihaz turunu tamamla. Tekli oyunlarda çevrimdışı, büyük yazı, duraklatma ve yeniden deneme turunu yap.
5. Ortak UI'nin kalan HUD/sonuç/profil/ayarlar/tekli oyun ekranlarına yayılmasını ve açık/koyu tema görsel turunu sürdür.
6. Masa oyunlarından sonra futbol/frikikte 3D kamera ve hareketi iyileştir. Mini Golf Ticker/CustomPainter temelini koruyarak yarış/dövüşte tekrarlanan döngüler için Flame prototipini düşük donanımlı Android kare süresiyle karşılaştır.
