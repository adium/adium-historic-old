//
//  ESBlockingPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESBlockingPlugin.h"

#define BLOCK_CONTACT	AILocalizedString(@"Block", @"Block Contact menu item")
#define UNBLOCK_CONTACT AILocalizedString(@"Unblock", @"Unblock Contact menu item")

@interface ESBlockingPlugin(PRIVATE)
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
@end

@implementation ESBlockingPlugin

- (void)installPlugin
{
	//Install the Block menu item
	blockContactMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
														 target:self
														 action:@selector(blockContact:)
												  keyEquivalent:@""];
	//[[adium menuController] addMenuItem:blockContactMenuItem toLocation:LOC_Contact_NegativeAction];
	
    //Add our get info contextual menu item
    blockContactContextualMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
																target:self
																action:@selector(blockContact:)
														 keyEquivalent:@""];
    //[[adium menuController] addContextualMenuItem:blockContactContextualMenuItem toLocation:Context_Contact_NegativeAction];
}

- (void)uninstallPlugin
{
	[blockContactMenuItem release];
	[blockContactContextualMenuItem release];
}

- (IBAction)blockContact:(id)sender
{
	AIListObject *object;
	
	if(sender == blockContactMenuItem){
		object = [[adium contactController] selectedListObject];
	}else{
		object = [[adium menuController] contactualMenuObject];
	}
	
	
	//don't block groups
	if([object isKindOfClass:[AIListContact class]]){
		AIListContact *contact = (AIListContact *)object;
		
		if([[contact account] conformsToProtocol:@protocol(AIAccount_Privacy)]){
			AIAccount <AIAccount_Privacy> *account = [contact account];
			//if it's not on the block list, block it. otherwise, unblock it
			if([[account listObjectsOnPrivacyList:PRIVACY_DENY] indexOfObjectIdenticalTo:contact] == NSNotFound){
				if(NSRunAlertPanel([NSString stringWithFormat:AILocalizedString(@"Are you sure you want to block %@?",nil), [object displayName]],
								   @"",
								   AILocalizedString(@"OK",nil),
								   AILocalizedString(@"Cancel",nil),
								   nil) 
								== NSAlertDefaultReturn){
					NSLog(@"Blocking");
					if([account addListObject:object toPrivacyList:PRIVACY_DENY]){ NSLog(@"Success!"); }
				}
			}else{
				if(NSRunAlertPanel([NSString stringWithFormat:AILocalizedString(@"Are you sure you want to unblock %@?",nil), [object displayName]],
								   @"",
								   AILocalizedString(@"OK",nil),
								   AILocalizedString(@"Cancel",nil),
								   nil)
								== NSAlertDefaultReturn){
					NSLog(@"Unblocking");
					if([account removeListObject:object fromPrivacyList:PRIVACY_DENY]){ NSLog(@"Success!"); }
				}
			}
		}
	}
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AIListObject *object;
	
	if(menuItem == blockContactMenuItem){
		object = [[adium contactController] selectedListObject];
	}else{
		object = [[adium menuController] contactualMenuObject];
	}
	
	if([object isKindOfClass:[AIListContact class]]){
		AIListContact *contact = (AIListContact *)object;
		
		if([[contact account] conformsToProtocol:@protocol(AIAccount_Privacy)]){
			AIAccount <AIAccount_Privacy> *account = [contact account];
			if([[account listObjectsOnPrivacyList:PRIVACY_DENY] indexOfObjectIdenticalTo:contact] == NSNotFound){
				[menuItem setTitle:BLOCK_CONTACT];
				return YES;
			}else{
				[menuItem setTitle:UNBLOCK_CONTACT];
				return YES;
			}
		}
	}
	
	//reset the title to the default if it's disabled
	[menuItem setTitle:BLOCK_CONTACT];
	return NO;
}

@end
