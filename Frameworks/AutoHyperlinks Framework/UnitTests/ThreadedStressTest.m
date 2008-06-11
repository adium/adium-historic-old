//
//  ThreadedStressTest.m
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 6/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ThreadedStressTest.h"
#import "AutoHyperlinks.h"

#define LOOP_COUNT 50
#define THREAD_COUNT 2

@implementation ThreadedStressTest
-(void) threadedStressTest
{
	int i = THREAD_COUNT;
	allTestsDidFinish = false;
	NSThread	*thread1 = [[NSThread alloc] initWithTarget:self selector:@selector(performTest) object:nil];
	NSThread	*thread2 = [[NSThread alloc] initWithTarget:self selector:@selector(performTest) object:nil];
	
	[thread1 start]; [thread2 start];
	while(![thread1 isFinished] && ![thread2 isFinished]);
}

-(void) performTest
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"started test thread");
	NSError				*error = nil;
	NSString			*stressString = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:TEST_URIS_FILE_PATHNAME] encoding:NSUTF8StringEncoding error:&error];
	STAssertNil(error, @"stringWithContentsOfFile:encoding:error: could not read file at path '%s': %@", TEST_URIS_FILE_PATHNAME, error);

	AHHyperlinkScanner	*scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
	NSAttributedString	*attrString;
	
	int i = LOOP_COUNT;
	while(i > 0) {
		attrString = [scanner linkifyString:[[NSAttributedString alloc] initWithString:stressString]];
		i--;
	}
	NSLog(@"We're done!");
	[pool release];
}
@end
