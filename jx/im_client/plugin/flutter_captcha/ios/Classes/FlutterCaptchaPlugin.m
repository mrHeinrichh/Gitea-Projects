#import "FlutterCaptchaPlugin.h"
#if __has_include(<flutter_captcha/flutter_captcha-Swift.h>)
#import <flutter_captcha/flutter_captcha-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_captcha-Swift.h"
#endif

@implementation FlutterCaptchaPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterCaptchaPlugin registerWithRegistrar:registrar];
}
@end
