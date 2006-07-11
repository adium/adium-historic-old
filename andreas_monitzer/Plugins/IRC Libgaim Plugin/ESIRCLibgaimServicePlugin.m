//
//  ESIRCLibgaimServicePlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import "ESIRCLibgaimServicePlugin.h"
#import "ESIRCService.h"

@implementation ESIRCLibgaimServicePlugin

- (void)installPlugin
{
	ircService = [[[ESIRCService alloc] init] retain];
}

extern BOOL gaim_init_irc_plugin(void);

- (void)installLibgaimPlugin
{
	gaim_init_irc_plugin();
}

- (void)dealloc
{
	[ircService release];

	[super dealloc];
}

- (void)uninstallPlugin
{

}

- (NSString *)libgaimPluginPath
{
	return [[NSBundle bundleForClass:[self class]] resourcePath];
}

@end
