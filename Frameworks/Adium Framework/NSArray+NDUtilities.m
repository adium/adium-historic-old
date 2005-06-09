/*
 *  NSArray+NDUtilities.m category
 *  AppleScriptRunner
 *
 *  Created by Nathan Day on Thu Jan 16 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NSArray+NDUtilities.h"

/*
 * category implementation NSArray (NDUtilities)
 */
@implementation NSArray (NDUtilities)

/*
 * -arrayByUsingFunction:
 */
- (NSArray *)arrayByUsingFunction:(id (*)(id, BOOL *))aFunc
{
	unsigned int		theIndex,
							theCount;
	NSMutableArray		* theResultArray;
	BOOL					theContinue = YES;

	theCount = [self count];
	theResultArray = [NSMutableArray arrayWithCapacity:theCount];

	for ( theIndex = 0; theIndex < theCount && theContinue == YES; theIndex++ )
	{
		id		theResult;
		
		theResult = aFunc([self objectAtIndex:theIndex], &theContinue );

		if ( theResult ) [theResultArray addObject:theResult];
	}

	return theResultArray;
}

/*
 * -everyObjectOfKindOfClass:
 */
- (NSArray *)everyObjectOfKindOfClass:(Class)aClass
{
	unsigned int		theIndex,
							theCount;
	NSMutableArray		* theResultArray;

	theCount = [self count];
	theResultArray = [NSMutableArray arrayWithCapacity:theCount];
	
	for ( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject;

		theObject = [self objectAtIndex:theIndex];

		if ( [theObject isKindOfClass:aClass] )
			[theResultArray addObject:theObject];
	}

	return theResultArray;
}

/*
 * -makeObjectsPerformFunction:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id))aFunc
{
	unsigned int		theIndex,
							theCount = [self count];
	
	for ( theIndex = 0; theIndex < theCount; theIndex++ )
		if ( !aFunc([self objectAtIndex:theIndex]) ) return NO;

	return YES;
}

/*
 * -makeObjectsPerformFunction:withContext:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, void *))aFunc withContext:(void *)aContext
{
	unsigned int		theIndex,
							theCount = [self count];

	for ( theIndex = 0; theIndex < theCount; theIndex++ )
		if ( !aFunc( [self objectAtIndex:theIndex], aContext ) ) return NO;

	return YES;
}

/*
 * -makeObjectsPerformFunction:withContext:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, id))aFunc withObject:(id)anObject
{
	unsigned int		theIndex,
							theCount = [self count];

	for ( theIndex = 0; theIndex < theCount; theIndex++ )
		if ( !aFunc( [self objectAtIndex:theIndex], anObject ) ) return NO;

	return YES;
}

/*
 * -findObjectWithFunction:
 */
- (id)findObjectWithFunction:(BOOL (*)(id))aFunc
{
	id						theFoundObject = nil;
	unsigned int		theIndex,
							theCount = [self count];

	for ( theIndex = 0; theIndex < theCount && theFoundObject == nil; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if ( aFunc( theObject ) )
				theFoundObject = theObject;
	}

	return theFoundObject;
}

/*
 * -findObjectWithFunction:withContext:
 */
- (id)findObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	id						theFoundObject = nil;
	unsigned int		theIndex,
		theCount = [self count];

	for ( theIndex = 0; theIndex < theCount && theFoundObject == nil; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if ( aFunc( theObject, aContext ) )
			theFoundObject = theObject;
	}

	return theFoundObject;
}

- (NSArray *)findAllObjectWithFunction:(BOOL (*)(id))aFunc
{
	NSMutableArray		* theFoundObjectArray = [NSMutableArray arrayWithCapacity:[self count]];
	unsigned int		theIndex,
							theCount = [self count];
	
	for ( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if ( aFunc( theObject ) )
			[theFoundObjectArray addObject:theObject];
	}
	
	return theFoundObjectArray;
}

- (NSArray *)findAllObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	NSMutableArray		* theFoundObjectArray = [NSMutableArray arrayWithCapacity:[self count]];
	unsigned int		theIndex,
		theCount = [self count];
	
	for ( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if ( aFunc( theObject, aContext ) )
			[theFoundObjectArray addObject:theObject];
	}
	
	return theFoundObjectArray;
}

/*
 * -indexOfObjectWithFunction:
 */
- (unsigned int)indexOfObjectWithFunction:(BOOL (*)(id))aFunc
{
	unsigned int		theIndex,
							theFoundIndex = NSNotFound,
							theCount = [self count];
	
	for ( theIndex = 0; theIndex < theCount && theFoundIndex == NSNotFound; theIndex++ )
	{
		if ( aFunc( [self objectAtIndex:theIndex] ) )
			theFoundIndex = theIndex;
	}
	
	return theFoundIndex;
}

/*
 * -indexOfObjectWithFunction:withContext:
 */
- (unsigned int)indexOfObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	unsigned int		theIndex,
	theFoundIndex = NSNotFound,
							theCount = [self count];

	for ( theIndex = 0; theIndex < theCount && theFoundIndex == NSNotFound; theIndex++ )
	{
		if ( aFunc( [self objectAtIndex:theIndex], aContext ) )
			theFoundIndex = theIndex;
	}

	return theFoundIndex;
}

- (void)sendEveryObjectToTarget:(id)aTarget withSelector:(SEL)aSelector
{
	unsigned int		theIndex,
							theCount = [self count];
	
	for ( theIndex = 0; theIndex < theCount; theIndex++ )
		[aTarget performSelector:aSelector withObject:[self objectAtIndex:theIndex]];
}

- (void)sendEveryObjectToTarget:(id)aTarget withSelector:(SEL)aSelector withObject:(id)anObject
{
	unsigned int		theIndex,
							theCount = [self count];
	
	for ( theIndex = 0; theIndex < theCount; theIndex++ )
		[aTarget performSelector:aSelector withObject:[self objectAtIndex:theIndex] withObject:anObject];
}

/*
 * -firstObject
 */
- (id)firstObject
{
	return ([self count] > 0 ) ? [self objectAtIndex:0] : nil;
}

/*
 * -isEmpty
 */
- (BOOL)isEmpty
{
	return [self count] == 0;
}

@end


