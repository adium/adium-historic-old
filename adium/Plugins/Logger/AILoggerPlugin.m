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
- (void)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andHandle:(AIHandle *)handle onDate:(NSDate *)date;
@end

@implementation AILoggerPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LOGGER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_LOGGING];

    //Observe content sending and receiving
    [[owner notificationCenter] addObserver:self selector:@selector(adiumSentContent:) name:Content_DidSendContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(adiumReceivedContent:) name:Content_DidReceiveContent object:nil];

    //Install the log viewer menu item
    logViewerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Log Viewer" target:self action:@selector(showLogViewer:) keyEquivalent:@"l"];
    [[owner menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxilary];

    //Install the 'view logs' menu item
    viewContactLogsMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Contact's Logs" target:self action:@selector(showLogViewerToSelectedContact:) keyEquivalent:@"L"];
    [[owner menuController] addMenuItem:viewContactLogsMenuItem toLocation:LOC_Contact_Action];
    
    
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
        AIHandle	*handle = [content destination];

        //Log the message
        [self _addMessage:[NSString stringWithFormat:@"(%@)%@:%@\n", dateString, [account UID], message]
            betweenAccount:account
                andHandle:handle
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
        AIHandle	*handle = [content source];
        
        //Log the message
        [self _addMessage:[NSString stringWithFormat:@"(%@)%@:%@\n", dateString, [handle UID], message]
           betweenAccount:account
                andHandle:handle
                   onDate:date];
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
- (void)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andHandle:(AIHandle *)handle onDate:(NSDate *)date
{
    NSString	*logPath;
    NSString	*logFileName;
    FILE	*file;

    //Create path to log file (.../Logs/ServiceID.AccountUID/HandleUID/HandleUID (YY|MM|DD).adiumLog)
    logPath = [[logBasePath stringByAppendingPathComponent:[account UIDAndServiceID]] stringByAppendingPathComponent:[handle UID]];
    logFileName = [NSString stringWithFormat:@"%@ (%@).adiumLog", [handle UID], [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];

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
