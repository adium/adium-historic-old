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

- (NSString *)queryArgumentForKey:(NSString *)key
{
    NSString *obj = nil;
    NSEnumerator *enumerator = [[[self query] componentsSeparatedByString:@"&"] objectEnumerator];
    
    while(obj = [enumerator nextObject]){
        NSArray *keyAndValue = [obj componentsSeparatedByString:@"="];

        if(([keyAndValue count] >= 2) &&
		   ([[keyAndValue objectAtIndex:0] isEqualToString:key]){
			   return [keyAndValue objectAtIndex:1];
		   }
    }
	
	return nil;
}

@end
