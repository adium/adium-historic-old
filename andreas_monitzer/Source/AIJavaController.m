//
//  AIJavaController.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-31.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "AIJavaController.h"
#import <JavaVM/NSJavaVirtualMachine.h>

@interface JavaVector : NSObject {
}

- (void)add:(id)obj;
- (NSString*)toString;

@end

@protocol JavaCocoaAdapter
- (JavaClassLoader*)classLoader:(JavaVector*)jars;
@end

@implementation AIJavaController

/*!
* @brief Controller loaded
 */
- (void)controllerDidLoad
{
}

/*!
* @brief Controller will close
 */
- (void)controllerWillClose
{
}

- (JavaClassLoader*)classLoaderWithJARs:(NSArray*)jararray
{
    if(!vm)
    {
        vm = [[NSJavaVirtualMachine alloc] initWithClassPath:[NSJavaVirtualMachine defaultClassPath]];
        // dynamically load class file
        JavaCocoaAdapter = [vm defineClass:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"JavaCocoaAdapter" ofType:@"class"]] withName:@"net/adium/JavaCocoaAdapter"];
        NSLog(@"JavaCocoaAdapter = %@", JavaCocoaAdapter);
    }
    
    // conver NSArray to java.util.Vector
    JavaVector *vec = [[vm findClass:@"java.util.Vector"] newWithSignature:@"(I)",[jararray count]];
    
    NSEnumerator *e = [jararray objectEnumerator];
    NSString *path;
    while((path = [e nextObject]))
        [vec add:path];
    
    JavaClassLoader *result = [JavaCocoaAdapter classLoader:vec];
    [vec release];
    
    return result;
}

@end
