//
//  AIJavaController.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-31.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIObject.h"

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

@end

@interface JavaClassLoader : NSObject {
}

// param format: http://java.sun.com/j2se/1.5.0/docs/api/java/lang/ClassLoader.html#name
- (JavaClass*)loadClass:(NSString*)classname;

@end

@class NSJavaVirtualMachine;

@interface AIJavaController : AIObject <AIController> {
    NSJavaVirtualMachine *vm;
    Class JavaCocoaAdapter;
}

- (JavaClassLoader*)classLoaderWithJARs:(NSArray*)jars; // NSArray of file paths (NSString)

@end
