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
    
    return [array autorelease];
}

- (NSComparisonResult)compare:(NSArray *)other
{
	NSComparisonResult result = NSOrderedSame;

	NSEnumerator *selfEnum = [self objectEnumerator], *otherEnum = [other objectEnumerator];
	id selfObj, otherObj = nil;
	while ((result == NSOrderedSame) && (selfObj = [selfEnum nextObject]) && (otherObj = [otherEnum nextObject])) {
		result = [selfObj compare:otherObj];
	}

	if (result == NSOrderedSame) {
		if (selfObj && !otherObj) {
			result = NSOrderedDescending;
		} else if(otherObj && !selfObj) {
			result = NSOrderedAscending;
		}
	}

	return result;
}

@end

@implementation NSMutableArray (ESArrayAdditions)

- (void)addObjectsFromArrayIgnoringDuplicates:(NSArray *)inArray
{
	NSEnumerator	*enumerator = [inArray objectEnumerator];
	id				object;
	
	while ((object = [enumerator nextObject])) {
		if (![self containsObject:object]) [self addObject:object];
	}
}

- (void)moveObject:(id)object toIndex:(unsigned)newIndex
{
	unsigned	currentIndex = [self indexOfObject:object];
	NSAssert3(currentIndex != NSNotFound, @"%@ %p does not contain object %p", NSStringFromClass([self class]), self, object);
	
	//if we're already there, do no work
	if (currentIndex == newIndex) return;
	
	//Account for shifting
	if (currentIndex <  newIndex) newIndex--;
	
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

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes
{
	int count = [indexes count];
	unsigned int* buffer = (unsigned int *)malloc(count * sizeof(unsigned));
	[indexes getIndexes:(unsigned int *)buffer maxCount:count inIndexRange:nil];
	[self removeObjectsFromIndices:buffer numIndices:count];
	free(buffer);
}

@end
