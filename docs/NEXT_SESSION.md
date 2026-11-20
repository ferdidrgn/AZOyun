# AZOyun devam noktası

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

- On dokuz API/web testi, geçici süreç içi HTTP taşımasıyla geçti. Bu ortam `127.0.0.1` bağlantılarına `EACCES` veriyor. Üretim sunucusu üzerinde test edilmiş gibi işaretleme.
- Beş Firebase temizlik politikası testi geçti.
- Flutter web derlemesi tamamlandı. Kod analizinde yeni hatalar çıkmadı. Şehir/Adam Asmaca'da iki kullanılmayan metot ve `main.dart` içinde önceden bulunan bir uyarı var.
- Önceki aşamada Okey'in altı, Mahalleler'in beş, Batak'ın on bir Dart senaryosu geçti. Batak testleri yirmi tam maçı kapsıyor.
- Flutter standart test koşucusu bu ortamda localhost soket hatası veriyor. CI'daki gerçek `flutter test` sonucu ayrıca doğrulanmalı.

## Hesap durumu

- Firebase Console açıldı. `azoyun-569b2` Spark planında. Functions ekranı ilk yayını bekliyor. Zamanlanmış temizlik için Blaze/faturalandırma gerekiyor. Kullanıcı bir mevcut VPS verirse HTTPS API Docker Compose ile orada da çalışabilir.
- Play Console geliştirici hesabı `8029085725143571520`, uygulama `4975804818976454127`, paket `com.ferdidrgn.azgame`.
- Play Games projesi `517819561284`. Saved Games ve Android kimlik bilgisi zaten yayınlanmış.
- Yedi mevcut başarımın gerçek kimlikleri `PlayGamesService` içindeki varsayılanlarla eşlendi. Boş CI değişkenleri bu varsayılanları ezmeyecek şekilde build argümanları düzeltildi.
- Total XP tablosu `CgkIxOrNg4kPEAIQEA` kimliğiyle yayınlandı. Play Games yayın ekranında bekleyen değişiklik kalmadığı doğrulandı. Yüz Maç ve Oyun Gezgini için kayıtlar tamamlanmalı. İki fiziksel Android cihazıyla bulut geri yükleme henüz denenmedi.
- CUA dosya yüklemesi sekme/oturum eşleşme hatası verdi. Bir başarım formu dolduruldu ama kaydedildiği varsayılmamalı. Yeni kaydı oluşturmadan önce Console'daki mevcut kayıtları kontrol et.

## Main'e gönderim

Yerel `gh` oturumu geçersiz. GitHub bağlantısı depoyu okuyabiliyor fakat Git ağacı ve dal oluşturma isteklerini HTTP 403 ile reddetti. Normal Git push, `getaddrinfo() thread failed to start` hatası verdi. Main'in güncellendiğini varsayma.

Değişiklikler ayrı, yazılabilir bir geçici checkout'ta commitlendi. Geçici checkout yolu `build/release21/checkout.txt` içinde. Kaybolmaya karşı commit nesneleri `build/release21/azoyun-release21.bundle` dosyasına aktarıldı. Kaynak çalışma dizinindeki dosyalar da duruyor.

Geçerli GitHub oturumu ve ağ bağlantısı olan PowerShell'de, proje kökünden aşağıdaki komutlar çalışma dosyalarını değiştirmeden hazır commit'i main'e gönderebilir. Uzak main ilerlemişse normal Git kontrolü gönderimi reddeder ve değişiklikler önce birleştirilir.

```powershell
git bundle verify ./build/release21/azoyun-release21.bundle
git fetch ./build/release21/azoyun-release21.bundle HEAD:refs/heads/release21-ready
git log -1 release21-ready
git push origin release21-ready:main
```

Push sonrasında web CI ve Play dahili kanal iş akışları izlenmeli. Yerel commit oluşması, GitHub'a push veya mağaza yayını tamamlandığı anlamına gelmez.

## Bekleyen sonraki adımlar

1. HTTPS API, GitHub `FAMILY_API_URL`, web yapılandırması ve Firebase temizlik fonksiyonunun üretim yayınını tamamla.
2. Total XP ve eksik iki başarımı yayınla. İki cihazla Saved Games ve Play App Signing SHA-1 eşleşmesini doğrula.
3. Android TV form faktörü ve gerçek Chromecast HD / RK3326 Cihaz Kataloğu gerekçelerini aç. Güncel AAB'nin ABI ve 16 KB uyumunu ölç. Yerel eski AAB güncel sürümün kanıtı sayılmaz.
4. Bütün oyunların QR, dolu oda, eşzamanlı katılım, zayıf ağ, arka plan, sonuç ve rövanş cihaz turunu tamamla. Tekli oyunlarda çevrimdışı, büyük yazı, duraklatma ve yeniden deneme turunu yap.
5. Ortak UI'nin kalan HUD/sonuç/profil/ayarlar/tekli oyun ekranlarına yayılmasını ve açık/koyu tema görsel turunu sürdür.
6. Masa oyunlarından sonra futbol/frikikte 3D kamera ve hareketi iyileştir. Mini Golf Ticker/CustomPainter temelini koruyarak yarış/dövüşte tekrarlanan döngüler için Flame prototipini düşük donanımlı Android kare süresiyle karşılaştır.
