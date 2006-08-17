/*
 *  AIJavaControllerProtocol.h
 *  Adium
 *
 *  Created by Andreas Monitzer on 2006-08-17.
 *
 */

#import <Adium/AIControllerProtocol.h>

@interface JavaField : NSObject {
}

- (id)get:(id)obj; // param is the instance, pass nil if it's a static field

@end

@interface JavaClass : NSObject {
}

- (BOOL)equals:(id)obj;
- (id)newInstance;
- (NSString*)toString;
- (BOOL)isInstace:(id)obj;
- (JavaField*)getField:(NSString*)name;

    // these are Java Bridge methods!
- (id)alloc;
- (id)newWithSignature:(NSString*)sig, ...;

@end

@interface JavaClassLoader : NSObject {
}

// param format: http://java.sun.com/j2se/1.5.0/docs/api/java/lang/ClassLoader.html#name
- (JavaClass*)loadClass:(NSString*)classname;

@end

@protocol AIJavaController <AIController>

- (JavaClassLoader*)classLoaderWithJARs:(NSArray*)jararray;
- (JavaClassLoader*)classLoaderWithJARs:(NSArray*)jararray parentClassLoader:(JavaClassLoader*)parent;

@end
