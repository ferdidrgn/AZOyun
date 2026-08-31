import java.util.Properties
import java.io.FileInputStream
import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// 🔐 Keystore properties yükleme (Kotlin DSL)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ferdidrgn.azgame"
    compileSdk = flutter.compileSdkVersion
    // Firebase / AdMob / Games Services gibi native eklentiler flutter.ndkVersion'ın
    // sağladığından daha yeni bir NDK istiyor; sabit, güncel bir sürüme pinliyoruz.
    // Android Studio > SDK Manager > SDK Tools > NDK (Side by side) kısmından bu
    // sürümün kurulu olduğundan emin ol.
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.ferdidrgn.azgame"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 🔐 Signing Config (Kotlin DSL)
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // 🔥 Crashlytics mapping — obfuscate edilmiş (R8) çökme
            // raporlarının okunabilir hale gelmesi için ProGuard mapping
            // dosyasını otomatik yükler (bkz. ROADMAP 8.3'teki bitmap
            // uyarısı notu — bu, o tür sorunları da netleştirir).
            // Not: build type lambda'sı içinde bare "firebaseCrashlytics {}"
            // çağrısı yanlış receiver'a (android bloğunun kendisine) bağlanır
            // — Firebase'in Kotlin DSL için resmi kurulumu, build type'a özel
            // ayar için configure<CrashlyticsExtension> kullanılmasını ister.
            configure<CrashlyticsExtension> {
                mappingFileUploadEnabled = true
                nativeSymbolUploadEnabled = true
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications, Java 8+ API'lerini (java.time vb.)
        // eski Android sürümlerinde kullanabilmek için bunu istiyor.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // flutter_local_notifications'ın istediği core library desugaring için
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-database")
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")

    // Play Games Services v2 (bkz. ROADMAP 8.7) — games_services Flutter
    // eklentisi 4.x'ten beri bunu transitive olarak getiriyor, ama
    // MainActivity.kt içinde PlayGamesSdk.initialize() çağırabilmek için
    // burada da açıkça tanımlanması gerekiyor (Google'ın resmi kurulum
    // adımı da bu şekilde).
    implementation("com.google.android.gms:play-services-games-v2:+")
}
