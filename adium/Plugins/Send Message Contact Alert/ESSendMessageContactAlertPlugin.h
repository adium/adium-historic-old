//
//  ESSendMessageContactAlertPlugin.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.

#define KEY_MESSAGE_SENDTO_UID		@"Destination UID"
#define KEY_MESSAGE_SENDTO_SERVICE	@"Destination Service"
#define KEY_MESSAGE_SENDFROM		@"Account ID"
#define KEY_MESSAGE_OTHERACCOUNT	@"Allow Other"		//allow other account
#define KEY_MESSAGE_ERROR		@"Display Error"

#define CONTACT_ALERT_IDENTIFIER            @"Message"

@interface ESSendMessageContactAlertPlugin : AIPlugin <ESContactAlertProvider>{

}

@end
