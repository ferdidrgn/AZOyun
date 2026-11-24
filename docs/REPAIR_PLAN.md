# AZ Oyun oynanabilirlik ve yayın onarım planı

**Durum:** Uygulanıyor · 24 Kasım 2026  
**Koordinasyon:** Ruflo hierarchical-mesh swarm (`swarm-1795490951211-jfyju9`) ve 10 ayrı ajan iş akışı; REA ile web uygulaması ve üretilen Android APK statik olarak incelendi.

## Doğrulanmış sorunlar

1. TV/Aile Masası `/api/**` isteklerini `familyApi` Firebase Function'ına yönlendiriyor. Bu Function hiç yayınlanmamış; son CI denemesi `artifactregistry.googleapis.com` API'sini etkinleştirme izni olmadığı için durdu. Hosting'in HTML hata sayfası, istemcide “API JSON yanıtı vermedi” olarak gösteriliyor.
2. Android'deki Kariyer Rotası, Kimya XI, Wordle, Bağlantı Yolu, Box2Box ve Connections, RTDB'deki `footballCatalog/current` verisine bağlı. Kataloğu yazacak planlı Function da yayınlanmadığı için boş katalog bu ekranları oynanamaz hale getiriyor.
3. Web statik bir uygulamadır; yeni Flutter futbol ekranları `azoyun.web.app` içine otomatik taşınmıyor. Web kataloğunda futbol quizinin yanında 3D Penaltı/Frikik bulunuyor; tarayıcı WebGL açamazsa bu 3D sayfalar oynanamıyor.
4. Flutter'da 2D Penaltı ve Frikik mekaniği zaten varmış ama ana ekranda bulunmuyordu. Oynanabilirliği bilgi quizinden ayırmak için bu modlar açıkça Futbol Atölyesi'ne ekleniyor.

## İş paketleri

| İş paketi | Yapılacak | Kanıt / sınır |
|---|---|---|
| TV masa durumu | API sağlık kontrolü, kullanılamıyorsa oda aç/katıl düğmelerini kapat ve nedenini/yeniden denemeyi göster. | UI arızayı gizlemez; backend izinleri düzelmeden çok oyunculu oda açılmaz. |
| Dinamik oyuncu kataloğu | Tek ücretsiz Wikidata çekişiyle sürümlü JSON üret, web Hosting'e koy ve RTDB'ye yaz; haftalık yenile. | Android RTDB erişimine/yazma yetkisine bağlı kalabilir; web JSON ayrı dağıtım yoludur. |
| Web Box2Box | Kategori kesişim tahtası, oyuncu arama, kaynak katalogdan cevap doğrulama ve skor. | Statik cevap bankası yok; yayınlanan katalog yüklenemezse açık hata/yenileme. |
| Web futbol vuruşu | 3D WebGL yokken Canvas 2D Penaltı/Frikik oynanışı. | Nişan, güç, kaleci/baraj, gol/kaçış, puan ve tekrar; 3D sahne korunur. |
| Android vuruş oyunu | Mevcut gerçek 2D vuruş ekranını ana ekranda görünür kıl. | Katalog/API olmadan çevrimdışı oynanabilen doğrudan oynanış. |
| Android veri oyunları | RTDB'yi dene; başarısızsa web'deki güncel JSON kataloğunu yükle. | Veri yoksa soru ekranına düşürmek yerine anlaşılır hata ve tekrar deneme. |
| CI / yayın | Web'i `azoyun.web.app` Hosting sitesine dağıt; APK artefaktlarını üret; Google Play production otomatik değil. | Hosting başarısı, Function başarısı ve APK artefaktı ayrı ayrı raporlanır. |

## Sıra ve tamamlanma ölçütleri

1. TV masa API hatasını açıkça göster; doğrudan RTDB'yi anonim kullanıma açma.
2. Aynı doğrulanmış Wikidata paketini haftalık web JSON'u ve Android RTDB yayını için kullan.
3. Web'de gerçek futbol grid oyunu ve WebGL gerektirmeyen vuruş oyunu ekle.
4. Android'de 2D Penaltı/Frikik'i aç; dinamik ekranları RTDB/JSON kaynağına bağla.
5. CI'da web build'i, doğrulama adımlarını, APK artefaktlarını ve Hosting canlı yayını ayrı ayrı kontrol et.
6. Firebase Functions'ın yayını için proje sahibinin `artifactregistry.googleapis.com` ve `cloudbuild.googleapis.com` API'lerini etkinleştirme yetkisi ile Gen 2 Functions için Blaze/faturalandırma ayarını sağlaması gerekir. Bu izin olmadan TV masası API'si ve haftalık Cloud Functions job'u canlı çalışıyor diye beyan edilmeyecek.

## Güvenlik / veri notu

`family_api` oyuncu oturum anahtarlarını ve gizli oyun durumunu içerir. Bu nedenle TV masasını çalıştırmak için Realtime Database kurallarını herkese yazılabilir hale getirmek güvenli bir çözüm değildir. API, Firebase Function veya eşdeğer yetkili HTTPS backend üzerinden yayınlanmalıdır.
