//
//  ESURLAdditions.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Feb 17 2004.
//

#import "ESURLAdditions.h"


@implementation NSURL (ESURLAdditions)

- (int)length
{
	return [[self absoluteString] length];
}

@end
