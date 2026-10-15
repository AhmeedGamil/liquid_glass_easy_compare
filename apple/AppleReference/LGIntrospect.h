#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Reads the properties a class declares, for the frame tracer. Lives in
/// Objective-C so a getter that throws is caught instead of killing the app.
@interface LGIntrospect : NSObject

/// Names of the printable properties declared from cls up to (not
/// including) the first class in stops: numbers, geometry structs, strings
/// and anything named like a shape or a corner.
+ (NSArray<NSString *> *)printablePropertiesOf:(Class)cls stopAt:(NSArray<Class> *)stops
    NS_SWIFT_NAME(printableProperties(of:stopAt:));

/// The property's value as short text, or nil when reading it throws.
+ (nullable NSString *)textFor:(id)object key:(NSString *)key
    NS_SWIFT_NAME(text(for:key:));

@end

NS_ASSUME_NONNULL_END
