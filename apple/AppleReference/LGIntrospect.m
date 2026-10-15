#import "LGIntrospect.h"
#import <objc/runtime.h>

static BOOL LGNamedLikeGeometry(NSString *name) {
    for (NSString *word in @[@"Shape", @"Corner", @"Radi", @"SDF", @"Glass", @"Lens"]) {
        if ([name rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    }
    return NO;
}

static BOOL LGPrintable(NSString *type) {
    if (type.length == 1) return [@"cislqCISLQfdB" containsString:type];
    if ([type hasPrefix:@"{"]) return YES;
    if ([type hasPrefix:@"@\""]) {
        NSString *cls = [type substringWithRange:NSMakeRange(2, type.length - 3)];
        return [@[@"NSNumber", @"NSString", @"NSValue"] containsObject:cls] || LGNamedLikeGeometry(cls);
    }
    return NO;
}

/// Whether a struct encoding holds only doubles, e.g. {CGRect={CGPoint=dd}{CGSize=dd}}.
static BOOL LGAllDoubles(const char *type) {
    BOOL any = NO;
    for (const char *c = type; *c; c++) {
        if (*c == '{') {
            while (*c && *c != '=') c++;
            if (!*c) return NO;
        } else if (*c == 'd') {
            any = YES;
        } else if (*c != '}') {
            return NO;
        }
    }
    return any;
}

static NSString *LGText(id value) {
    if (value == nil || value == NSNull.null) return @"nil";
    if ([value isKindOfClass:NSNumber.class]) {
        NSNumber *n = value;
        const char *t = n.objCType;
        if (strcmp(t, "f") == 0 || strcmp(t, "d") == 0) return [NSString stringWithFormat:@"%.4g", n.doubleValue];
        return n.stringValue;
    }
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value isKindOfClass:NSValue.class]) {
        NSValue *v = value;
        NSUInteger size = 0;
        NSGetSizeAndAlignment(v.objCType, &size, NULL);
        if (size > 0 && size % sizeof(double) == 0 && size <= 32 * sizeof(double) && LGAllDoubles(v.objCType)) {
            double buf[32];
            [v getValue:buf size:size];
            NSMutableArray *parts = [NSMutableArray array];
            for (NSUInteger i = 0; i < size / sizeof(double); i++) [parts addObject:[NSString stringWithFormat:@"%.4g", buf[i]]];
            return [parts componentsJoinedByString:@" "];
        }
        return v.description;
    }
    NSString *d = [value description];
    return d.length > 300 ? [d substringToIndex:300] : d;
}

@implementation LGIntrospect

+ (NSArray<NSString *> *)printablePropertiesOf:(Class)cls stopAt:(NSArray<Class> *)stops {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    NSSet *skip = [NSSet setWithArray:@[@"hash", @"superclass", @"description", @"debugDescription"]];
    for (Class c = cls; c != Nil && ![stops containsObject:c]; c = class_getSuperclass(c)) {
        unsigned int count = 0;
        objc_property_t *props = class_copyPropertyList(c, &count);
        for (unsigned int i = 0; i < count; i++) {
            NSString *name = @(property_getName(props[i]));
            const char *attrs = property_getAttributes(props[i]);
            if (attrs == NULL || [skip containsObject:name] || [names containsObject:name]) continue;
            NSString *type = [@(attrs) componentsSeparatedByString:@","].firstObject;
            if (type.length < 2) continue;
            if (LGPrintable([type substringFromIndex:1])) [names addObject:name];
        }
        free(props);
    }
    return names;
}

+ (nullable NSString *)textFor:(id)object key:(NSString *)key {
    @try {
        return LGText([object valueForKey:key]);
    } @catch (NSException *e) {
        return nil;
    }
}

@end
