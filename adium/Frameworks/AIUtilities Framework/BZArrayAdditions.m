//
//  BZArrayAdditions.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Tue May 11 2004.
//

#import "BZArrayAdditions.h"

@implementation NSArray (BZArrayAdditions)

- (BOOL)containsObjectIdenticalTo:(id)obj
{
	return ([self indexOfObjectIdenticalTo:obj] != NSNotFound);
}

@end
