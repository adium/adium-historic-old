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

#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AILoggerPlugin.h"
#import "AILogViewerWindowController.h"
#import "AILogImporter.h"

#define LOGGER_DEFAULT_PREFS		@"LoggerDefaults"
#define PREF_GROUP_LOGGING		@"Logging"
#define KEY_HAS_IMPORTED_16_LOGS	@"Has Imported Adium 1.6 Logs"

@interface AILoggerPlugin (PRIVATE)
- (void)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andContact:(AIListContact *)contact onDate:(NSDate *)date;
@end

@implementation AILoggerPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LOGGER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_LOGGING];

    //Observe content sending and receiving
    //[[owner notificationCenter] addObserver:self selector:@selector(adiumSentContent:) name:Content_DidSendContent object:nil];
    //[[owner notificationCenter] addObserver:self selector:@selector(adiumReceivedContent:) name:Content_DidReceiveContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:nil];

    //Install the log viewer menu item
    logViewerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Log Viewer" target:self action:@selector(showLogViewer:) keyEquivalent:@"l"];
    [[owner menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxilary];

    //Install the 'view logs' menu item
    viewContactLogsMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Contact's Logs" target:self action:@selector(showLogViewerToSelectedContact:) keyEquivalent:@"L"];
    [[owner menuController] addMenuItem:viewContactLogsMenuItem toLocation:LOC_Contact_Action];

    //Install a 'view logs' contextual menu item
    viewContactLogsContextMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Logs" target:self action:@selector(showLogViewerToSelectedContact:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:viewContactLogsContextMenuItem toLocation:Context_Contact_Manage];
    
    //Create a logs directory
    logBasePath = [[[[[owner loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath] retain];
    [AIFileUtilities createDirectory:logBasePath];

    //Import Adium 1.6 logs
    if(![[[[owner preferenceController] preferencesForGroup:PREF_GROUP_LOGGING] objectForKey:KEY_HAS_IMPORTED_16_LOGS] boolValue]){
        [[AILogImporter logImporterWithOwner:owner] importAdium1xLogs];

        [[owner preferenceController] setPreference:[NSNumber numberWithBool:YES]
                                             forKey:KEY_HAS_IMPORTED_16_LOGS
                                              group:PREF_GROUP_LOGGING];
    }
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL valid = YES;

    if(menuItem == viewContactLogsMenuItem){
        AIListContact	*selectedContact = [[owner contactController] selectedContact];

        if(selectedContact){
            [viewContactLogsMenuItem setTitle:[NSString stringWithFormat:@"View %@'s Logs",[selectedContact displayName]]];
        }else{
            [viewContactLogsMenuItem setTitle:@"View Contact's Logs"];
            valid = NO;
        }
        
    }else if(menuItem == viewContactLogsContextMenuItem){
        AIListContact	*selectedContact = [[owner contactController] selectedContact];

        valid = (selectedContact != nil);
    }

    return(valid);
}

//Content was sent
- (void)adiumSentContent:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];

    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSDate		*date = [content date];
        NSString	*dateString = [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
        NSString	*message = [[content message] string];
        AIAccount	*account = [content source];
        AIListContact	*contact = [content destination];

        //Log the message
        [self _addMessage:[NSString stringWithFormat:@"(%@)%@:%@\n", dateString, [account UID], message]
            betweenAccount:account
                andContact:contact
                    onDate:date];
    }
}

//Content was received
- (void)adiumReceivedContent:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];

    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        NSDate		*date = [content date];
        NSString	*dateString = [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
        NSString	*message = [[content message] string];
        AIAccount	*account = [content destination];
        AIListContact	*contact = [content source];

        //Log the message
        [self _addMessage:[NSString stringWithFormat:@"(%@)%@:%@\n", dateString, [contact UID], message]
           betweenAccount:account
               andContact:contact
                   onDate:date];
    }
}

