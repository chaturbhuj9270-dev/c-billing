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

# Cashfree SDK (kept for non-Play channels; unused on Android Play path)
-keep class com.cashfree.** { *; }
-dontwarn com.cashfree.**

# Play Billing
-keep class com.android.vending.billing.** { *; }

# Gson / reflection helpers some plugins use
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn javax.annotation.**
