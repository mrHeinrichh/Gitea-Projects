#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
#baidu
-keep class com.baidu.location.** {*;}
-keep class com.baidu.** {*;}
-keep class vi.com.** {*;}
-keep class com.baidu.vi.** {*;}
-dontwarn com.baidu.**

-keep class org.jetbrains.kotlin.** { *; }
-keep class androidx.camera.** { *; }
-keep class dev.steenbakker.mobile_scanner.** {*;}
-keep class com.google.mlkit.** {*;}
-keep class com.kiwi.sdk.**{*;}

-ignorewarnings
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keep class com.huawei.hianalytics.**{*;}
-keep class com.huawei.updatesdk.**{*;}
-keep class com.huawei.hms.**{*;}
-keep class org.videolan.libvlc.** {*;}

-dontwarn com.videocall.**
-keep class com.videocall.** { *; }

-dontwarn com.nb.rtc.**
-keep class com.nb.rtc.** { *; }
-dontwarn org.webrtc.**
-keep class org.webrtc.** { *; }
-keep class org.whispersystems.**{*;}
-keep class com.bumptech.glide.** {*;}
#flutter git混淆
-keep class com.neo.flutter_git.** {*;}
-dontwarn aidl.**
-keep class aidl.** { *; }
#Rxjava RxAndroid 代码混淆
-dontwarn sun.misc.**
-keepclassmembers class rx.internal.util.unsafe.*ArrayQueue*Field* {
long producerIndex;
long consumerIndex;
}
-keep class android.src.main.kotlin.com.jximrtc.flutter_rtc_call.models.** { *; }
-keepclassmembers class rx.internal.util.unsafe.BaseLinkedQueueProducerNodeRef {
rx.internal.util.atomic.LinkedQueueNode producerNode;
}
-keepclassmembers class rx.internal.util.unsafe.BaseLinkedQueueConsumerNodeRef {
rx.internal.util.atomic.LinkedQueueNode consumerNode;
}
