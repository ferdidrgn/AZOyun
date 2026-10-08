// android/build.gradle.kts

plugins {
    // Flutter SDK's FlutterPlugin, AGP 9.1.1'e karşı derleniyor.
    id("com.android.application") version "9.1.1" apply false

    // AGP 9.1, Kotlin 2.2.20 ile uyumsuz; Flutter şablonu 2.4.20 istiyor.
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
