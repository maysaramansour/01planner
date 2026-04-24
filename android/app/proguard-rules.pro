# Keep flutter_local_notifications + Gson reflection types (fixes "Missing type parameter")
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep home_widget plugin
-keep class es.antonborri.home_widget.** { *; }

# Hive type adapters
-keep class * extends hive.TypeAdapter { *; }
