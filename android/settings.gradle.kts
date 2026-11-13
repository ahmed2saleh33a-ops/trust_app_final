// android/settings.gradle.kts

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    // استخدم أدوات Flutter Gradle من الـ SDK
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // مستودعات للبلاجنز
        google()
        mavenCentral()
        gradlePluginPortal()
        // مستودع Flutter للـ artifacts (لبعض البلغنز)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // ✅ تم تحديث AGP إلى أحدث إصدار مستقر 8.9.1
    id("com.android.application") version "8.9.1" apply false
    // ✅ تم تحديث Kotlin إلى إصدار 2.1.0 (أحدث إصدار مستقر)
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

dependencyResolutionManagement {
    // نُفضّل مستودعات هذا الملف
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)

    repositories {
        google()
        mavenCentral()
        // مستودع Flutter
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

include(":app")