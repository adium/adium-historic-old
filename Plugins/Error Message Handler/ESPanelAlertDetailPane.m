//
//  ESAlertMessageContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Nov 29 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
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
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	NSString *alertText = [inDetails objectForKey:KEY_ALERT_TEXT];

	[view_alertText setString:(alertText ? alertText : @"")];
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	if([view_alertText string]){
		return([NSDictionary dictionaryWithObject:[view_alertText string] forKey:KEY_ALERT_TEXT]);
	}else{
		return(nil);
	}
}

@end