//Content was added
/* this observer method could replace both the above sending and recieving observers
 * by using:
 * [[content destination] isKindOfClass:[AIAccount class]] and
 * [[content destination] isKindOfClass:[AIAccount class]]
 * to determine whether the message is sending or recieving
 * the only reason for using Content_ContentObjectAdded is because status changes are not
 * recieved content.
 *
 * the downside to moving both to this method is the reliance on isKindOfClass
 * the downside to not moving it is that the contentObjectAdded observer is activated
 * twice as often as is needed
 */
- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];

    NSString		*message = nil;
    AIAccount		*account = nil;
    AIListContact	*contact = nil;

    NSDate	*date = [content date];
    NSString	*dateString = [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];

    NSString	*logMessage = nil;

    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
	if([[content destination] isKindOfClass:[AIAccount class]] && [[content source] isKindOfClass:[AIListContact class]]){
	    account = [content destination];
	    contact = [content source];

	}else if([[content source] isKindOfClass:[AIAccount class]] && [[content destination] isKindOfClass:[AIListContact class]]){
	    account = [content source];
	    contact = [content destination];

	}
	
	message = (NSString *)[[content message] string];
	
        if(account && contact){
//	    logMessage = [NSString stringWithFormat:@"(%@)%@:%@\n", dateString, [contact UID], message];
	}

    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
        account = [content destination];
        contact = [content source];

	message = (NSString *)[content message];

	//only log the status change if the contact has a currently open tab
	//this doesn't match the actual status notification of adium, but it does match the logging of 1.x
        if(account && contact && [[contact statusArrayForKey:@"Open Tab"] greatestIntegerValue]){
	    logMessage = [NSString stringWithFormat:@"<%@ (%@)>\n", message, dateString];
	}
    }

    //Log the message
    if(logMessage != nil){
        [self _addMessage:logMessage betweenAccount:account andContact:contact onDate:date];
	//NSLog(@"account:%@ contact:%@ message:%@",[account UID], [contact UID], logMessage);
    }
}

//Show the log viewer window
- (void)showLogViewer:(id)sender
{
    [[AILogViewerWindowController logViewerWindowControllerWithOwner:owner] showWindow:nil];
}

//Show the log viewer, displaying the selected contact's logs
- (void)showLogViewerToSelectedContact:(id)sender
{
    AIListContact	*selectedContact = [[owner contactController] selectedContact];
    
    [[AILogViewerWindowController logViewerWindowControllerWithOwner:owner] showWindow:nil];

    if(selectedContact){
        [[AILogViewerWindowController logViewerWindowControllerWithOwner:owner] showLogsForContact:selectedContact];
    }
}

//Add a message to the specified log file
- (void)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andContact:(AIListContact *)contact onDate:(NSDate *)date
{
    NSString	*logPath;
    NSString	*logFileName;
    FILE	*file;

    //Create path to log file (.../Logs/ServiceID.AccountUID/HandleUID/HandleUID (YY|MM|DD).adiumLog)
    logPath = [[logBasePath stringByAppendingPathComponent:[account UIDAndServiceID]] stringByAppendingPathComponent:[contact UID]];
    logFileName = [NSString stringWithFormat:@"%@ (%@).adiumLog", [contact UID], [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];

    //Create a directory for this log (if one doesn't exist)
    [AIFileUtilities createDirectory:logPath];

    //Append the new content (We use fopen/fputs/fclose for max speed)
    file = fopen([[logPath stringByAppendingPathComponent:logFileName] cString], "a");
    fputs([message cString], file);
    fclose(file);
}

- (NSString *)pluginAuthor {
    return @"Adam Atlas";
}

- (NSString *)pluginDescription {
    return @"This plugin implements chat logging like that of Adium 1.x.";
}

- (NSString *)pluginVersion {
    return @"1.0d2";
}

- (NSString *)pluginURL {
    return @"http://www.atommic.com/software/adium/";
}

@end
