# ============================================
# قواعد إضافية لـ Flutter ومكتباته
# ============================================

# Flutter الأساسي
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# مكتبات Flutter الشائعة
-keep class com.google.** { *; }
-dontwarn com.google.**
-keep class org.chromium.** { *; }
-dontwarn org.chromium.**

# منع إزالة الدوال المستخدمة عبر JNI
-keepclasseswithmembers class * {
    @io.flutter.plugin.common.MethodCall <methods>;
}

-keepclasseswithmembers class * {
    @io.flutter.plugin.common.EventChannel <methods>;
}

-keepclasseswithmembers class * {
    @io.flutter.embedding.engine.plugins.FlutterPlugin <methods>;
}