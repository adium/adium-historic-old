/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "ErrorMessageHandlerPlugin.h"
#import "ErrorMessageWindowController.h"
#import "ESPanelAlertDetailPane.h"

#define ERROR_MESSAGE_ALERT_SHORT	@"Display an alert"
#define ERROR_MESSAGE_ALERT_LONG	@"Display the alert \"%@\""

@implementation ErrorMessageHandlerPlugin

- (void)installPlugin
{
    //Install our observers
    [[adium notificationCenter] addObserver:self
								   selector:@selector(handleError:)
									   name:Interface_ShouldDisplayErrorMessage 
									 object:nil];
    
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:ERROR_MESSAGE_CONTACT_ALERT_IDENTIFIER withHandler:self];

	[[adium contactAlertsController] registerEventID:INTERFACE_ERROR_MESSAGE withHandler:self globalOnly:YES];
}

- (void)uninstallPlugin
{
    [ErrorMessageWindowController closeSharedInstance]; //Close the error window
}

- (void)handleError:(NSNotification *)notification
{
    NSDictionary	*userInfo;
    NSString		*errorTitle;
    NSString		*errorDesc;
    NSString		*windowTitle;
    
    //Get the error info
    userInfo = [notification userInfo];
    errorTitle = [userInfo objectForKey:@"Title"];
    errorDesc = [userInfo objectForKey:@"Description"];
    windowTitle = [userInfo objectForKey:@"Window Title"];

    //Display an alert
    [[ErrorMessageWindowController errorMessageWindowController] displayError:errorTitle 
															  withDescription:errorDesc
																	withTitle:windowTitle];
	
	//Generate the event (for no list object, so only global triggers apply)
	[[adium contactAlertsController] generateEvent:INTERFACE_ERROR_MESSAGE
									 forListObject:nil
										  userInfo:nil];
}


//Display Dialog Alert -------------------------------------------------------------------------------------------------
#pragma mark Display Dialog Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(ERROR_MESSAGE_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString	*alertText = [[details objectForKey:KEY_ALERT_TEXT] lastPathComponent];
	
	if(alertText && [alertText length]){
		return([NSString stringWithFormat:ERROR_MESSAGE_ALERT_LONG, alertText]);
	}else{
		return(ERROR_MESSAGE_ALERT_LONG);
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"ErrorAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESPanelAlertDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
    NSString    *dateString = [[NSCalendarDate calendarDate] descriptionWithCalendarFormat:[NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:YES]];
	NSString	*alertText = [[details objectForKey:KEY_ALERT_TEXT] lastPathComponent];

    [[adium interfaceController] handleMessage:[listObject displayName]
							   withDescription:(alertText ? [NSString stringWithFormat:@"%@: %@", dateString, alertText] : @"")
							   withWindowTitle:@"Contact Alert"];
}


#pragma mark Error Message event
// Error Message Event (global only)
- (NSString *)shortDescriptionForEventID:(NSString *)eventID {	return @""; }

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:INTERFACE_ERROR_MESSAGE]){
		description = AILocalizedString(@"Error",nil);
	}else{
		description = @"";
	}
	
	return(description);
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:INTERFACE_ERROR_MESSAGE]){
		description = @"Error";
	}else{
		description = @"";
	}
	
	return(description);
}


- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject	{ return @""; }



@end
