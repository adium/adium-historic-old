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
#import <AIUtilities/NDRunLoopMessenger.h>

@implementation ESGaimOTRUnknownFingerprintController

+ (void)showUnknownFingerprintPromptWithResponseInfo:(NSDictionary *)responseInfo
{
	NSString			*messageString;
	NSString			*protocol = [responseInfo objectForKey:@"protocol"];
	NSString			*who = [responseInfo objectForKey:@"who"];
	NSString			*hash = [responseInfo objectForKey:@"hash"];
	
	messageString = [NSString stringWithFormat:
		AILocalizedString(@"%@ (%@) has sent you an unknown encryption fingerprint:\n\n%@\n\nDo you want to accept this fingerprint as valid?", nil),
		who,
		([protocol length] ? protocol : AILocalizedString(@"Unknown", nil)), 
		hash];

	
	[ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:AILocalizedString(@"Unknown OTR fingerprint",nil)
														  defaultButton:AILocalizedString(@"Yes",nil)
														alternateButton:AILocalizedString(@"No",nil)
															otherButton:nil
															   onWindow:nil
													  withMessageHeader:nil
															 andMessage:[[[NSAttributedString alloc] initWithString:messageString] autorelease]
																 target:self
															   userInfo:responseInfo];
}

/*
 * @brief Window was closed, either by a button being clicked or the user closing it
 */
+ (void)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo
{
	BOOL	fingerprintAccepted;

	switch(returnCode){
		case AITextAndButtonsDefaultReturn:
			fingerprintAccepted = YES;
			break;

		case AITextAndButtonsAlternateReturn:
		case AITextAndButtonsOtherReturn:
		case AITextAndButtonsClosedWithoutResponse:
			fingerprintAccepted = NO;
			break;
	}	
	
	//Use the gaim thread to perform the response
	NSLog(@"unknown from %x",[NSRunLoop currentRunLoop]);
	[[SLGaimCocoaAdapter gaimThreadMessenger] target:self
									 performSelector:@selector(gaimThreadUnknownFingerprintResponseInfo:wasAccepted:)
										  withObject:userInfo
										  withObject:[NSNumber numberWithBool:fingerprintAccepted]];
	
	//XXX perform any other behaviors now
	
}

/*
 * @brief Called on the gaim thread to pass the unknown fingerprint response on to the OTR core
 */
+ (void)gaimThreadUnknownFingerprintResponseInfo:(NSDictionary *)responseInfo wasAccepted:(NSNumber *)fingerprintAcceptedNumber
{
	NSLog(@"moved to %x",[NSRunLoop currentRunLoop]);
	otrg_adium_unknown_fingerprint_response(responseInfo, [fingerprintAcceptedNumber boolValue]);
}

@end
