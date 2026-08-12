import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase
    id("com.google.gms.google-services")
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

            // 🔥 Crashlytics mapping
            /*firebaseCrashlytics {
                mappingFileUploadEnabled = true
                nativeSymbolUploadEnabled = true
            }*/
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-database")
}
