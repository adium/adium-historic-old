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

extern BOOL purple_init_irc_plugin(void);

- (void)installLibpurplePlugin
{
	purple_init_irc_plugin();
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
