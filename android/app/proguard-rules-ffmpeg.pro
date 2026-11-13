# ============================================
# قواعد خاصة بـ FFmpegKit للنظام الجديد
# ============================================

-keep class com.arthenica.** { *; }
-keep interface com.arthenica.** { *; }
-keep enum com.arthenica.** { *; }
-dontwarn com.arthenica.**
-dontnote com.arthenica.**

# مكتبات FFmpeg الأصلية
-keep class org.bytedeco.** { *; }
-dontwarn org.bytedeco.**
-keep class org.bytedeco.ffmpeg.** { *; }
-dontwarn org.bytedeco.ffmpeg.**

# مكتبات الترميز
-keep class org.bytedeco.javacpp.** { *; }
-dontwarn org.bytedeco.javacpp.**

# الحفاظ على التوافق
-keepattributes Exceptions, Signature, Deprecated
-keep class **.R { *; }
-keep class **.R$* { *; }

# منع إزالة التوابع الهامة
-keepclasseswithmembers class * {
    native <methods>;
}

-keepclasseswithmembers class * {
    public <init>(...);
}