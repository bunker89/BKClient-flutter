#import "BkclientFlutterPlugin.h"
#if __has_include(<bkclient_flutter/bkclient_flutter-Swift.h>)
#import <bkclient_flutter/bkclient_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "bkclient_flutter-Swift.h"
#endif

@implementation BkclientFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBkclientFlutterPlugin registerWithRegistrar:registrar];
}
@end
