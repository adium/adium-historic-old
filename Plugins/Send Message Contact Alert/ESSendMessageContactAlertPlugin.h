//
//  ESSendMessageContactAlertPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.

#define KEY_MESSAGE_SEND_TO			@"Destination ID"
#define KEY_MESSAGE_SEND_FROM		@"Account ID"
#define KEY_MESSAGE_OTHER_ACCOUNT	@"Allow Other"
#define KEY_MESSAGE_SEND_MESSAGE	@"Message"

@interface ESSendMessageContactAlertPlugin : AIPlugin <AIActionHandler> {
    NSDictionary *attributes;
}

@end
