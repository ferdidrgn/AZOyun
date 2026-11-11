# Web yayını, Google ve uygulama bağlantıları

Web çıktısını `node scripts/build-web.mjs` ile hazırla. Firebase Hosting ve yerel Aile Masası sunucusu `build/salon` dizinini kullanır.

## Google Search Console ve AdSense

- Search Console doğrulama etiketi ve `google5afbd46fec1b3ba7.html` önceki sitedeki değerleri kullanır. Yayından sonra mevcut Search Console mülkünde `https://azoyun.web.app/sitemap.xml` adresini gönder.
- Oyun kataloğu ve oyun sayfalarının başlıkları derleme sırasında HTML’ye yazılır. `/oyun/<oyun>/` adresleri canonical ve sitemap için ortak kaynaktır. Oda davetleri, TV kumandası ve Arcade’in doğrudan oyun motoru adresleri sitemap dışında tutulur.
- AdSense yayıncı kimliği `ca-pub-5779807348211992` ve kök `ads.txt` önceki kurulumdan gelir. `app-ads.txt` mobil mağaza kaydı içindir. Siteyi AdSense’e eklerken kök dosyayı veya `google-adsense-account` meta etiketini kullanabilirsin.
- Reklam betiği varsayılan olarak kapalıdır. AdSense onayı ve gerekli izin yönetimi hazır olduğunda GitHub depo değişkeni `WEB_ADS_ENABLED=true` ile yeni web çıktısını hazırla. Betik yalnızca üretim alan adında ve genel sayfalarda çalışır. Oda ekranlarında yüklenmez. Reklam birimlerini yerleştirirken AdSense’in oluşturduğu gerçek slot numaralarını kullan.
- AEA, Birleşik Krallık ve İsviçre trafiği için geçerli Google izin ayarlarını AdSense **Gizlilik ve mesajlaşma** ekranında yapılandır. [Google AdSense izin yönetimi](https://support.google.com/adsense/answer/13554116)

## Android ve iOS oda davetleri

- Yeni davet adresi `https://azoyun.web.app/join/<oyun>/<kod>`. Eski `?join=<oyun>&code=<kod>` davetleri de webde çalışır. Aile Masası daveti tarayıcıdan katılıma, mobil oyun daveti uygulamayı açma seçeneğine gider.
- Android App Links için `/.well-known/assetlinks.json` mevcut Android paket adı ve parmak iziyle yayınlanır. Play Console **Uygulama bütünlüğü** ekranındaki uygulama imzalama SHA-256 değerini dosyayla karşılaştır. HTTPS ilişkilendirmesi, yeni manifesti içeren Android sürümü ve canlı dosya ile cihazda doğrulanır.
- iOS için web çıktısı `APPLE_TEAM_ID` verilirse aynı paket adı ve `/join/*` yoluyla AASA dosyasını üretir. Apple Developer ve Xcode’da Associated Domains yetkisi ve `applinks:azoyun.web.app` kaydı ayrıca gerekir. Ekip kimliği olmadan boş ilişkilendirme dosyası sunulur. Özel `azoyun://` daveti uygulamanın yeni iOS sürümünde kullanılabilir.
