//
//  NEHMutableStringAdditions.m
//  Adium
//
//  Created by Nelson Elhage on Sun Mar 14 2004.
//

#import "NEHMutableStringAdditions.h"

@implementation NSMutableString (NEHMutableStringAdditions)

+ (NSMutableString *)stringWithContentsOfASCIIFile:(NSString *)path
{
	return ([[[NSMutableString alloc] initWithData:[NSData dataWithContentsOfFile:path]
								   encoding:NSASCIIStringEncoding] autorelease]);
}

- (NSMutableString*)mutableString
{
	return self;
}

@end
