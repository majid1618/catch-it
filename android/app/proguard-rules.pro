# Flutter rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep classes used by reflection
-keepclasseswithmembers class * {
    native <methods>;
}

# General Android rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep generated plugin registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep classes referenced in AndroidManifest.xml
-keep class com.majid.catch_it.MainActivity { *; }
