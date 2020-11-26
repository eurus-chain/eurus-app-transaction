#import "TransactionPlugin.h"
#if __has_include(<transaction/transaction-Swift.h>)
#import <transaction/transaction-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "transaction-Swift.h"
#endif

@implementation TransactionPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTransactionPlugin registerWithRegistrar:registrar];
}
@end
