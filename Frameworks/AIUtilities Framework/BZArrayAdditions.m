//
//  BZArrayAdditions.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Tue May 11 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "BZArrayAdditions.h"

@implementation NSArray (BZArrayAdditions)

- (BOOL)containsObjectIdenticalTo:(id)obj
{
	return ([self indexOfObjectIdenticalTo:obj] != NSNotFound);
}

@end
