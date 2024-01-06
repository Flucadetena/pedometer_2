#import "PedometerPlugin.h"
#if __has_include(<pedometer_plus/pedometer_plus-Swift.h>)
#import <pedometer_plus/pedometer_plus-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "pedometer_plus-Swift.h"
#endif

@implementation PedometerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPedometerPlugin registerWithRegistrar:registrar];
}
@end
