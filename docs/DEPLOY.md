# Otomatik Web Yayınlama (GitHub Actions → Firebase Hosting)

`main` branch'ine her push yapıldığında (ör. bir Pull Request birleştiğinde)
`.github/workflows/firebase-hosting-deploy.yml` iş akışı otomatik olarak:

1. Flutter'ı kurar
2. `flutter build web --release` ile web sürümünü derler
3. Sonucu Firebase Hosting'e (`azoyun-569b2` projesi, `azoyun` sitesi) yayınlar

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
"Web'i derle ve Firebase Hosting'e yayınla" adında bir çalışma göreceksin.
Yeşil tik ✅ = başarıyla yayınlandı. Kırmızı çarpı ❌ = bir hata var, üstüne
tıklayıp log'ları okuyabilirsin (ya da hatayı bana yapıştır, birlikte
çözeriz).

## Elle de tetikleyebilirsin

Secret'ı ekledikten sonra, yeni bir kod değişikliği olmadan da yayınlamak
istersen: **Actions** sekmesi → soldan bu iş akışını seç → **Run workflow**
butonuna bas.
