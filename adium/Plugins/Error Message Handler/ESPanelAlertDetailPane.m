//
//  ESAlertMessageContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Nov 29 2003.
//

#import "ESPanelAlertDetailPane.h"
#import "ErrorMessageHandlerPlugin.h"

@implementation ESPanelAlertDetailPane

//Pane Details
- (NSString *)label{
	return(@"");
}
- (NSString *)nibName{
    return(@"AlertMessageContactAlert");    
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails
{
	NSString *alertText = [inDetails objectForKey:KEY_ALERT_TEXT];
	if(alertText){
        [view_alertText setString:alertText];
	}
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	return([NSDictionary dictionaryWithObject:[view_alertText string] forKey:KEY_ALERT_TEXT]);
}

@end
