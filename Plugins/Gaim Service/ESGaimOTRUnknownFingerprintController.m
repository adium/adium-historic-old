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

#import "ESGaimOTRUnknownFingerprintController.h"
#import "ESTextAndButtonsWindowController.h"
#import "SLGaimCocoaAdapter.h"
#import "adiumGaimOTR.h"
#import <Adium/NDRunLoopMessenger.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIServiceIcons.h>
#import "AIAccountController.h"

#import "gaimOTRCommon.h"

@implementation ESGaimOTRUnknownFingerprintController

+ (void)showUnknownFingerprintPromptWithResponseInfo:(NSDictionary *)responseInfo
{
	NSString							*messageString;
	NSString							*accountname = [responseInfo objectForKey:@"accountname"];
	NSString							*who = [responseInfo objectForKey:@"who"];
	NSString							*ourHash = [responseInfo objectForKey:@"Outgoing SessionID"];
	NSString							*theirHash = [responseInfo objectForKey:@"Incoming SessionID"];
	ESTextAndButtonsWindowController	*windowController;
	
	messageString = [NSString stringWithFormat:
		AILocalizedString(@"%@ has sent you (%@) an unknown encryption fingerprint.\n\n"
						  "Fingerprint for you: %@\n\n"
						  "Purported fingerprint for %@: %@\n\n"
						  "Accept this fingerprint as verified?",nil),
		who,
		accountname,
		ourHash,
		who,
		theirHash];
	
	GaimAccount *account = gaim_accounts_find([accountname UTF8String], [[responseInfo objectForKey:@"protocol"] UTF8String]);
	NSImage		*serviceImage = nil;
	
	if (account) {
		serviceImage = [AIServiceIcons serviceIconForObject:accountLookup(account)
													   type:AIServiceIconLarge
												  direction:AIIconNormal];
	}
	
	windowController = [ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:AILocalizedString(@"OTR Fingerprint Verification",nil)
																			 defaultButton:AILocalizedString(@"Accept",nil)
																		   alternateButton:AILocalizedString(@"Verify Later",nil)
																			   otherButton:AILocalizedString(@"Help", nil)
																				  onWindow:nil
																		 withMessageHeader:nil
																				andMessage:[AIHTMLDecoder decodeHTML:messageString]
																					 image:serviceImage
																					target:self
																				  userInfo:responseInfo];	
}

/*!
* @brief Window was closed, either by a button being clicked or the user closing it
 */
+ (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo
{
	BOOL	shouldCloseWindow = YES;
	
	if (userInfo && [userInfo objectForKey:@"Fingerprint"]) {
		BOOL	fingerprintAccepted;
		
		if (returnCode == AITextAndButtonsOtherReturn) {
			NSString			*who = [userInfo objectForKey:@"who"];
			
			NSString *message = [NSString stringWithFormat:AILocalizedString(@"A fingerprint is a unique identifier "
																			 "that you should use to verify the identity of %@.\n\nTo verify the fingerprint, contact %@ via some "
																			 "other authenticated channel such as the telephone or GPG-signed email. "
																			 "Each of you should tell your fingerprint to the other.", nil),
				who,
				who];
			
			[ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:nil
																  defaultButton:nil
																alternateButton:nil
																	otherButton:nil
																	   onWindow:window
															  withMessageHeader:AILocalizedString(@"Fingerprint Help", nil)
																	 andMessage:[[[NSAttributedString alloc] initWithString:message] autorelease]
																		 target:self
																	   userInfo:nil];	
			
			//Don't close the original window if the help button is pressed
			shouldCloseWindow = NO;
			
		} else {
			fingerprintAccepted = ((returnCode == AITextAndButtonsDefaultReturn) ? YES : NO);
			
			//Use the gaim thread to perform the response
			[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
											 performSelector:@selector(gaimThreadUnknownFingerprintResponseInfo:wasAccepted:)
												  withObject:userInfo
												  withObject:[NSNumber numberWithBool:fingerprintAccepted]];
			
		}
	}
	
	return shouldCloseWindow;
}

/*!
* @brief Called on the gaim thread to pass the unknown fingerprint response on to the OTR core
 */
+ (void)gaimThreadUnknownFingerprintResponseInfo:(NSDictionary *)responseInfo wasAccepted:(NSNumber *)fingerprintAcceptedNumber
{
	NSString			*protocol = [responseInfo objectForKey:@"protocol"];
	NSString			*accountname = [responseInfo objectForKey:@"accountname"];
	NSString			*who = [responseInfo objectForKey:@"who"];
	NSString			*fingerprint = [responseInfo objectForKey:@"Fingerprint"];
	
	ConnContext *context = otrl_context_find(otrg_get_userstate(),
											 [who UTF8String], [accountname UTF8String], [protocol UTF8String],
											 0, NULL, NULL, NULL);
    Fingerprint *fprint;
    BOOL oldtrust, trust;
	
    if (context == NULL) return;
	
    fprint = otrl_context_find_fingerprint(context, (unsigned char *)[fingerprint UTF8String],
										   0, NULL);
	
    if (fprint == NULL) return;
	
    oldtrust = (fprint->trust && fprint->trust[0]);
    trust = [fingerprintAcceptedNumber boolValue];
	
    /* See if anything's changed */
    if (trust != oldtrust) {
		otrl_context_set_trust(fprint, trust ? "verified" : "");
		/* Write the new info to disk, redraw the ui, and redraw the
		* OTR buttons. */
		otrg_plugin_write_fingerprints();
		otrg_ui_update_keylist();
		otrg_dialog_resensitize_all();
    }	
}

@end
