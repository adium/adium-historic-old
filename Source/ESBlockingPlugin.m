/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIMenuController.h"
#import "ESBlockingPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>

#define BLOCK_CONTACT	AILocalizedString(@"Block","Block Contact menu item")
#define UNBLOCK_CONTACT AILocalizedString(@"Unblock","Unblock Contact menu item")

@interface ESBlockingPlugin(PRIVATE)
- (void)_blockContact:(AIListContact *)contact unblock:(BOOL)unblock;
- (BOOL)_searchPrivacyListsForListContact:(AIListContact *)contact withDesiredResult:(BOOL)desiredResult;
@end

@implementation ESBlockingPlugin

- (void)installPlugin
{
	//Install the Block menu items
	blockContactMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
														 target:self
														 action:@selector(blockContact:)
												  keyEquivalent:@""];
	[[adium menuController] addMenuItem:blockContactMenuItem toLocation:LOC_Contact_NegativeAction];

    //Add our get info contextual menu items
    blockContactContextualMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
																target:self
																action:@selector(blockContact:)
														 keyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:blockContactContextualMenuItem toLocation:Context_Contact_NegativeAction];
}

- (void)uninstallPlugin
{
	[blockContactMenuItem release];
	[blockContactContextualMenuItem release];
}


- (IBAction)blockContact:(id)sender
{
	AIListObject *object;
	BOOL unblock;
	
	if(sender == blockContactMenuItem){
		object = [[adium contactController] selectedListObject];
	}else{
		object = [[adium menuController] currentContextMenuObject];
	}
	
	unblock = [[sender title] isEqualToString:UNBLOCK_CONTACT];

	//Don't do groups
	if([object isKindOfClass:[AIListContact class]]){
		AIListContact *contact = (AIListContact *)object;
		NSString *format = unblock 
						 ? AILocalizedString(@"Are you sure you want to unblock %@?",nil)
						 : AILocalizedString(@"Are you sure you want to block %@?",nil);
						 
		if(NSRunAlertPanel([NSString stringWithFormat:format, [contact displayName]],
				   @"",
				   AILocalizedString(@"OK",nil),
				   AILocalizedString(@"Cancel",nil),
				   nil) 
				== NSAlertDefaultReturn){
		
			//Handle metas
			if([object isKindOfClass:[AIMetaContact class]]){
				AIMetaContact *meta = (AIMetaContact *)object;
									
				//Enumerate over the various list contacts contained
				NSEnumerator *enumerator = [[meta listContacts] objectEnumerator];
				AIListContact *containedContact = nil;
				
				while(containedContact = [enumerator nextObject]){
					[[containedContact account] addListObject:containedContact toPrivacyList:PRIVACY_DENY];
				}
			}else{
				AIListContact *contact = (AIListContact *)object;
				[[contact account] addListObject:contact toPrivacyList:PRIVACY_DENY];
			}
		}
	}
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AIListObject *object;
	BOOL unblock = [[menuItem title] isEqualToString:UNBLOCK_CONTACT];
	BOOL anyAccount = NO;
	
	if(menuItem == blockContactMenuItem){
		object = [[adium contactController] selectedListObject];
	}else{
		object = [[adium menuController] currentContextMenuObject];
	}
	
	//Don't do groups
	if([object isKindOfClass:[AIListContact class]]){
		//Handle metas
		if([object isKindOfClass:[AIMetaContact class]]){
			AIMetaContact *meta = (AIMetaContact *)object;
								
			//Enumerate over the various list contacts contained
			NSEnumerator *enumerator = [[meta listContacts] objectEnumerator];
			AIListContact *contact = nil;
			
			while(contact = [enumerator nextObject]){
				if([[contact account] conformsToProtocol:@protocol(AIAccount_Privacy)]){
					anyAccount = YES;
					if([[[contact account] listObjectIDsOnPrivacyList:PRIVACY_DENY] containsObject:[contact UID]]){
						if(!unblock){
							[menuItem setTitle:UNBLOCK_CONTACT];
						}
						return YES;
					}
				}
			}
			if(anyAccount){
				if(unblock){
					[menuItem setTitle:BLOCK_CONTACT];
				}
				return YES;
			}else{
				[menuItem setTitle:BLOCK_CONTACT];
				return NO;
			}
		}else{
			AIListContact *contact = (AIListContact *)object;
			if([[contact account] conformsToProtocol:@protocol(AIAccount_Privacy)]){
				if([[[contact account] listObjectIDsOnPrivacyList:PRIVACY_DENY] containsObject:[contact UID]]){
					if(!unblock){
						[menuItem setTitle:UNBLOCK_CONTACT];
					}
					return YES;
				}else{
					if(unblock){
						[menuItem setTitle:BLOCK_CONTACT];
					}
					return YES;
				}
			}else{
				[menuItem setTitle:BLOCK_CONTACT];
				return NO;
			}
		}
	}
	return NO;
}

#pragma mark Private
//Private --------------------------------------------------------------------------------------------------------------

- (void)_blockContact:(AIListContact *)contact unblock:(BOOL)unblock
{
	//We want to block on all accounts with the same service class. If you want someone gone, you want 'em GONE.
	NSEnumerator *enumerator = [[[adium accountController] accountsWithServiceClassOfService:[contact service]] objectEnumerator];
	AIAccount *account = nil;

	while(account = [enumerator nextObject]){
		if([account conformsToProtocol:@protocol(AIAccount_Privacy)]){
			AIAccount <AIAccount_Privacy> *privacyAccount = (AIAccount <AIAccount_Privacy> *)account;
			if(unblock){
				if([[privacyAccount listObjectIDsOnPrivacyList:PRIVACY_DENY] containsObject:[contact UID]]){
					[privacyAccount removeListObject:contact fromPrivacyList:PRIVACY_DENY];
				}
			}else{
				if(![[privacyAccount listObjectIDsOnPrivacyList:PRIVACY_DENY] containsObject:[contact UID]]){
					[privacyAccount addListObject:contact toPrivacyList:PRIVACY_DENY];
				}
			}
		}
	}
}

- (BOOL)_searchPrivacyListsForListContact:(AIListContact *)contact withDesiredResult:(BOOL)desiredResult
{
	AIAccount *account = nil;
	NSEnumerator *enumerator;
	
	enumerator = [[[adium accountController] accountsWithServiceClassOfService:[contact service]] objectEnumerator];
	
	while(account = [enumerator nextObject]){
		if([account conformsToProtocol:@protocol(AIAccount_Privacy)]){
			AIAccount <AIAccount_Privacy> *privacyAccount = (AIAccount <AIAccount_Privacy> *)account;
			if([[privacyAccount listObjectIDsOnPrivacyList:PRIVACY_DENY] containsObject:[contact UID]] == desiredResult){
				return YES;
			}
		}
	}
	return NO;
}

@end