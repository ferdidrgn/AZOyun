# Bu dosya release build için minifyEnabled + shrinkResources açıkken
# (bkz. app/build.gradle.kts) R8'in reflection ile erişilen sınıfları
# yanlışlıkla silmesini/obfuscate etmesini önler.
#
# ÖNEMLİ: Bu dosya daha önce boştu. Sonuç: uygulama "flutter run" ile veya
# yerel olarak kurulan bir APK ile sorunsuz çalışıyor, ama Play Store'dan
# indirilen (signed, minified) sürümde R8 bu paketlerin reflection/native
# köprü ile çağırdığı sınıfları silip uygulamayı açılışta çökertiyor.
# Bu, Flutter + Firebase + Play Services tabanlı uygulamalarda çok bilinen
# bir sorun.

# Gerekli attribute'lar — reflection, generic tip bilgisi ve annotation'lara
# bağımlı tüm kütüphaneler (Firebase, Gson, Play Services) için gerekli.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable

# --- Flutter ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# --- Play Core / deferred components ---
# Flutter'ın embedding'i Play Store'dan kurulan APK'larda bu sınıflara
# (varsa) başvurur; R8 bunları native/isteğe bağlı bağımlılık olarak
# görüp silebilir, bu da "sadece Play Store'dan indirince çöküyor" semptomunun
# klasik sebebidir.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- Google Play Services / Play Games Services v2 ---
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# --- Firebase (Core, Database, Messaging, Analytics, Crashlytics) ---
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# --- Google Mobile Ads (AdMob) ---
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.ads.**

# --- Play Billing (in_app_purchase) ---
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# --- flutter_local_notifications ---
# Bildirim/alarm yeniden planlama BroadcastReceiver'ları ve zaman dilimi
# verisi reflection ile kullanılır; silinirse bildirimler ya da (bu paketin
# init sırasında çağrılan) zaman dilimi okuma kodu çöker.
-keep class com.dexterous.** { *; }

# --- Gson (Firebase/Play Services tarafından dahili olarak kullanılır) ---
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Enum'lar reflection ile (valueOf/values) kullanılabiliyor — genel güvenlik
# ağı olarak enum sınıflarının üyelerini koru.
-keepclassmembers enum * { *; }
