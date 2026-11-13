# ==== Keep rules for video_compress / light_compressor ====
-keep class com.abedelazizshe.lightcompressor.** { *; }
-dontwarn com.abedelazizshe.lightcompressor.**

# ==== ExoPlayer (video_player) ====
# بعض الأجزاء تُستخدم عبر reflection؛ الحفاظ عليها يمنع كراشات في الإصدار
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# ==== Kotlin / AndroidX ====
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class androidx.** { *; }
-dontwarn androidx.**
# مفيد أحياناً مع الـ metadata
-keep class kotlin.Metadata { *; }

# ==== Coroutines (تُستخدم بكثرة في المكتبات الحديثة) ====
-dontwarn kotlinx.coroutines.**

# ==== OkHttp/Okio (مستخدمة عبر http/Supabase) ====
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# ==== kotlinx.serialization (قد تظهر مع Supabase) ====
-keepattributes *Annotation*
-keep class kotlinx.serialization.** { *; }
-keepclassmembers class ** {
    @kotlinx.serialization.Serializable *;
}

# ==== Flutter auto-generated classes ====
-keep class **.R { *; }
-keep class **.R$* { *; }
-keep class **.BuildConfig { *; }
