/*-------------------------------------------------------------------------------------------------------*\
| AISQLLoggerPlugin 1.0 for Adium                                                                         |
| AILoggerPlugin: Copyright (C) 2002 Jeffrey Melloy.                                                      |
| <jmelloy@visualdistortion.org> <http://www.visualdistortion.org/adium/>                                 |
| Adium: Copyright (C) 2001-2003 Adam Iser. <adamiser@mac.com> <http://www.adiumx.com>                    |---\
\---------------------------------------------------------------------------------------------------------/   |
  | This program is free software; you can redistribute it and/or modify it under the terms of the GNU        |
  | General Public License as published by the Free Software Foundation; either version 2 of the License,     |
  | or (at your option) any later version.                                                                    |
  |                                                                                                           |
  | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even    |
  | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General         |
  | Public License for more details.                                                                          |
  |                                                                                                           |
  | You should have received a copy of the GNU General Public License along with this program; if not,        |
  | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.    |
  \----------------------------------------------------------------------------------------------------------*/
/*
 * $Revision: 1.39 $
 * $Date: 2004/02/10 23:45:56 $
 * $Author: evands $
 *
 */

#import "AISQLLoggerPlugin.h"
#import "libpq-fe.h"
#import "JMSQLLogViewerWindowController.h"
#import "JMSQLLoggerAdvancedPreferences.h"

#define SQL_LOG_VIEWER  AILocalizedString(@"SQL Log Viewer",nil)

@interface AISQLLoggerPlugin (PRIVATE)
- (void)_addMessage:(NSAttributedString *)message dest:(NSString *)destName source:(NSString *)sourceName sendDisplay:(NSString *)sendDisp destDisplay:(NSString *)destDisp sendServe:(NSString *)s_service recServe:(NSString *)r_service;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AISQLLoggerPlugin

- (void)installPlugin
{
    NSMenuItem	*logViewerMenuItem;
	NSString	*connInfo;
	id			tmp;
	
    //Install some prefs.
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SQL_LOGGING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_SQL_LOGGING];
    advancedPreferences = [[JMSQLLoggerAdvancedPreferences preferencePane] retain];
    
    //Install Menu item
    //logViewerMenuItem = [[[NSMenuItem alloc] initWithTitle:SQL_LOG_VIEWER target:self action:@selector(showLogViewer:) keyEquivalent:@""] autorelease];
    //[[adium menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxiliary];

	//Watch for pref changes
	[[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
	[self preferencesChanged:nil];

	if([username isEqualToString:@""] ) {
		username = nil;
	}

	if ([database isEqualToString:@""] ) {
		database = nil;
	}

	connInfo = [NSString stringWithFormat:@"host=\'%@\' port=\'%@\' user=\'%@\' password=\'%@\' dbname=\'%@\' sslmode=\'prefer\'", 
						(tmp = url) ? tmp: @"", (tmp = port) ? tmp: @"", (tmp = username) ? tmp: NSUserName(), 
				   (tmp = password) ? tmp: @"", (tmp = database) ? tmp: NSUserName()];

    conn = PQconnectdb([connInfo cString]);
    if (PQstatus(conn) == CONNECTION_BAD)
    {
        NSString *error =  [NSString stringWithCString:PQerrorMessage(conn)];
        [[adium interfaceController] handleErrorMessage:@"Connection to database failed." withDescription:error];
    }
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_SQL_LOGGING compare:[[notification userInfo] objectForKey:@"Group"]] == 0){
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_SQL_LOGGING];
		bool			newLogValue;
		
		newLogValue = [[preferenceDict objectForKey:KEY_SQL_LOGGER_ENABLE] boolValue];
		username = [preferenceDict objectForKey:KEY_SQL_USERNAME];
		url = [preferenceDict objectForKey:KEY_SQL_URL];
		port = [preferenceDict objectForKey:KEY_SQL_PORT];
		database = [preferenceDict objectForKey:KEY_SQL_DATABASE];
		password = [preferenceDict objectForKey:KEY_SQL_PASSWORD];
		
		if(newLogValue != observingContent){
			observingContent = newLogValue;

			if(!observingContent){ //Stop Logging
				[[adium notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];

			}else{ //Start Logging
				[[adium notificationCenter] addObserver:self selector:@selector(adiumSentOrReceivedContent:) name:Content_ContentObjectAdded object:nil];		
			}
		}
    }
}

- (void)uninstallPlugin {
    PQfinish(conn);
}

