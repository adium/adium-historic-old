//
//  ESArrayAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Jan 10 2004.

#import "ESArrayAdditions.h"


@implementation NSArray (ESArrayAdditions)

// Returns an array from the owners bundle with the specified name
+ (NSArray *)arrayNamed:(NSString *)name forClass:(Class)inClass
{
    NSBundle		*ownerBundle;
    NSString		*arrayPath;
    NSDictionary	*array;
    
    //Get the bundle
    ownerBundle = [NSBundle bundleForClass:inClass];
    
    //Open the image
    arrayPath = [ownerBundle pathForResource:name ofType:@"plist"];    
    array = [[NSArray alloc] initWithContentsOfFile:arrayPath];
    
    return([array autorelease]);
}
@end
