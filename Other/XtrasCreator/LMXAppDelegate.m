//
//  LMXAppDelegate.m
//  LMX
//
//  Created by Mac-arena the Bored Zo on 2005-10-17.
//  Copyright 2005 Mac-arena the Bored Zo. All rights reserved.
//

#import "LMXAppDelegate.h"

#include <sys/types.h>
#include <unistd.h>
#import <ExceptionHandling/NSExceptionHandler.h>

@implementation LMXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
#pragma unused(notification)
	NSExceptionHandler *excHandler = [NSExceptionHandler defaultExceptionHandler];
	[excHandler setExceptionHandlingMask:NSLogUncaughtExceptionMask | NSLogUncaughtSystemExceptionMask | NSLogUncaughtRuntimeErrorMask | NSLogTopLevelExceptionMask | NSLogOtherExceptionMask];
	[excHandler setDelegate:self];
}

#pragma mark -

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(unsigned int)aMask {
	NSMutableArray *symbols = [[[[exception userInfo] objectForKey:NSStackTraceKey] componentsSeparatedByString:@"  "] mutableCopy];

	[symbols insertObject:@"-p" atIndex:0U];
	[symbols insertObject:[[NSNumber numberWithInt:getpid()] stringValue] atIndex:1U];

	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/atos"];
	[task setArguments:symbols];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];

	[task launch];
	[task waitUntilExit];

	NSFileHandle *fh = [pipe fileHandleForReading];
	NSData *data = [fh readDataToEndOfFile];
	NSString *stackTrace = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

	NSLog(@"got %@ with reason %@; stack trace follows\n%@", [exception name], [exception reason], stackTrace);

	return NO; //because we just did
}

@end
