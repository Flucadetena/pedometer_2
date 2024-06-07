#import "PedometerPlugin.h"
#if __has_include(<pedometer_2/pedometer_2-Swift.h>)
#import <pedometer_2/pedometer_2-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "pedometer_2-Swift.h"
#endif

@implementation PedometerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [Pedometer_2Plugin registerWithRegistrar:registrar];
}
@end
