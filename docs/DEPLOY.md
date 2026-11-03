# Otomatik Web Yayınlama (GitHub Actions → Firebase Hosting)

`main` branch'ine her push yapıldığında ve her pull request'te
`.github/workflows/firebase-hosting-deploy.yml` iş akışı:

1. Flutter'ı kurar
2. `flutter test` ile testleri çalıştırır
3. `flutter build web --release` ile web sürümünü derler
4. Yalnızca `main`'de, testler geçtikten sonra sonucu Firebase Hosting'e
   (`azoyun-569b2` projesi, `azoyun` sitesi) yayınlar

Elle `flutter build web` + `firebase deploy` çalıştırmana artık gerek yok.

## Tek seferlik kurulum: GitHub'a Firebase izni ver

Bu iş akışının GitHub'dan Firebase'e "benim yerime yayınla" diyebilmesi için
bir kerelik bir sır (secret) eklemen gerekiyor. Adımlar:

### 1. Firebase'den bir "servis hesabı anahtarı" indir
1. https://console.firebase.google.com adresine git, **azoyun-569b2**
   projesini aç.
2. Sol üstteki dişli ikonuna tıkla → **Project settings** (Proje ayarları).
3. Üstteki sekmelerden **Service accounts** (Servis hesapları) sekmesine geç.
4. **Generate new private key** (Yeni özel anahtar oluştur) butonuna tıkla,
   açılan uyarıda onayla.
5. Bilgisayarına küçük bir `.json` dosyası inecek — bunu bir yere kaydet.
   Bu dosya şifre gibidir, kimseyle paylaşma, GitHub'a **dosya olarak**
   yükleme; sadece aşağıdaki adımda içeriğini kopyalayacaksın.

### 2. Bu dosyanın içeriğini GitHub'a "secret" olarak ekle
1. GitHub'da `ferdidrgn/AZOyun` reposuna git.
2. **Settings** (Ayarlar) → sol menüden **Secrets and variables** →
   **Actions**.
3. **New repository secret** (Yeni repo sırrı) butonuna tıkla.
4. **Name** kutusuna tam olarak şunu yaz: `FIREBASE_SERVICE_ACCOUNT_AZOYUN`
5. **Secret** kutusuna, indirdiğin `.json` dosyasını bir metin editörüyle
   (Not Defteri yeterli) açıp **içindeki her şeyi** kopyala-yapıştır.
6. **Add secret** (Sır ekle) ile kaydet.

Bu kadar. Bir daha bu adımları tekrarlamana gerek yok — bundan sonra `main`'e
her push, birkaç dakika içinde otomatik olarak canlı siteye (azoyun.web.app /
kendi domainin) yansır.

## Nasıl kontrol ederim?

GitHub'da reponun **Actions** sekmesine gir — her push'tan sonra orada
"CI ve web yayını" adında bir çalışma göreceksin.
Yeşil tik ✅ = başarıyla yayınlandı. Kırmızı çarpı ❌ = bir hata var, üstüne
tıklayıp log'ları okuyabilirsin (ya da hatayı bana yapıştır, birlikte
çözeriz).

## Elle de tetikleyebilirsin

Secret'ı ekledikten sonra, yeni bir kod değişikliği olmadan da yayınlamak
istersen: **Actions** sekmesi → soldan bu iş akışını seç → **Run workflow**
butonuna bas.

---

# Otomatik Google Play Yayınlama (GitHub Actions → AAB)

`main`'e her push'ta `.github/workflows/play-store-deploy.yml` iş akışı:

1. Flutter + Java kurar
2. Aşağıdaki secret'lardan imzalama anahtarını (keystore) geri oluşturur
3. `flutter test` çalıştırır
4. `flutter build appbundle --release` ile imzalı AAB üretir
5. AAB'yi Google Play Console'daki **internal** (dahili test) kanalına yükler

