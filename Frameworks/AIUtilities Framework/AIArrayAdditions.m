//
//  AIArrayAdditions.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 2/15/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIArrayAdditions.h"

@implementation NSArray (AIArrayAdditions)

- (BOOL)containsObjectIdenticalTo:(id)obj
{
	return ([self indexOfObjectIdenticalTo:obj] != NSNotFound);
}

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

@implementation NSMutableArray (ESArrayAdditions)

- (void)moveObject:(id)object toIndex:(unsigned)newIndex
{
	unsigned	currentIndex = [self indexOfObject:object];
	NSAssert3(currentIndex != NSNotFound, @"%@ %p does not contain object %p", NSStringFromClass([self class]), self, object);
	
	//if we're already there, do no work
	if(currentIndex == newIndex) return;
	
	//Account for shifting
	if(currentIndex <  newIndex) newIndex--;
	
	//Move via a remove and add :(
	[object retain];
	[self removeObject:object];
	[self insertObject:object atIndex:newIndex];
	[object release];
}

@end
