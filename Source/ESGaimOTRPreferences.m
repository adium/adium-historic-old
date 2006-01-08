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

#import "ESGaimOTRPreferences.h"
#import "AIAccountController.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccountMenu.h>
#import "SLGaimCocoaAdapter.h"

#import "gaimOTRCommon.h"

/* Adium OTR headers */
#import "ESGaimOTRFingerprintDetailsWindowController.h"

@interface ESGaimOTRPreferences (PRIVATE)
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (void)configureAccountsMenu;
@end

@implementation ESGaimOTRPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category
{
    return AIPref_Advanced;
}
- (NSString *)label
{
    return AILocalizedString(@"Encryption",nil);
}
- (NSString *)nibName
{
    return @"OTRPrefs";
}
- (NSImage *)image
{
	return [NSImage imageNamed:@"Lock_Locked State" forClass:[adium class]];
}

- (void)viewDidLoad
{
	viewIsOpen = YES;

	//Account Menu
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountNoSubmenu
										   showTitleVerbs:NO] retain];
	
	//Fingerprints
	[tableView_fingerprints setDelegate:self];
	[tableView_fingerprints setDataSource:self];
	[tableView_fingerprints setTarget:self];
	[tableView_fingerprints setDoubleAction:@selector(showFingerprint:)];
	[self updateFingerprintsList];
	
	[self updatePrivateKeyList];

	[textField_privateKey setSelectable:YES];

	[self tableViewSelectionDidChange:nil];		
}

- (void)viewWillClose
{
	viewIsOpen = NO;
	[fingerprintDictArray release]; fingerprintDictArray = nil;
	[accountMenu release]; accountMenu = nil;
	
	[[adium notificationCenter] removeObserver:self
										  name:Account_ListChanged
										object:nil];
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[fingerprintDictArray release]; fingerprintDictArray = nil;
	[[adium notificationCenter] removeObserver:self];

	[super dealloc];
}

/*
 * @brief Update the fingerprint display
 *
 * Called by the OTR adapter when gaim-otr informs us the fingerprint list changed
 */
- (void)updateFingerprintsList
{
	if (viewIsOpen) {
		ConnContext		*context;
		Fingerprint		*fingerprint;
		OtrlUserState	otrg_plugin_userstate = otrg_get_userstate();

		[fingerprintDictArray release];
		fingerprintDictArray = [[NSMutableArray alloc] init];
		
		for (context = otrg_plugin_userstate->context_root; context != NULL;
			 context = context->next) {

			fingerprint = context->fingerprint_root.next;
			/* If there's no fingerprint, don't add it to the known
				* fingerprints list */
			while (fingerprint) {
				char			hash[45];
				NSDictionary	*fingerprintDict;
				NSString		*UID;
				NSString		*state, *fingerprintString;
				GaimAccount		*gaimAccount;
				AIAccount		*adiumAccount;

				UID = [NSString stringWithUTF8String:context->username];
				
				if (context->msgstate == OTRL_MSGSTATE_ENCRYPTED &&
					context->active_fingerprint != fingerprint) {
					state = AILocalizedString(@"Unused",nil);
				} else {
					TrustLevel trustLevel = otrg_plugin_context_to_trust(context);
					
					switch (trustLevel) {
						case TRUST_NOT_PRIVATE:
							state = AILocalizedString(@"Not private",nil);
							break;
						case TRUST_UNVERIFIED:
							state = AILocalizedString(@"Unverified",nil);
							break;
						case TRUST_PRIVATE:
							state = AILocalizedString(@"Private",nil);
							break;
						case TRUST_FINISHED:
							state = AILocalizedString(@"Finished",nil);
							break;
						default:
							state = @"";
							break;
					}
				}
				
				otrl_privkey_hash_to_human(hash, fingerprint->fingerprint);
				fingerprintString = [NSString stringWithUTF8String:hash];

				gaimAccount = gaim_accounts_find(context->accountname, context->protocol);
				adiumAccount = accountLookup(gaimAccount);

				fingerprintDict = [NSDictionary dictionaryWithObjectsAndKeys:
					UID, @"UID",
					state, @"Status",
					fingerprintString, @"FingerprintString",
					[NSValue valueWithPointer:fingerprint], @"FingerprintValue",
					adiumAccount, @"AIAccount",
					nil];

				[fingerprintDictArray addObject:fingerprintDict];

				fingerprint = fingerprint->next;
			}
		}
		
		[tableView_fingerprints reloadData];
	}
}

