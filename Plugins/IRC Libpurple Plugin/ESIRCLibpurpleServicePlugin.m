//
//  ESIRCLibpurpleServicePlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import "ESIRCLibpurpleServicePlugin.h"
#import "ESIRCService.h"

@implementation ESIRCLibpurpleServicePlugin

- (void)installPlugin
{
	ircService = [[[ESIRCService alloc] init] retain];
}

- (void)installLibpurplePlugin
{
	//No action needed. The IRC prpl is incldued in libpurple.framework and initialized by libpurple automatically.
}

- (void)loadLibpurplePlugin
{
	//No action needed
}

- (void)dealloc
{
	[ircService release];

	[super dealloc];
}

- (void)uninstallPlugin
{

}

- (NSString *)libpurplePluginPath
{
	return [[NSBundle bundleForClass:[self class]] resourcePath];
}

@end