//Content was sent or recieved
- (void)adiumSentOrReceivedContent:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];
    
    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIChat		*chat = [notification object];
        AIListObject	*source = [content source];
        AIListObject	*destination = [content destination];
        AIAccount	*account = [chat account];
        
        NSString	*srcDisplay = nil;
        NSString	*destDisplay = nil;
        NSString	*destUID = nil;
        NSString	*srcUID = nil;
        NSString	*destSrv = nil;
        NSString	*srcSrv = nil;
        
        if ([[account UID] isEqual:[source UID]]) {
            destUID  = [[chat statusDictionary] objectForKey:@"DisplayName"];
            if(!destUID) {
                destUID = [[chat listObject] UID];
                destDisplay = [[chat listObject] displayName];
            }
            else {
                destDisplay = destUID;
            }
            destSrv = [[chat account] serviceID];
            srcDisplay = [source displayName];
            srcUID = [source UID];
            srcSrv = [source serviceID];
        } else {
            destUID = [[chat statusDictionary] objectForKey:@"DisplayName"];
            if(!destUID) {
                srcDisplay = [[chat listObject] displayName];
                srcUID = [[chat listObject] UID];
                destUID = [destination UID];
                destDisplay = [destination displayName];
            }
            else {
                srcUID = [source UID];
                srcDisplay = srcUID;
                destDisplay = destUID;
            }
            srcSrv = [[chat account] serviceID];
            destSrv = srcSrv;
        }
        
        if(account && source){
            //Log the message
            [self _addMessage:[[content message] safeString]
                         dest:destUID
                       source:srcUID
                  sendDisplay:srcDisplay
                  destDisplay:destDisplay
                    sendServe:srcSrv
                     recServe:destSrv];
        }
    }
}

//Show the log viewer window
- (void)showLogViewer:(id)sender
{
    [[JMSQLLogViewerWindowController logViewerWindowController] showWindow:nil];
}

//Insert a message
- (void)_addMessage:(NSAttributedString *)message
               dest:(NSString *)destName
             source:(NSString *)sourceName
        sendDisplay:(NSString *)sendDisp
        destDisplay:(NSString *)destDisp
          sendServe:(NSString *)s_service
           recServe:(NSString *)r_service

{
    NSString	*sqlStatement;
    NSMutableString 	*escapeHTMLMessage;
    escapeHTMLMessage = [NSMutableString stringWithString:[AIHTMLDecoder encodeHTML:message headers:NO 
									   fontTags:NO closeFontTags:NO 
									  styleTags:YES closeStyleTagsOnFontChange:NO 
								     encodeNonASCII:YES imagesPath:nil]];
        
    char	escapeMessage[[escapeHTMLMessage length] * 2 + 1];
    char	escapeSender[[sourceName length] * 2 + 1];
    char	escapeRecip[[destName length] * 2 + 1];
    char	escapeSendDisplay[[sendDisp length] * 2 + 1];
    char	escapeRecDisplay[[destDisp length] * 2 + 1];
    
    PGresult *res;
        
    PQescapeString(escapeMessage, [escapeHTMLMessage UTF8String], [escapeHTMLMessage length]);
    PQescapeString(escapeSender, [sourceName UTF8String], [sourceName length]);
    PQescapeString(escapeRecip, [destName UTF8String], [destName length]);
    PQescapeString(escapeSendDisplay, [sendDisp UTF8String], [sendDisp length]);
    PQescapeString(escapeRecDisplay, [destDisp UTF8String], [destDisp length]);
    
    sqlStatement = [NSString stringWithFormat:@"insert into adium.message_v (sender_sn, recipient_sn, message, sender_service, recipient_service, sender_display, recipient_display) values (\'%s\',\'%s\',\'%s\', \'%@\', \'%@\', \'%s\', \'%s\')", 
    escapeSender, escapeRecip, escapeMessage, s_service, r_service, escapeSendDisplay, escapeRecDisplay];
    
    res = PQexec(conn, [sqlStatement UTF8String]);
    if (!res || PQresultStatus(res) != PGRES_COMMAND_OK) {
        NSLog(@"%s / %s\n%@", PQresStatus(PQresultStatus(res)), PQresultErrorMessage(res), sqlStatement);
        [[adium interfaceController] handleErrorMessage:@"Insertion failed." withDescription:@"Database Insert Failed"];
        if (res) {
            PQclear(res);
        }
        
        if (PQresultStatus(res) == PGRES_NONFATAL_ERROR) {
            //Disconnect and reconnect.
            PQfinish(conn);
            conn = PQconnectdb("");
            if (PQstatus(conn) == CONNECTION_BAD)
            {
                [[adium interfaceController] handleErrorMessage:@"Database reconnect failed.." 			withDescription:@"Check your settings and try again."];
                NSLog(@"%s", PQerrorMessage(conn));
            } else {
                NSLog(@"Connection to PostgreSQL successfully made.");
            }
        }
    }
    if(res) {
        PQclear(res);
    }
}

- (NSString *)pluginAuthor {
    return @"Jeffrey Melloy";
}

- (NSString *)pluginDescription {
    return @"This plugin implements chat logging into a PostgreSQL database.";
}

- (NSString *)pluginVersion {
    return @"1.0";
}

- (NSString *)pluginURL {
    return @"http://www.visualdistortion.org/adium/";
}

@end
