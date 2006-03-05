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
