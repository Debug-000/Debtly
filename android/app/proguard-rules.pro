# Keep generic type signatures and annotation metadata.
# This is critical for Gson TypeToken deserialization used by
# flutter_local_notifications scheduled notification persistence.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep Gson TypeToken and subclasses.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep flutter_local_notifications internals used for scheduling.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep classes and fields annotated for Gson serialization.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep enum names for JSON compatibility.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
