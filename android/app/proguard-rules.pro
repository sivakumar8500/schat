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
