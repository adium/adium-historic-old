//
//  ESBlockingPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
//

#import "ESBlockingPlugin.h"

#define BLOCK_CONTACT @"Block Contact"

@implementation ESBlockingPlugin

- (void)installPlugin
{
	/*
	//Install the Block menu item
	viewContactInfoMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
														 target:self
														 action:@selector(blockContact:)
												  keyEquivalent:@"i"];
	[[adium menuController] addMenuItem:viewContactInfoMenuItem toLocation:LOC_Contact_Manage];
	
	
    //Add our get info contextual menu item
    getInfoContextMenuItem = [[NSMenuItem alloc] initWithTitle:VIEW_INFO target:self action:@selector(showContextContactInfo:) keyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:getInfoContextMenuItem toLocation:Context_Contact_Manage];
	*/
}

@end
