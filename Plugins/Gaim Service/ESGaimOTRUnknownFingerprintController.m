//
//  ESGaimOTRUnknownFingerprintController.m
//  Adium
//
//  Created by Evan Schoenberg on 2/9/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESGaimOTRUnknownFingerprintController.h"
#import "ESTextAndButtonsWindowController.h"
#import "SLGaimCocoaAdapter.h"

@implementation ESGaimOTRUnknownFingerprintController

+ (void)showUnknownFingerprintPromptForUsername:(const char *)who
									   protocol:(const char *)protocol
										   hash:(const char *)hash
								   responseInfo:(NSDictionary *)responseInfo
{
	NSString			*messageString;

	messageString = [NSString stringWithFormat:
		AILocalizedString(@"%s (%s) has sent you an unknown encryption fingerprint:\n\n%s\n\nDo you want to accept this fingerprint as valid?", nil),
		who,
		(protocol ? protocol : [AILocalizedString(@"Unknown", nil) UTF8String]), 
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
	otrg_adium_unknown_fingerprint_response(responseInfo, [fingerprintAcceptedNumber boolValue]);
}

@end
