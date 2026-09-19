# Flutter Wrapper
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.google.firebase.** { *; }

# Dart
-keep class dart.** { *; }

# Home screen widget
-keep class es.antonborri.home_widget.** { *; }
-keep class com.trufit.trufit_bodamma.TrufitWidgetProvider { *; }
-keep class * extends android.appwidget.AppWidgetProvider { *; }
