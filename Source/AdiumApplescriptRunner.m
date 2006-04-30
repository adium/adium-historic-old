//
//  AdiumApplescriptRunner.m
//  Adium
//
//  Created by Evan Schoenberg on 4/29/06.
//

#import "AdiumApplescriptRunner.h"

#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <sys/errno.h>
#include <unistd.h>

@implementation AdiumApplescriptRunner
- (id)init
{
	if ((self = [super init])) {
		NSDistributedNotificationCenter *distributedNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
		[distributedNotificationCenter addObserver:self
										  selector:@selector(applescriptRunnerIsReady:)
											  name:@"AdiumApplescriptRunner_IsReady"
											object:nil];
		[distributedNotificationCenter addObserver:self
										  selector:@selector(applescriptRunnerDidQuit:)
											  name:@"AdiumApplescriptRunner_DidQuit"
											object:nil];
		
		[distributedNotificationCenter addObserver:self
										  selector:@selector(applescriptDidRun:)
											  name:@"AdiumApplescript_DidRun"
											object:nil];	
		
		//Check for an existing AdiumApplescriptRunner; if there is one, it will respond with AdiumApplescriptRunner_IsReady
		[distributedNotificationCenter postNotificationName:@"AdiumApplescriptRunner_RespondIfReady"
													 object:nil
												   userInfo:nil
										 deliverImmediately:NO];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"AdiumApplescriptRunner_Quit"
																   object:nil
																 userInfo:nil
													   deliverImmediately:NO];

	[super dealloc];
}

- (void)_executeApplescriptWithDict:(NSDictionary *)executionDict
{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"AdiumApplescriptRunner_ExecuteScript"
																   object:nil
																 userInfo:executionDict
													   deliverImmediately:NO];
}

- (void)launchApplescriptRunner
{
	NSString *applescriptRunnerPath = [[NSBundle mainBundle] pathForResource:@"AdiumApplescriptRunner"
																	  ofType:nil
																 inDirectory:nil];
	
	//Houston, we are go for launch.
	if (applescriptRunnerPath) {
		pid_t pid = fork();
		if(pid == 0) {
			//We are the child process. Turn into an AppleScriptRunner.
			execl([applescriptRunnerPath fileSystemRepresentation], NULL);

			//If we get here, we have failed.
			NSLog(@"Could not launch %@: %s", applescriptRunnerPath, strerror(errno));
			exit(1);
		} else if(pid < 0) {
			//Fork failed.
			NSLog(@"Could not fork to AppleScript runner: %s", strerror(errno));
		}
	} else {
		NSLog(@"Could not find AdiumApplescriptRunner...");
	}
}

/*
 * @brief Run an applescript, optinally calling a function with arguments, and notify a target/selector with its output when it is done
 */
- (void)runApplescriptAtPath:(NSString *)path function:(NSString *)function arguments:(NSArray *)arguments notifyingTarget:(id)target selector:(SEL)selector userInfo:(id)userInfo
{
	NSString *uniqueID = [[NSProcessInfo processInfo] globallyUniqueString];
	
	if (!runningApplescriptsDict) runningApplescriptsDict = [[NSMutableDictionary alloc] init];
	
	[runningApplescriptsDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
		target, @"target",
		NSStringFromSelector(selector), @"selector",
		userInfo, @"userInfo", nil]
								forKey:uniqueID];
	
	NSDictionary *executionDict = [NSDictionary dictionaryWithObjectsAndKeys:
		path, @"path",
		(function ? function : @""), @"function",
		(arguments ? arguments : [NSArray array]), @"arguments",
		uniqueID, @"uniqueID",
		nil];
	
	if (applescriptRunnerIsReady) {
		[self _executeApplescriptWithDict:executionDict];
		
	} else {
		if (!pendingApplescriptsArray) pendingApplescriptsArray = [[NSMutableArray alloc] init];
		
		[pendingApplescriptsArray addObject:executionDict];
		
		[self launchApplescriptRunner];
	}
}

- (void)applescriptRunnerIsReady:(NSNotification *)inNotification
{
	NSEnumerator	*enumerator;
	NSDictionary	*executionDict;
	
	applescriptRunnerIsReady = YES;
	
	enumerator = [pendingApplescriptsArray objectEnumerator];
	while ((executionDict = [enumerator nextObject])) {
		[self _executeApplescriptWithDict:executionDict];		
	}
	
	[pendingApplescriptsArray release]; pendingApplescriptsArray = nil;
}

- (void)applescriptRunnerDidQuit:(NSNotification *)inNotification
{
	applescriptRunnerIsReady = NO;
}

- (void)applescriptDidRun:(NSNotification *)inNotification
{
	NSDictionary *userInfo = [inNotification userInfo];
	NSString	 *uniqueID = [userInfo objectForKey:@"uniqueID"];
	
	NSDictionary *targetDict = [runningApplescriptsDict objectForKey:uniqueID];
	id			 target = [targetDict objectForKey:@"target"];
	//Selector will be of the form applescriptDidRun:resultString:
	SEL			 selector = NSSelectorFromString([targetDict objectForKey:@"selector"]);
	
	//Notify our target
	[target performSelector:selector
				 withObject:[targetDict objectForKey:@"userInfo"]
				 withObject:[userInfo objectForKey:@"resultString"]];
	
	//No further need for this dictionary entry
	[runningApplescriptsDict removeObjectForKey:uniqueID];
}

@end
