# Flutter Callkit Incoming ProGuard Rules
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-dontwarn com.hiennv.flutter_callkit_incoming.**

# Firebase Messaging ProGuard Rules
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-dontwarn io.flutter.plugins.firebase.messaging.**

# Flutter Local Notifications ProGuard Rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# WebRTC ProGuard Rules
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.** { *; }
-dontwarn com.cloudwebrtc.webrtc.**
-dontwarn org.webrtc.**

# Flutter Engine & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App Components & Services
-keep class com.sdpi.schat.MainActivity { *; }
-keep class com.sdpi.schat.MainApplication { *; }
-keep class com.sdpi.schat.ScreenRecordService { *; }
-keep class com.sdpi.schat.ScreenRecordService$* { *; }

# Google Play Services & Maps
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Core (deferred components referenced by Flutter engine)
-dontwarn com.google.android.play.core.**

# LiveKit & Audio
-keep class io.livekit.** { *; }
-dontwarn io.livekit.**

# ScreenProtector
-keep class com.prongbang.screen_protector.** { *; }
-dontwarn com.prongbang.screen_protector.**

# Preserve attributes for stack traces & reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

