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
# yalnızca uygulamanın ihtiyaç duyduğu dar kapsamlı kuralları ekliyoruz.

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

# --- AndroidX Room / WorkManager ---
# GERÇEK ÇÖKME (Play Console pre-launch raporu, "16 KB sayfa boyutu" diye
# etiketlense de sayfa boyutuyla ilgisi yok — o test cihazında rastlandı
# diye öyle sınıflandırılmış):
#   java.lang.RuntimeException: Failed to create an instance of
#   androidx.work.impl.WorkDatabase (androidx.startup.InitializationProvider
#   -> WorkManagerInitializer, uygulama açılışında, Flutter hiç devreye
#   girmeden çöküyor)
# Room, *_Impl veritabanı sınıflarını (WorkManager'ın kendi dahili
# WorkDatabase'i dahil) reflection ile no-arg constructor üzerinden
# oluşturuyor; Room'un kendi consumer-rules'u sınıf adını korusa da R8 bu
# constructor'ı silebiliyor. androidx.work muhtemelen Firebase/Play Core
# üzerinden transitive geliyor, pubspec'te doğrudan bir bağımlılık değil.
-keep class * extends androidx.room.RoomDatabase {
    <init>(...);
}
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class * extends androidx.work.impl.WorkDatabase { *; }
-dontwarn androidx.room.**
-dontwarn androidx.work.**

# Firebase manifestten okuduğu registrar sınıflarını parametresiz constructor
# ile oluşturur. Release açılışında bu constructor silinince Crashlytics
# kaydedilemedi ve Firebase.initializeApp() ilk Flutter karesinden önce durdu.
-keep,allowoptimization class com.google.firebase.** implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}

# İsteğe bağlı veya platforma özel bağımlılıklar için derleme uyarıları.
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
-dontwarn com.google.ads.**
-dontwarn com.android.billingclient.**
-dontwarn com.google.gson.**