**Bilerek production'a otomatik basmıyor** — bir önceki AdMob/AdSense askıya
alma olayından sonra, yeni bir sürümün gözden geçirilmeden gerçek kullanıcılara
gitmesini istemedik. İnternal kanalda test edip sorun yoksa Play Console'dan
elle "Production'a terfi ettir" diyebilirsin, ya da Actions sekmesinden bu
iş akışını **Run workflow** ile manuel tetikleyip açılan listeden
`alpha` / `beta` / `production` seçebilirsin.

## Tek seferlik kurulum: 5 secret

GitHub'da `ferdidrgn/AZOyun` → **Settings** → **Secrets and variables** →
**Actions** → **New repository secret** ile aşağıdaki 5 secret'ı ekle.

### 1-4. İmzalama (keystore) bilgileri

Bunlar bilgisayarındaki `android/key.properties` (ve `keys.txt`) dosyalarında
zaten var — o dosyaları aç, değerleri kopyala:

| Secret adı | Değer |
|---|---|
| `ANDROID_KEY_ALIAS` | `key.properties` içindeki `keyAlias` |
| `ANDROID_KEY_PASSWORD` | `key.properties` içindeki `keyPassword` |
| `ANDROID_STORE_PASSWORD` | `key.properties` içindeki `storePassword` |
| `ANDROID_KEYSTORE_BASE64` | Aşağıda anlatılan şekilde `.jks`/`.keystore` dosyasının base64 hâli |

`ANDROID_KEYSTORE_BASE64` için: `key.properties`'teki `storeFile` satırının
gösterdiği `.jks` dosyasının **içeriğini** base64'e çevirip o metni secret
olarak yapıştırman gerekiyor (dosyanın kendisini değil, metin karşılığını).

PowerShell'de:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\yol\dosya.jks")) | Set-Clipboard
```
Bu komut base64 metnini direkt panoya kopyalar — GitHub'daki secret kutusuna
yapıştırman yeterli.

⚠️ Bu dosyayı ve şifreleri kaybedersen, Play Console'da yayınlanmış uygulamayı
**güncelleyemezsin** (yeni bir uygulama gibi görünür) — zaten güvenli bir
yere yedekli olduğundan emin ol.

### 5. Play Console API erişimi (servis hesabı)

1. https://play.google.com/console → uygulaman → **Kurulum (Setup)** →
   **API access**.
2. Bağlı bir Google Cloud projesi yoksa oluşturmanı isteyecek, kabul et.
3. **Create new service account** (ya da var olan Cloud projesinde bir
   servis hesabı oluştur) — Google Cloud Console'a yönlendirir, orada
   **IAM & Admin → Service Accounts → Create Service Account** ile bir
   hesap oluştur, rol gerekmiyor (Play Console tarafında yetki vereceğiz).
4. Oluşturduğun servis hesabı için bir **JSON anahtarı** indir (Keys →
   Add Key → Create new key → JSON).
5. Play Console'a geri dön → **Users and permissions** → bu servis
   hesabını (e-posta adresiyle) davet et → en azından **"Release to
   testing tracks"** (ve production'a da basmak istiyorsan **"Release to
   production"**) iznini ver.
6. İndirdiğin `.json` dosyasının **tüm içeriğini** kopyala, GitHub secret'ı
   `PLAY_STORE_SERVICE_ACCOUNT_JSON` olarak yapıştır.

⚠️ Bu API, Play Console'da **daha önce en az bir kez elle yayınlanmış**
bir uygulama üzerinde çalışır — sıfırdan bir uygulama/listing oluşturamaz.
AZOyun zaten yayında olduğu için bu bir sorun değil.

## Nasıl kontrol ederim?

GitHub'da **Actions** sekmesi → "Google Play'e yayınla (AAB)" çalışması.
Yeşil tik ✅ = internal kanala yüklendi (Play Console → Test → Internal
testing'de görünür). Kırmızı çarpı ❌ = log'lara bak (ya da hatayı bana
yapıştır).
