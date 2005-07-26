//
//  AIDictionaryDebug.m
//  Adium
//
//  Created by Evan Schoenberg on 7/26/05.
//

#import "AIDictionaryDebug.h"

@interface AIDictionaryDebug (PRIVATE)
#ifdef DEBUG_BUILD
	+ (IMP)replaceSelector:(SEL)sel ofClass:(Class)oldClass withClass:(Class)newClass;
#endif
@end

@implementation AIDictionaryDebug

#ifdef DEBUG_BUILD

typedef void (*SetObjectForKeyIMP)(id, SEL, id, id);
SetObjectForKeyIMP	originalSetObjectForKey = nil;

struct objc_method
{
	SEL method_name;
	char * method_types;
	IMP method_imp;
};

struct objc_method *class_getInstanceMethod(Class aClass, SEL aSelector);
void _objc_flush_caches(Class);

+ (void)load
{
	originalSetObjectForKey = (SetObjectForKeyIMP)[AIDictionaryDebug replaceSelector:@selector(setObject:forKey:)
																			 ofClass:NSClassFromString(@"NSCFDictionary")
																		   withClass:[AIDictionaryDebug class]];
}

- (void)setObject:(id)object forKey:(id)key
{
	NSAssert3(object != nil, @"%@: Attempted to set %@ for %@",self,object,key);
	NSAssert3(key != nil, @"%@: Attempted to set %@ for %@",self,object,key);

	originalSetObjectForKey(self, @selector(setObject:forKey:),object,key);
}

+ (IMP)replaceSelector:(SEL)sel ofClass:(Class)oldClass withClass:(Class)newClass
{
    IMP original = [oldClass instanceMethodForSelector:sel];

	if (!original) {
		NSLog(@"Cannot find implementation for '%@' in %@",
			  NSStringFromSelector(sel),
			  NSStringFromClass(oldClass));
		return NULL;
	}

    struct objc_method *method = class_getInstanceMethod(oldClass, sel); 

	// original to change
    if (!method) {
        NSLog(@"Cannot find method for '%@' in %@",
			  NSStringFromSelector(sel),
			  NSStringFromClass(oldClass));
        return NULL;
    }

    IMP new = [newClass instanceMethodForSelector:sel]; // new method to use
	if (!new) {
		NSLog(@"Cannot find implementation for '%@' in %@",
			  NSStringFromSelector(sel),
			  NSStringFromClass(newClass));
		return NULL;
	}

    method->method_imp = new;

    _objc_flush_caches(oldClass);

    return original;
}

#endif
@end
