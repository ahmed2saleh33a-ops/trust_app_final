# ============================================
# قواعد خاصة بمكتبات الفيديو
# ============================================

# video_trimmer
-keep class com.example.video_trimmer.** { *; }
-dontwarn com.example.video_trimmer.**
-keep class bz.rxla.** { *; }
-dontwarn bz.rxla.**

# flutter_video_info
-keep class com.example.flutter_video_info.** { *; }
-dontwarn com.example.flutter_video_info.**

# video_thumbnail
-keep class wseemann.media.** { *; }
-dontwarn wseemann.media.**

# ExoPlayer وإضافاته
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# مكتبات الترميز الصوتي/المرئي
-keep class * extends android.media.MediaCodec { *; }
-keep class * extends android.media.MediaExtractor { *; }
-keep class * extends android.media.MediaMuxer { *; }

# مكتبات الفيديو
-keep class com.otaliastudios.** { *; }
-dontwarn com.otaliastudios.**
-keep class org.mp4parser.** { *; }
-dontwarn org.mp4parser.**