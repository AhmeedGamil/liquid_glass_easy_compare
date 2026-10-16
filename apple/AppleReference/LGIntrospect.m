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

static void LGWalkIvars(id object, NSString *path, int depth, NSMutableSet *visited,
                        NSMutableDictionary<NSString *, NSString *> *out);

static NSString *LGScalarText(const char *type, const void *at) {
    switch (type[0]) {
        case 'd': return [NSString stringWithFormat:@"%.6g", *(const double *)at];
        case 'f': return [NSString stringWithFormat:@"%.6g", *(const float *)at];
        case 'q': return [NSString stringWithFormat:@"%lld", *(const long long *)at];
        case 'Q': return [NSString stringWithFormat:@"%llu", *(const unsigned long long *)at];
        case 'i': return [NSString stringWithFormat:@"%d", *(const int *)at];
        case 'I': return [NSString stringWithFormat:@"%u", *(const unsigned int *)at];
        case 's': return [NSString stringWithFormat:@"%d", *(const short *)at];
        case 'c': return [NSString stringWithFormat:@"%d", *(const signed char *)at];
        case 'C': return [NSString stringWithFormat:@"%u", *(const unsigned char *)at];
        case 'B': return *(const bool *)at ? @"1" : @"0";
        case '{':
            if (LGAllDoubles(type)) {
                NSUInteger size = 0;
                NSGetSizeAndAlignment(type, &size, NULL);
                if (size % sizeof(double) == 0 && size <= 32 * sizeof(double)) {
                    NSMutableArray *parts = [NSMutableArray array];
                    for (NSUInteger i = 0; i < size / sizeof(double); i++) {
                        [parts addObject:[NSString stringWithFormat:@"%.6g", ((const double *)at)[i]]];
                    }
                    return [parts componentsJoinedByString:@" "];
                }
            }
            return nil;
        default: return nil;
    }
}

static void LGWalkObject(id value, NSString *path, int depth, NSMutableSet *visited,
                         NSMutableDictionary<NSString *, NSString *> *out) {
    if (value == nil) { out[path] = @"nil"; return; }
    if ([value isKindOfClass:NSNumber.class]) { out[path] = LGText(value); return; }
    if ([value isKindOfClass:NSString.class]) {
        NSString *s = value;
        out[path] = s.length > 80 ? [s substringToIndex:80] : s;
        return;
    }
    if ([value isKindOfClass:NSValue.class]) { out[path] = LGText(value); return; }
    out[[path stringByAppendingString:@".class"]] = NSStringFromClass([value class]);
    Class view = NSClassFromString(@"UIView"), layer = NSClassFromString(@"CALayer");
    if ((view && [value isKindOfClass:view]) || (layer && [value isKindOfClass:layer])) return;
    if (depth <= 0) return;
    NSValue *key = [NSValue valueWithNonretainedObject:value];
    if ([visited containsObject:key]) return;
    [visited addObject:key];
    if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSSet.class] ||
        [value isKindOfClass:NSOrderedSet.class]) {
        NSArray *items = [value isKindOfClass:NSArray.class] ? value : [value allObjects];
        out[[path stringByAppendingString:@".count"]] = [NSString stringWithFormat:@"%lu", (unsigned long)items.count];
        for (NSUInteger i = 0; i < MIN(items.count, (NSUInteger)6); i++) {
            LGWalkObject(items[i], [NSString stringWithFormat:@"%@[%lu]", path, (unsigned long)i], depth - 1, visited, out);
        }
        return;
    }
    if ([value isKindOfClass:NSDictionary.class]) {
        NSDictionary *d = value;
        out[[path stringByAppendingString:@".count"]] = [NSString stringWithFormat:@"%lu", (unsigned long)d.count];
        NSUInteger i = 0;
        for (id k in d) {
            if (i++ >= 6) break;
            LGWalkObject(d[k], [NSString stringWithFormat:@"%@[%@]", path, [k description]], depth - 1, visited, out);
        }
        return;
    }
    LGWalkIvars(value, path, depth - 1, visited, out);
}

static void LGWalkIvars(id object, NSString *path, int depth, NSMutableSet *visited,
                        NSMutableDictionary<NSString *, NSString *> *out) {
    if (out.count > 4000) return;
    Class view = NSClassFromString(@"UIView"), responder = NSClassFromString(@"UIResponder"),
          layer = NSClassFromString(@"CALayer");
    for (Class c = object_getClass(object); c != Nil && c != NSObject.class && c != view &&
         c != responder && c != layer; c = class_getSuperclass(c)) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList(c, &count);
        for (unsigned int i = 0; i < count; i++) {
            const char *name = ivar_getName(ivars[i]);
            const char *type = ivar_getTypeEncoding(ivars[i]);
            if (name == NULL || type == NULL || type[0] == '\0') continue;
            NSString *p = [NSString stringWithFormat:@"%@.%s", path, name];
            if (type[0] == '@') {
                @try {
                    id v = object_getIvar(object, ivars[i]);
                    LGWalkObject(v, p, depth, visited, out);
                } @catch (NSException *e) {
                }
                continue;
            }
            const void *at = (const char *)(__bridge void *)object + ivar_getOffset(ivars[i]);
            NSString *text = LGScalarText(type, at);
            if (text) out[p] = text;
        }
        free(ivars);
    }
}

@implementation LGIntrospect

+ (NSDictionary<NSString *, NSString *> *)ivarsOf:(id)object path:(NSString *)path depth:(int)depth {
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    @try {
        LGWalkIvars(object, path, depth, [NSMutableSet set], out);
    } @catch (NSException *e) {
    }
    return out;
}

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
