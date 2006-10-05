//
//  AIScannerDebug.m
//  Adium
//
//  Created by Evan Schoenberg on 9/27/06.
//

#import "AIScannerDebug.h"

@implementation AIScannerDebug

#ifdef DEBUG_BUILD

+ (void)load
{
	[self poseAsClass:[NSScanner class]];
}

- (id)initWithString:(NSString *)aString
{
	NSParameterAssert(aString != nil);
	AILog(@"String is %@",aString);

	return [super initWithString:aString];
}

#endif

@end
