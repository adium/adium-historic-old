/*-------------------------------------------------------------------------------------------------------*\
| AISQLLoggerPlugin 1.0 for Adium                                                                         |
| AILoggerPlugin: Copyright (C) 2002 Jeffrey Melloy.                                                      |
| <jmelloy@visualdistortion.org> <http://www.visualdistortion.org/adium/>                                 |
| Adium: Copyright (C) 2001-2002 Adam Iser. <adamiser@mac.com> <http://www.adiumx.com>                    |---\
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

#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AISQLLoggerPlugin.h"
#import "libpq-fe.h"

@interface AISQLLoggerPlugin (PRIVATE)
- (void)_addMessage:(NSAttributedString *)message dest:(NSString *)destName source:(NSString *)sourceName date:(NSDate *)date sendServe:(NSString *)s_service recServe:(NSString *)r_service;

@end

@implementation AISQLLoggerPlugin

- (void)installPlugin
{
    //NSMenuItem	*logViewerMenuItem;

    //Observe content sending and receiving
    [[owner notificationCenter] addObserver:self selector:@selector(adiumSentContent:) name:Content_DidSendContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(adiumReceivedContent:) name:Content_DidReceiveContent object:nil];

    //Install the log viewer menu item
    //logViewerMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Log Viewer" target:self action:@selector(showLogViewer:) keyEquivalent:@"L"] autorelease];
    //[[owner menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxilary];
    
    conn = PQconnectdb("");
    if (PQstatus(conn) == CONNECTION_BAD)
    {
        NSLog(@"Connection to database failed.\n");
        NSLog(@"%s", PQerrorMessage(conn));
    }
}

- (void)uninstallPlugin {
    PQfinish(conn);
}

//Content was sent
- (void)adiumSentContent:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];
    

    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIAccount	*source = [content source];
        AIHandle	*destination = [content destination];
        
        //Source and destination are valid (account & handle)
        if([source isKindOfClass:[AIAccount class]] && [destination isKindOfClass:[AIHandle class]]){
            //Log the message
            [self _addMessage:[content message]
                        dest:[destination UID]
                       source:[source UID]
                         date:[content date]
                         sendServe:[source serviceID]
                         recServe:[destination serviceID]];
        }
    }
}

//Content was received
- (void)adiumReceivedContent:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];
    
    //Message Content
    if([[content type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIHandle	*source = [content source];
        AIAccount	*destination = [content destination];
        
        //Destination are valid (handle)
        if([source isKindOfClass:[AIHandle class]]){
            //Log the message
            [self _addMessage:[content message]
                        dest:[destination UID]
                       source:[source UID]
                         date:[content date]
                         sendServe:[source serviceID]
                         recServe:[destination serviceID]];
        }
    }
}

//Show the log viewer window
- (void)showLogViewer:(id)sender
{
    
}

//Add a message to the specified log file
- (void)_addMessage:
(NSAttributedString *)message 
dest:(NSString *)destName 
source:(NSString *)sourceName
date:(NSDate *)date
sendServe:(NSString *)s_service
recServe:(NSString *)r_service
{
    NSString	*sqlStatement;
    NSMutableString 	*escapeHTMLMessage;
    escapeHTMLMessage = [NSMutableString stringWithString:[AIHTMLDecoder encodeHTML:message encodeFullString:NO]];
    
    char	escapeMessage[[escapeHTMLMessage length] * 2 + 1];
    char	escapeSender[[sourceName length] * 2 + 1];
    char	escapeRecip[[destName length] * 2 + 1];
    
    PGresult *res;
        
    PQescapeString(escapeMessage, [escapeHTMLMessage UTF8String], [escapeHTMLMessage length]);
    PQescapeString(escapeSender, [sourceName UTF8String], [sourceName length]);
    PQescapeString(escapeRecip, [destName UTF8String], [destName length]);
    
    sqlStatement = [NSString stringWithFormat:@"insert into adium.messages (sender_sn, recipient_sn, message, message_date, sender_service, recipient_service) values (\'%s\',\'%s\',\'%s\', \'%@ %@\', \'%@\', \'%@\')", escapeSender, escapeRecip, escapeMessage, 
        [date descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil], [[NSDate date] 
        descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil],
        s_service, r_service];
        
    res = PQexec(conn, [sqlStatement UTF8String]);
    if (PQresultStatus(res) != PGRES_COMMAND_OK) {
        NSLog(@"%s / %s", PQresStatus(PQresultStatus(res)), PQresultErrorMessage(res));
        NSLog(@"Insert failed");
        PQclear(res);
    }

    PQclear(res);
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
    return @"http://www.visualdistortion.org";
}

@end
