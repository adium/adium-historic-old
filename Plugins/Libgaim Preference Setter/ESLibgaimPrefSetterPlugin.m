//
//  ESLibgaimPrefSetterPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 12/25/06.
//

#import "ESLibgaimPrefSetterPlugin.h"
#import "ESLibgaimPrefSetterWindowController.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>

@implementation ESLibgaimPrefSetterPlugin
+ (void)initialize
{
	NSLog(@"init");
}
- (void)installPlugin
{
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Set a Libgaim Preference"
													target:self 
													action:@selector(setLibgaimPreference:)
											 keyEquivalent:@"n"];
	[[adium menuController] addMenuItem:menuItem toLocation:LOC_Adium_Other];
	NSLog(@"Added %@ to %@",menuItem,[adium menuController]);;
}
- (void)installLibgaimPlugin
{
	NSLog(@"test");
}
- (void)setLibgaimPreference:(id)sender
{
	[ESLibgaimPrefSetterWindowController show];
}

@end