/*
 * @brief Update the key list
 *
 * Called by the OTR adapter when gaim-otr informs us the private key list changed
 */
- (void)updatePrivateKeyList
{
	if (viewIsOpen) {
		NSString		*fingerprintString = nil;
		CBGaimAccount	*adiumAccount = [[popUp_accounts selectedItem] representedObject];
		GaimAccount		*gaimAccount;
		
		gaimAccount = accountLookupFromAdiumAccount(adiumAccount);

		if (gaimAccount) {
			const char *accountname;
			const char *protocol;
			char *fingerprint;

			char fingerprint_buf[45];
			accountname = gaim_account_get_username(gaimAccount);
			protocol = gaim_account_get_protocol_id(gaimAccount);
			fingerprint = otrl_privkey_fingerprint(otrg_plugin_userstate,
												   fingerprint_buf, accountname, protocol);

			if (fingerprint) {
				fingerprintString = [NSString stringWithFormat:AILocalizedString(@"Fingerprint: %.80s",nil), fingerprint];
			} else {
				fingerprintString = AILocalizedString(@"No private key present", "Message to show in the Encryption OTR preferences when an account is selected which does not have a private key");
			}
		}

		[textField_privateKey setStringValue:(fingerprintString ?
											  fingerprintString :
											  @"")];
	}	
}

/*
 * @brief Generate a new private key for the currently selected account
 */
- (IBAction)generate:(id)sender
{
	CBGaimAccount	*adiumAccount = [[popUp_accounts selectedItem] representedObject];
	GaimAccount		*gaimAccount;

	gaimAccount = accountLookupFromAdiumAccount(adiumAccount);
	
	otrg_plugin_create_privkey(gaim_account_get_username(gaimAccount),
							   gaim_account_get_protocol_id(gaimAccount));
}

/*
 * @brief Show the fingerprint for the contact selected in the fingerprints NSTableView
 */
- (IBAction)showFingerprint:(id)sender
{
	int selectedRow = [tableView_fingerprints selectedRow];
	if (selectedRow != -1) {
		NSDictionary	*fingerprintDict = [fingerprintDictArray objectAtIndex:selectedRow];
		[ESGaimOTRFingerprintDetailsWindowController showDetailsForFingerprintDict:fingerprintDict];
	}
}

//Fingerprint tableview ------------------------------------------------------------------------------------------------
#pragma mark Fingerprint tableview
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [fingerprintDictArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((rowIndex >= 0) && (rowIndex < [fingerprintDictArray count])) {
		NSString		*identifier = [aTableColumn identifier];
		NSDictionary	*fingerprintDict = [fingerprintDictArray objectAtIndex:rowIndex];
		
		if ([identifier isEqualToString:@"UID"]) {
			return [fingerprintDict objectForKey:@"UID"];
			
		} else if ([identifier isEqualToString:@"Status"]) {
			return [fingerprintDict objectForKey:@"Status"];
			
		}
	}

	return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int selectedRow = [tableView_fingerprints selectedRow];
	[button_showFingerprint setEnabled:(selectedRow != -1)];
}


//Account menu ---------------------------------------------------------------------------------------------------------
#pragma mark Account menu
/*
 * @brief Account menu delegate
 */ 
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	[popUp_accounts setMenu:[inAccountMenu menu]];
}
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[self updatePrivateKeyList];
}
- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount {
	return [inAccount isKindOfClass:[CBGaimAccount class]];
}

@end
