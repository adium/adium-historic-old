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
    NSArray *arguments = [[self query] componentsSeparatedByString:@"&"];
    NSEnumerator *numer = [arguments objectEnumerator];
    
    while(obj = [numer nextObject]){
        NSArray *keyAndValue = [obj componentsSeparatedByString:@"="];
        if([[keyAndValue objectAtIndex:0] isEqualToString:key]){
            return [keyAndValue objectAtIndex:1];
        }
    }
}

@end
