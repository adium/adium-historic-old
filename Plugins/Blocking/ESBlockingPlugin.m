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

#define BLOCK_CONTACT	AILocalizedString(@"Block",@"Block Contact menu item")
#define UNBLOCK_CONTACT AILocalizedString(@"Unblock",@"Unblock Contact menu item")

@interface ESBlockingPlugin(PRIVATE)
- (void)_blockObject:(AIListObject *)object unblock:(BOOL)unblock;
- (void)_blockContact:(AIListContact *)contact unblock:(BOOL)unblock;
- (BOOL)_searchPrivacyListsForListObject:(AIListObject *)object withDesiredResult:(BOOL)desiredResult;
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
	
	unblockContactMenuItem = [[NSMenuItem alloc] initWithTitle:UNBLOCK_CONTACT
														 target:self
														 action:@selector(unblockContact:)
												  keyEquivalent:@""];
	[[adium menuController] addMenuItem:unblockContactMenuItem toLocation:LOC_Contact_NegativeAction];

    //Add our get info contextual menu items
    blockContactContextualMenuItem = [[NSMenuItem alloc] initWithTitle:BLOCK_CONTACT
																target:self
																action:@selector(blockContact:)
														 keyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:blockContactContextualMenuItem toLocation:Context_Contact_NegativeAction];

    unblockContactContextualMenuItem = [[NSMenuItem alloc] initWithTitle:UNBLOCK_CONTACT
																target:self
																action:@selector(unblockContact:)
														 keyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:unblockContactContextualMenuItem toLocation:Context_Contact_NegativeAction];

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
	
	[self _blockObject:object unblock:NO];
}

- (IBAction)unblockContact:(id)sender
{
	AIListObject *object;
	
	if(sender == unblockContactMenuItem){
		object = [[adium contactController] selectedListObject];
	}else{
		object = [[adium menuController] contactualMenuObject];
	}

	[self _blockObject:object unblock:YES];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	AIListObject *object;
	
	if(menuItem == blockContactMenuItem || menuItem == blockContactContextualMenuItem){
		if(menuItem == blockContactMenuItem){
			object = [[adium contactController] selectedListObject];
		}else{
			object = [[adium menuController] contactualMenuObject];
		}
		return [self _searchPrivacyListsForListObject:object withDesiredResult:NO];
		
	}else{
		if(menuItem == unblockContactMenuItem){
			object = [[adium contactController] selectedListObject];
		}else{
			object = [[adium menuController] contactualMenuObject];
		}
		return [self _searchPrivacyListsForListObject:object withDesiredResult:YES];
	}
}

#pragma mark Private
//Private --------------------------------------------------------------------------------------------------------------

- (void)_blockObject:(AIListObject *)object unblock:(BOOL)unblock
{
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
					[self _blockContact:containedContact unblock:unblock];
				}
			}else{
				AIListContact *contact = (AIListContact *)object;
				[self _blockContact:contact unblock:unblock];
			}
		}
	}
}

- (void)_blockContact:(AIListContact *)contact unblock:(BOOL)unblock
{
	if([[contact account] conformsToProtocol:@protocol(AIAccount_Privacy)]){
		//We want to block on all accounts with the same service class. If you want someone gone, you want 'em GONE.
		NSEnumerator *enumerator = [[[adium accountController] accountsWithServiceClassOfService:[contact service]] objectEnumerator];
		AIAccount *account = nil;

		while(account = [enumerator nextObject]){
			if([account conformsToProtocol:@protocol(AIAccount_Privacy)]){
				AIAccount <AIAccount_Privacy> *privacyAccount = (AIAccount <AIAccount_Privacy> *)account;
				if([privacyAccount privacyOptions] == PRIVACY_DENY_USERS){
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
	}
}

- (BOOL)_searchPrivacyListsForListObject:(AIListObject *)object withDesiredResult:(BOOL)desiredResult
{
	//Don't do groups
	if([object isKindOfClass:[AIListContact class]]){
		//Handle metas
		if([object isKindOfClass:[AIMetaContact class]]){
			AIMetaContact *meta = (AIMetaContact *)object;
								
			//Enumerate over the various list contacts contained
			NSEnumerator *enumerator = [[meta listContacts] objectEnumerator];
			AIListContact *contact = nil;
			
			while(contact = [enumerator nextObject]){
				if([self _searchPrivacyListsForListContact:contact withDesiredResult:desiredResult]){
					return YES;
				}
			}
			return NO;
		}else{
			AIListContact *contact = (AIListContact *)object;
			return [self _searchPrivacyListsForListContact:contact withDesiredResult:desiredResult];
		}
	}
	return NO;
}

- (BOOL)_searchPrivacyListsForListContact:(AIListContact *)contact withDesiredResult:(BOOL)desiredResult
{
	if([[contact account] conformsToProtocol:@protocol(AIAccount_Privacy)]){
		AIAccount *account = nil;
		NSEnumerator *enumerator;
		
		enumerator = [[[adium accountController] accountsWithServiceClassOfService:[contact service]] objectEnumerator];
		
		while(account = [enumerator nextObject]){
			if([account conformsToProtocol:@protocol(AIAccount_Privacy)]){
				AIAccount <AIAccount_Privacy> *privacyAccount = (AIAccount <AIAccount_Privacy> *)account;
				if([privacyAccount privacyOptions] == PRIVACY_DENY_USERS){
					if([[privacyAccount listObjectIDsOnPrivacyList:PRIVACY_DENY] containsObject:[contact UID]] == desiredResult){
						return YES;
					}
				}
			}
		}
	}
	return NO;
}

@end
