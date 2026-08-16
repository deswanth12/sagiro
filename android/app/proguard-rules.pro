# Flutter engine and Sagiro app classes
-keep class io.flutter.** { *; }
-keep class com.deshu.sagiro.app.** { *; }
-keepattributes *Annotation*
-dontwarn io.flutter.**

# Plugin keeps for native JNI and reflection
-keep class com.tekartik.sqflite.** { *; }
-keep class com.it_del.flutter_secure_storage.** { *; }
-keep class com.doobooloo.paypack.** { *; }
-keep class com.android.billingclient.api.** { *; }

# Preserve SQLite and cryptographic helpers
-keep class java.security.** { *; }
-keep class javax.crypto.** { *; }

# Suppress obsolete R8 consumer rule warnings from legacy toolchain transforms
-dontwarn com.android.tools.r8.**
