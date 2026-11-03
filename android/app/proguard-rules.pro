# Bu dosya release build için minifyEnabled + shrinkResources açıkken
# (bkz. app/build.gradle.kts) R8'in reflection ile erişilen sınıfları
# yanlışlıkla silmesini/obfuscate etmesini önler — ama ÖNEMLİ: olabildiğince
# DAR tutulmalı. Daha önce burada Firebase/Play Services/AdMob/Billing/Gson
# gibi koca paketlerin tamamını "-keep class X.** { *; }" ile koruyorduk;
# bu, R8'in o paketlerin neredeyse tamamını küçültmeden/obfuscate etmeden
# bırakmasına yol açtı (Play Console "düşük optimizasyon/küçültme/karartma
# oranı" uyarısı — bkz. ROADMAP). Bu kütüphanelerin hepsi zaten kendi AAR'ları
# içinde kendi consumer-proguard-rules.txt dosyalarını taşıyor ve R8 bunları
# otomatik uyguluyor — ayrıca bizim geniş "-keep"lerimize gerek yok. Burada
# sadece o kütüphanelerin KENDİ kurallarının kapsamadığı, Flutter'a özgü ve
# gerçekten yaşanmış iki dar sorunu koruyoruz.

# Gerekli attribute'lar — reflection, generic tip bilgisi ve annotation'lara
# bağımlı kütüphaneler için gerekli; kod boyutuna/küçültmeye etkisi yok.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable

# --- Play Core / deferred components ---
# Flutter'ın embedding'i Play Store'dan kurulan APK'larda (varsa) bu
# sınıflara başvurur; R8 bunları isteğe bağlı/eksik bağımlılık sanıp
# silebilir — "sadece Play Store'dan indirince açılışta çöküyor"
# semptomunun klasik, dar kapsamlı sebeplerinden biri. Paket küçük,
# tamamını korumanın optimizasyon oranına etkisi ihmal edilebilir.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- flutter_local_notifications ---
# Bildirim/alarm yeniden planlama BroadcastReceiver'ları manifest'ten
# reflection ile çağrılır; silinirse/adı değişirse bildirimler çöker.
# Paket küçük, tamamını korumanın etkisi ihmal edilebilir.
-keep class com.dexterous.** { *; }

# Enum'lar bazı kütüphanelerde reflection ile (valueOf/values) kullanılır —
# üyeleri korumak kod boyutunu neredeyse hiç etkilemez, genel güvenlik ağı.
-keepclassmembers enum * { *; }

# Firebase / Play Services / AdMob / Play Billing / Gson kendi AAR'larında
# kendi consumer-proguard kurallarını taşıyor (R8 bunları otomatik okur) —
# burada ayrıca -keep yazmıyoruz; sadece build sırasında o kütüphanelerin
# optional/platforma özel sınıflarını bulamazsa R8'in hata vermemesi için:
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn com.google.ads.**
-dontwarn com.android.billingclient.**
-dontwarn com.google.gson.**
