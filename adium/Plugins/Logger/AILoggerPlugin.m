/*-------------------------------------------------------------------------------------------------------*\
| AILoggerPlugin 1.0 for Adium                                                                            |
| AILoggerPlugin: Copyright (C) 2002 Adam Atlas. <adam@atommic.com> <http://www.atommic.com>              |
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
#import "AILoggerPlugin.h"

#define PATH_LOGS	@"/Logs"

@interface AILoggerPlugin (PRIVATE)
- (void)_addMessage:(NSString *)message toLog:(NSString *)logName source:(NSString *)sourceName date:(NSDate *)date;
@end

@implementation AILoggerPlugin

- (void)installPlugin
{
    NSMenuItem	*logViewerMenuItem;

    //Observe content sending and receiving
    [[owner notificationCenter] addObserver:self selector:@selector(adiumSentContent:) name:Content_DidSendContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(adiumReceivedContent:) name:Content_DidReceiveContent object:nil];

    //Install the log viewer menu item
    logViewerMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Log Viewer" target:self action:@selector(showLogViewer:) keyEquivalent:@"L"] autorelease];
    [[owner menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxilary];

    //Create a logs directory
    logBasePath = [[[[[owner loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath] retain];
    [AIFileUtilities createDirectory:logBasePath];
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
            [self _addMessage:[[content message] string]
                        toLog:[destination UIDAndServiceID]
                       source:[source UIDAndServiceID]
                         date:[content date]];
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

        //Destination are valid (handle)
        if([source isKindOfClass:[AIHandle class]]){
            //Log the message
            [self _addMessage:[[content message] string]
                        toLog:[source UIDAndServiceID]
                       source:[source UIDAndServiceID]
                         date:[content date]];
        }
    }
}

//Show the log viewer window
- (void)showLogViewer:(id)sender
{
    
}

//Add a message to the specified log file
- (void)_addMessage:(NSString *)message toLog:(NSString *)logName source:(NSString *)sourceName date:(NSDate *)date
{
    NSString	*logPath;
    NSString	*logFileName;
    NSString	*logString;
    FILE	*file;

    //Create path to log file
    logPath = [logBasePath stringByAppendingPathComponent:logName];
    logFileName = [NSString stringWithFormat:@"%@ (%@).adiumLog", logName, [date descriptionWithCalendarFormat:@"%Y|%m|%d" timeZone:nil locale:nil]];

    //Create a directory for this log (if one doesn't exist)
    [AIFileUtilities createDirectory:logPath];

    //Format the log string
    logString = [NSString stringWithFormat:@"(%@)%@:%@\n",[[NSDate date] descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil], sourceName, message];

    //Append the new content (We use fopen/fputs/fclose for max speed)
    file = fopen([[logPath stringByAppendingPathComponent:logFileName] cString], "a");
    fputs([logString cString], file);
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
