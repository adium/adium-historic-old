//
//  ESSendMessageContactAlertPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 28 2003.

#define KEY_MESSAGE_SENDTO_UID		@"Destination UID"
#define KEY_MESSAGE_SENDTO_SERVICE	@"Destination Service"
#define KEY_MESSAGE_SENDFROM		@"Account ID"
#define KEY_MESSAGE_OTHERACCOUNT	@"Allow Other"		//allow other account
#define KEY_MESSAGE_ERROR		@"Display Error"

#define PREF_GROUP_FORMATTING			@"Formatting"
#define KEY_FORMATTING_FONT			@"Default Font"
#define KEY_FORMATTING_TEXT_COLOR		@"Default Text Color"
#define KEY_FORMATTING_BACKGROUND_COLOR		@"Default Background Color"
#define KEY_FORMATTING_SUBBACKGROUND_COLOR	@"Default SubBackground Color"

#define CONTACT_ALERT_IDENTIFIER            @"Message"

@interface ESSendMessageContactAlertPlugin : AIPlugin <ESContactAlertProvider>{
    NSDictionary *attributes;
}

@end
