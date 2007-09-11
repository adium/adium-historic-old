//
//  AIContactVisibility.m
//  Adium
//
//  Created by Andre Cohen on 8/5/07.
//

#import "AIContactVisibilityPlugin.h"
#import <Adium/AIListObject.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <AIUtilities/AIMenuAdditions.h>

@implementation AIContactVisibilityPlugin

- (void)installPlugin {
	alwaysVisible = [[NSMenuItem alloc] initWithTitle:@"Always visible"
											   target:self
											   action:@selector(updateVisible:)
										keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:alwaysVisible 
									   toLocation:Context_Group_Manage];
	
}

- (void)uninstallPlugin {
	[alwaysVisible release];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	AIListObject *object = [[adium interfaceController] selectedListObject];
	
	if(object == nil)
		return NO;
	
	if([object alwaysVisible])
		[alwaysVisible setState:NSOnState];
	else
		[alwaysVisible setState:NSOffState];
	
	return YES;
}

- (void)updateVisible:(id)sender {
	AIListObject *object = [[adium interfaceController] selectedListObject];
	
	if(object == nil)
		return;
	
	[object setAlwaysVisible:![object alwaysVisible]];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent {
	return nil;
}

@end
