# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Hive
-keep class * extends hive.** { *; }
-keep class **.hive.** { *; }

# Fix Play Core missing classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
