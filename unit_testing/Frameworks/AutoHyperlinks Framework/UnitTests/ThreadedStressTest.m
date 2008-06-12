//
//  ThreadedStressTest.m
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 6/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ThreadedStressTest.h"
#import "AutoHyperlinks.h"

#define LOOP_COUNT 10
#define THREAD_COUNT 8

@implementation ThreadedStressTest
-(void) threadedStressTest
{
	AHHyperlinkScanner	*scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
	
	NSThread	*thread1 = [[NSThread alloc] initWithTarget:self selector:@selector(performTestWithScanner:) object:scanner];
	NSThread	*thread2 = [[NSThread alloc] initWithTarget:self selector:@selector(performTestWithScanner:) object:scanner];
	NSThread	*thread3 = [[NSThread alloc] initWithTarget:self selector:@selector(performTestWithScanner:) object:scanner];
	NSThread	*thread4 = [[NSThread alloc] initWithTarget:self selector:@selector(performTestWithScanner:) object:scanner];
	NSThread	*thread5 = [[NSThread alloc] initWithTarget:self selector:@selector(performTestWithScanner:) object:scanner];
	NSThread	*thread6 = [[NSThread alloc] initWithTarget:self selector:@selector(performTestWithScanner:) object:scanner];
	NSThread	*thread7 = [[NSThread alloc] initWithTarget:self selector:@selector(performTestWithScanner:) object:scanner];
	NSThread	*thread8 = [[NSThread alloc] initWithTarget:self selector:@selector(performTestWithScanner:) object:scanner];

	[thread1 start]; [thread2 start];
	[thread3 start]; [thread4 start];
	[thread5 start]; [thread6 start];
	[thread7 start]; [thread8 start];
	
	while(![thread1 isFinished] && ![thread2 isFinished] &&
		  ![thread3 isFinished] && ![thread4 isFinished] &&
		  ![thread5 isFinished] && ![thread6 isFinished] &&
		  ![thread7 isFinished] && ![thread8 isFinished]){
		[NSThread sleepForTimeInterval:.1];
	}
}

-(void) performTestWithScanner:(AHHyperlinkScanner *)scanner
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSError				*error = nil;
	NSString			*stressString = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:TEST_URIS_FILE_PATHNAME] encoding:NSUTF8StringEncoding error:&error];
	STAssertNil(error, @"stringWithContentsOfFile:encoding:error: could not read file at path '%s': %@", TEST_URIS_FILE_PATHNAME, error);

	//AHHyperlinkScanner	*scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
	NSAttributedString	*attrString;
	
	int i = LOOP_COUNT;
	while(i > 0) {
		attrString = [scanner linkifyString:[[NSAttributedString alloc] initWithString:stressString]];
		i--;
	}
	[pool release];
}
@end
