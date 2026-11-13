# ============================================
# قواعد خفيفة للوضع التصحيحي
# ============================================

# لا تقم بتصغير الكود في الوضع التصحيحي
-dontobfuscate
-dontoptimize
-dontshrink
-dontpreverify

# أبقي على معلومات التصحيح
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# حافظ على أسماء الحزم
-keeppackagenames **

# حافظ على جميع الدوال
-keepclasseswithmembers class * {
    *;
}