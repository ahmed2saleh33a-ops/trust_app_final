// android/build.gradle.kts

// لا تضيف أي plugins هنا — الإصدارات تُدار من settings.gradle.kts فقط.
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

// ✅ لا حاجة لـ Google Services لأن المشروع لا يستخدم Firebase
buildscript {
    repositories {
        google()
        mavenCentral()
        // ضروري لبعض إضافات Flutter
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
    dependencies {
        // ✅ لا توجد dependencies مطلوبة هنا
    }
}

/**
 * ✅ مهم: نفس المستودعات القياسية فقط
 */
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

// اجعل build/ على مستوى الجذر لتقليل حجم المجلدات داخل android/
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // ✅ تأكد أيضًا أن كل subproject لديه نفس المستودعات
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }

    // وجّه buildDir لكل موديول تحت build/الجذر
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    layout.buildDirectory.value(newSubprojectBuildDir)

    // تأكَّد أن app يتقيّم أولاً (إن وُجد)
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

// مهمة clean الموحّدة
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}