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

#import "AILoggerPlugin.h"
#import "AILogViewerWindowController.h"
#import "AILoggerPreferences.h"
#import "AILoggerAdvancedPreferences.h"

#define LOGGING_DEFAULT_PREFS	@"LoggingDefaults"

@interface AILoggerPlugin (PRIVATE)
- (void)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andObject:(NSString *)object onDate:(NSDate *)date;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AILoggerPlugin

- (void)installPlugin
{
    observingContent = NO;

    //Setup our preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LOGGING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_LOGGING];
    preferences = [[AILoggerPreferences preferencePaneWithOwner:owner] retain];
    advancedPreferences = [[AILoggerAdvancedPreferences preferencePaneWithOwner:owner] retain];

    //Install the log viewer menu item
    logViewerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Log Viewer" target:self action:@selector(showLogViewer:) keyEquivalent:@"l"];
    [[owner menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxilary];

    //Install the 'view logs' menu item
    viewContactLogsMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Contact's Logs" target:self action:@selector(showLogViewerToSelectedContact:) keyEquivalent:@"L"];
    [[owner menuController] addMenuItem:viewContactLogsMenuItem toLocation:LOC_Contact_Manage];

    //Install a 'view logs' contextual menu item
    viewContactLogsContextMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Logs" target:self action:@selector(showLogViewerToSelectedContextContact:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:viewContactLogsContextMenuItem toLocation:Context_Contact_Manage];
    
    //Create a logs directory
    logBasePath = [[[[[owner loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath] retain];
    [AIFileUtilities createDirectory:logBasePath];

    //Observe preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_LOGGING] == 0){
        NSDictionary    *preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_LOGGING];
        BOOL            newLogValue;
        
        //Load new values
        logStyle = [[preferenceDict objectForKey:KEY_LOGGER_STYLE] boolValue];
        logFont = [[preferenceDict objectForKey:KEY_LOGGER_FONT] boolValue];
        logStatus = [[preferenceDict objectForKey:KEY_LOGGER_STATUS] boolValue];
        logHTML = [[preferenceDict objectForKey:KEY_LOGGER_HTML] boolValue];
        
        //Start/Stop logging
        newLogValue = [[preferenceDict objectForKey:KEY_LOGGER_ENABLE] boolValue];
        if(newLogValue != observingContent){
            observingContent = newLogValue;

            if(!observingContent){ //Stop Logging
                [[owner notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];

            }else{ //Start Logging
                [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:nil];
                
            }
        }
    }
}

//
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL valid = YES;

    if(menuItem == viewContactLogsMenuItem){
        AIListContact	*selectedContact = [[owner contactController] selectedContact];

        if(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]){
            [viewContactLogsMenuItem setTitle:[NSString stringWithFormat:@"View %@'s Logs",[selectedContact displayName]]];
        }else{
            [viewContactLogsMenuItem setTitle:@"View Contact's Logs"];
            valid = NO;
        }
    }else if(menuItem == viewContactLogsContextMenuItem){
        AIListContact	*selectedContact = [[owner menuController] contactualMenuContact];
        if ( !(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]) )
              valid = NO;
    }
    return(valid);
}

//
- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];

    AIChat		*chat = nil;
    NSAttributedString	*message = nil;
    AIAccount		*account = nil;
    NSString		*object = nil;
    AIListObject	*source = nil;
    NSDate		*date = nil;
    NSString		*dateString = nil;
    NSString		*logMessage = nil;
    BOOL		closeStyle = NO;
    
    if(logFont && logStyle) closeStyle = YES;
    else closeStyle=NO;

    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        date = [content date];
        dateString = [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
        chat	= [notification object];
        object  = [[chat statusDictionary] objectForKey:@"DisplayName"];
           if(!object) object = [[chat listObject] UID];
        account	= [chat account];
	source	= [content source];
	message = [[content message] safeString];

        if(account &&/* object && */source){
            if (logHTML) {

                NSString  *sendOrReceive;

                if ([[account UID] isEqualTo:[source UID]]) {
                    sendOrReceive = [NSString stringWithString:@"send"];
                } else {
                    sendOrReceive = [NSString stringWithString:@"receive"];
                }

                logMessage = [NSString stringWithFormat:@"<div class=\"%@\"><span class=\"timestamp\">%@</span> <span class=\"sender\">%@:</span><pre class=\"message\">%@</pre></div>\n", sendOrReceive, dateString, [source UID], [AIHTMLDecoder encodeHTML:message headers:NO fontTags:logFont closeFontTags:logFont styleTags:logStyle closeStyleTagsOnFontChange:closeStyle]];

            } else {
                logMessage = [NSString stringWithFormat:@"(%@)%@:%@\n", dateString, [source UID], [message string]];
            }
	}

    }else if([[content type] compare:CONTENT_STATUS_TYPE] == 0 && logStatus){
        date = [content date];
        dateString = [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
        chat	= [notification object];
        object  = [[chat statusDictionary] objectForKey:@"DisplayName"];
           if(!object) object = [[chat listObject] UID];
	account	= [chat account];
	source	= [content source];
        message = [content message];

        if(account && source){
            if(logHTML) {
                logMessage = [NSString stringWithFormat:@"<div class=\"status\">%@ (%@)</div>\n", message, dateString];
            } else {
                logMessage = [NSString stringWithFormat:@"<%@ (%@)>\n", message, dateString];
            }
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
- (void)_addMessage:(NSString *)message betweenAccount:(AIAccount *)account andObject:(NSString *)object onDate:(NSDate *)date
{
    NSString	*logPath;
    NSString	*logFileName;
    FILE	*file;

    //Create path to log file (.../Logs/ServiceID.AccountUID/HandleUID/HandleUID (YY|MM|DD).adiumLog)
    logPath = [[logBasePath stringByAppendingPathComponent:[account UIDAndServiceID]] stringByAppendingPathComponent:object];
    if(logHTML) {
        logFileName = [NSString stringWithFormat:@"%@_(%@).adiumLog.html", object, [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];
    } else {
        logFileName = [NSString stringWithFormat:@"%@ (%@).adiumLog", object, [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];
    }

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
    return @"This plugin implements chat logging with a variable amount of HTML.";
}

- (NSString *)pluginVersion {
    return @"1.0d2";
}

- (NSString *)pluginURL {
    return @"http://www.atommic.com/software/adium/";
}

@end
