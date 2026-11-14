# Flutter / Play release keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Play Billing
-keep class com.android.vending.billing.** { *; }

# Flutter references Play Core deferred-component APIs optionally.
# App does not use Play Feature Delivery — suppress R8 missing-class errors.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Gson / reflection helpers some plugins use
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn javax.annotation.**
