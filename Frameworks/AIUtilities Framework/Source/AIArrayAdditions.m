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

- (void)addObjectsFromArrayIgnoringDuplicates:(NSArray *)inArray
{
	NSEnumerator	*enumerator = [inArray objectEnumerator];
	id				object;
	
	while((object = [enumerator nextObject])){
		if(![self containsObject:object]) [self addObject:object];
	}
}

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

//just a better name for an existing NSMutableArray method.
//this makes it uniform in style with -[NSMutableDictionary setObject:forKey:].
- (void)setObject:(id)object atIndex:(unsigned)index
{
	[self replaceObjectAtIndex:index withObject:object];
}

@end
