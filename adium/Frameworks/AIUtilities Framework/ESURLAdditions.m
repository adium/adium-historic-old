//
//  ESURLAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Feb 17 2004.
//

#import "ESURLAdditions.h"

@implementation NSURL (ESURLAdditions)

- (unsigned int)length
{
	return [[self absoluteString] length];
}

@end
