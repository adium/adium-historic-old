/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
    [[adium notificationCenter] addObserver:self selector:@selector(handleError:) name:Interface_ErrorMessageReceived object:nil];
    
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:@"DisplayAlert" withHandler:self];
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
    [[ErrorMessageWindowController errorMessageWindowController] displayError:errorTitle withDescription:errorDesc withTitle:windowTitle];
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

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID
{
    NSString    *dateString = [[NSCalendarDate calendarDate] descriptionWithCalendarFormat:[NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:YES]];
	NSString	*alertText = [[details objectForKey:KEY_ALERT_TEXT] lastPathComponent];

    [[adium interfaceController] handleMessage:[listObject displayName]
							   withDescription:(alertText ? [NSString stringWithFormat:@"%@: %@", dateString, alertText] : @"")
							   withWindowTitle:@"Contact Alert"];
}

@end
