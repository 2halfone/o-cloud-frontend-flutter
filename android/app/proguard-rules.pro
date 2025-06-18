# QR Code Scanner rules
-keep class com.github.jaiimageio.** { *; }
-dontwarn javax.imageio.**
-dontwarn com.github.jaiimageio.**

# HTTP and networking
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# Flutter Secure Storage
-keep class io.flutter.plugins.flutter_secure_storage.** { *; }

# Image picker
-keep class io.flutter.plugins.image_picker.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# General Flutter rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
