//
//  RAFjoscarPlugin.m
//  Adium
//
//  Created by Augie Fackler on 11/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "RAFjoscarServicePlugin.h"
#import "RAFjoscarDebugController.h"

@implementation RAFjoscarServicePlugin

- (void)installPlugin
{
#ifdef JOSCAR_SUPERCEDE_LIBGAIM
	joscarAIMService = [[RAFjoscarAIMService alloc] init];
	joscarDotMacService = [[RAFjoscarDotMacService alloc] init];
	joscarICQService = [[RAFjoscarICQService alloc] init];
	#ifdef DEBUG_BUILD
		debugController = [[RAFjoscarDebugController alloc] init];
		[debugController activateDebugController];
	#endif
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
	[joscarICQService release]; joscarICQService = nil;
	[super dealloc];
}

@end
