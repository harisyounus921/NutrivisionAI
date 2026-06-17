# flutter_local_notifications uses Gson to (de)serialize scheduled
# notifications. R8 (enabled by default for release builds) strips the generic
# type signatures Gson's TypeToken depends on, causing a release-only crash:
#   PlatformException(error, Missing type parameter., ...)
#     at com.dexterous.flutterlocalnotifications...loadScheduledNotifications
# Keeping the plugin classes and the Signature/annotation attributes fixes it.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses, EnclosingMethod

# Gson — preserve generic TypeToken info and @SerializedName fields.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**
