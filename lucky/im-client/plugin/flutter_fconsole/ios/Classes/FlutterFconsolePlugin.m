#import "FlutterFconsolePlugin.h"
#if __has_include(<flutter_fconsole/flutter_fconsole-Swift.h>)
#import <flutter_fconsole/flutter_fconsole-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_fconsole-Swift.h"
#endif

@implementation FlutterFconsolePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterFconsolePlugin registerWithRegistrar:registrar];
}
@end
