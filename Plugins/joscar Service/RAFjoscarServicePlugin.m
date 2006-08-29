//
//  RAFjoscarPlugin.m
//  Adium
//
//  Created by Augie Fackler on 11/18/05.
//

#import "RAFjoscarServicePlugin.h"
#import "RAFjoscarDebugController.h"

@implementation RAFjoscarServicePlugin

- (void)installPlugin
{
	joscarAIMService = [[RAFjoscarAIMService alloc] init];
	joscarDotMacService = [[RAFjoscarDotMacService alloc] init];
//	joscarICQService = [[RAFjoscarICQService alloc] init];
	#ifdef DEBUG_BUILD
		debugController = [[RAFjoscarDebugController alloc] init];
		[debugController activateDebugController];
	#endif
}

- (void)uninstallPlugin
{
	[debugController release]; debugController = nil;
}

- (void)dealloc
{
	[joscarAIMService release]; joscarAIMService = nil;
	[joscarDotMacService release]; joscarDotMacService = nil;
//	[joscarICQService release]; joscarICQService = nil;
	[super dealloc];
}

@end
