import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.ferdidrgn.azgame.wear"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.ferdidrgn.azgame"
        minSdk = 30
        targetSdk = 35
        // Keep Wear APK versioning independent from the phone form factor.
        versionCode = providers.gradleProperty("wearVersionCode").orElse("10000").get().toInt()
        versionName = providers.gradleProperty("wearVersionName").orElse("1.0.0").get()
    }

    signingConfigs {
        create("release") {
            val props = Properties()
            val propsFile = rootProject.file("key.properties")
            if (propsFile.exists()) {
                propsFile.inputStream().use { props.load(it) }
            }
            keyAlias = props["keyAlias"] as String
            keyPassword = props["keyPassword"] as String
            val storeFileName = props["storeFile"] as String
            storeFile = rootProject.file("app/$storeFileName")
            storePassword = props["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    buildFeatures { compose = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin { jvmToolchain(17) }

dependencies {
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.wear.compose:compose-material3:1.5.0")
    implementation("androidx.wear.compose:compose-foundation:1.5.0")
    implementation("androidx.wear:wear:1.3.0")
    implementation("androidx.wear:wear-remote-interactions:1.1.0")
    implementation("com.google.android.gms:play-services-wearable:20.0.1")
}
