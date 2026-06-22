# R8 / ProGuard keep rules for the release build.
#
# The Flutter Gradle plugin already contributes engine keep rules, but plugins
# that rely on reflection (audioplayers -> ExoPlayer/Media3) need explicit
# rules so R8 does not strip classes that are only referenced dynamically.
# These rules are intentionally narrow; broaden only if a release smoke test
# surfaces a missing-class crash.

# --- Flutter embedding ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- audioplayers (uses ExoPlayer / AndroidX Media3 via reflection) ---
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
