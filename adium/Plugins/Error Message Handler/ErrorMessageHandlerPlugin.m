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
#import "ESAlertMessageContactAlert.h"

@implementation ErrorMessageHandlerPlugin

- (void)installPlugin
{
    //Install our observers
    [[adium notificationCenter] addObserver:self selector:@selector(handleError:) name:Interface_ErrorMessageReceived object:nil];
    
    //Install our contact alert
    [[adium contactAlertsController] registerContactAlertProvider:self];
    
}

- (void)uninstallPlugin
{
    //Uninstall our contact alert
    [[adium contactAlertsController] unregisterContactAlertProvider:self];
    
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

    //Log to console
    NSLog([NSString stringWithFormat:@"%@: %@ (%@)",windowTitle,errorTitle,errorDesc]);

    //Display an alert
    [[ErrorMessageWindowController errorMessageWindowController] displayError:errorTitle withDescription:errorDesc withTitle:windowTitle];
}

//*****
//ESContactAlertProvider
//*****
#pragma mark ESContactAlertProvider

- (NSString *)identifier
{
    return CONTACT_ALERT_IDENTIFIER;
}

- (ESContactAlert *)contactAlert
{
    return [ESAlertMessageContactAlert contactAlert];   
}

//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName
{
    NSString *title = [NSString stringWithFormat:@"%@ %@", [inObject displayName], actionName];
    [[adium interfaceController] handleMessage:title 
							   withDescription:(details ? details : @"")
							   withWindowTitle:@"Contact Alert"];
    return YES;
}

//continue processing after a successful action
- (BOOL)shouldKeepProcessing
{
    return YES;
}

@end
