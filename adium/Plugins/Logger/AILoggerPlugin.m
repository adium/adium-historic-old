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

@interface AILoggerPlugin (PRIVATE)
- (void)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andObject:(AIListObject *)object onDate:(NSDate *)date;
@end

@implementation AILoggerPlugin

- (void)installPlugin
{
    //Observe content
    [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:nil];

    //Install the log viewer menu item
    logViewerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Log Viewer" target:self action:@selector(showLogViewer:) keyEquivalent:@"l"];
    [[owner menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxilary];

    //Install the 'view logs' menu item
    viewContactLogsMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Contact's Logs" target:self action:@selector(showLogViewerToSelectedContact:) keyEquivalent:@"L"];
    [[owner menuController] addMenuItem:viewContactLogsMenuItem toLocation:LOC_Contact_Action];

    //Install a 'view logs' contextual menu item
    viewContactLogsContextMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Logs" target:self action:@selector(showLogViewerToSelectedContextContact:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:viewContactLogsContextMenuItem toLocation:Context_Contact_Manage];
    
    //Create a logs directory
    logBasePath = [[[[[owner loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath] retain];
    [AIFileUtilities createDirectory:logBasePath];
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
        valid = ([[owner menuController] contactualMenuContact] != nil);

    }

    return(valid);
}

- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];

    AIChat		*chat = nil;
    NSString		*message = nil;
    AIAccount		*account = nil;
    AIListObject	*object = nil;
    AIListObject	*source = nil;

    NSDate	*date = [content date];
    NSString	*dateString = [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];

    NSString	*logMessage = nil;

    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
	chat	= [notification object];
	account	= [chat account];
	object	= [chat object];
	source	= [content source];
	
	message = (NSString *)[[content message] safeString];
	
        if(account && object && source){
	    logMessage = [NSString stringWithFormat:@"(%@)%@:%@\n", dateString, [source UID], message];
	}

    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0){
	chat	= [notification object];
	account	= [chat account];
	object	= [chat object];
	source	= [content source];
	
	message = (NSString *)[content message];

	//only log the status change if the contact has a currently open tab
	//this doesn't match the actual status notification of adium, but it does match the logging of 1.x
        if(account && object && source && [[object statusArrayForKey:@"Open Tab"] greatestIntegerValue]){
	    logMessage = [NSString stringWithFormat:@"<%@ (%@)>\n", message, dateString];
	}
    }

    //Log the message
    if(logMessage != nil){
        [self _addMessage:logMessage betweenAccount:account andObject:object onDate:date];
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
    [[AILogViewerWindowController logViewerWindowControllerWithOwner:owner] showWindow:nil];
    [[AILogViewerWindowController logViewerWindowControllerWithOwner:owner] showLogsForContact:[[owner contactController] selectedContact]];
}

//Show the log viewer, displaying the selected contact's logs
- (void)showLogViewerToSelectedContextContact:(id)sender
{
    [[AILogViewerWindowController logViewerWindowControllerWithOwner:owner] showWindow:nil];
    [[AILogViewerWindowController logViewerWindowControllerWithOwner:owner] showLogsForContact:[[owner menuController] contactualMenuContact]];
}

//Add a message to the specified log file
- (void)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andObject:(AIListObject *)object onDate:(NSDate *)date
{
    NSString	*logPath;
    NSString	*logFileName;
    FILE	*file;

    //Create path to log file (.../Logs/ServiceID.AccountUID/HandleUID/HandleUID (YY|MM|DD).adiumLog)
    logPath = [[logBasePath stringByAppendingPathComponent:[account UIDAndServiceID]] stringByAppendingPathComponent:[object UID]];
    logFileName = [NSString stringWithFormat:@"%@ (%@).adiumLog", [object UID], [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];

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
