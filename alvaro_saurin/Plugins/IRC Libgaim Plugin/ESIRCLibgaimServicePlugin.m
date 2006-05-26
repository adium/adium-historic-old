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
	NSLog(@"Init %@ and got %@",self, ircService);
}

extern BOOL gaim_init_irc_plugin(void);

- (void)installLibgaimPlugin
{
	gaim_init_irc_plugin();
}

- (void)dealloc
{
	[ircService release];
	NSLog(@"Dealloc %@",self);
	[super dealloc];
}

- (void)uninstallPlugin
{
	NSLog(@"Uninstall");
}

- (NSString *)libgaimPluginPath
{
	return [[NSBundle bundleForClass:[self class]] resourcePath];
}

@end
