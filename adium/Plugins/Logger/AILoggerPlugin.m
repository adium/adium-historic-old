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


@implementation AILoggerPlugin

- (void)makeDir:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL folderExists, isDirectory;

    folderExists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];

    if (folderExists && !isDirectory) {
        [fileManager movePath:path toPath:[path stringByAppendingString:@".moved-aside"] handler:nil];
        folderExists = NO;
    }

    if (!folderExists) {
        [fileManager createDirectoryAtPath:path attributes:nil];
    }
}

- (void)installPlugin {
    NSNotificationCenter *notificationCenter = [[owner contentController] contentNotificationCenter];
    NSMenuItem *logViewerMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Log Viewer" action:@selector(showLogViewer) keyEquivalent:@"L"] autorelease];
    NSString *destination = [[[[owner loginController] userDirectory] stringByExpandingTildeInPath] stringByAppendingString:@"/Logs"];

    [notificationCenter addObserver:self selector:@selector(adiumSentContent:) name:@"Content_DidSendContent" object:nil];

    [notificationCenter addObserver:self selector:@selector(adiumReceivedContent:) name:@"Content_DidReceiveContent" object:nil];

    [self makeDir:destination];

    [logViewerMenuItem setTarget:self];
    
    [[owner menuController] addMenuItem:logViewerMenuItem toLocation:LOC_Window_Auxilary];
}

- (void)adiumSentContent:(NSNotification *)notification {
    AIContentMessage *content = [[notification userInfo] objectForKey:@"Object"];
    id sender = [content source];
    id receiver = [content destination];
    NSString *text = [[content message] string];
    NSString *filePath;
    FILE *file;
    NSCalendarDate *theDate = [NSCalendarDate calendarDate];

    NSString *senderName;
    NSString *receiverName;

    NSString *basePath = [[[[owner loginController] userDirectory] stringByExpandingTildeInPath] stringByAppendingString:@"/Logs"];
    NSString *destinationPath;

    char oString[1024];

    if ([sender isKindOfClass:[AIContactHandle class]]) {
        senderName = [sender UID];
    } else {
        senderName = [sender accountDescription];
    }

    if ([receiver isKindOfClass:[AIContactHandle class]]) {
        receiverName = [receiver UID];
    } else {
        receiverName = [receiver accountDescription];
    }

    destinationPath = [basePath stringByAppendingString:[NSString stringWithFormat:@"/%@", receiverName]];
    [self makeDir:destinationPath];

    filePath = [[NSString stringWithFormat:@"%@/%i-%i-%i.log", destinationPath, [theDate monthOfYear], [theDate dayOfMonth], [theDate yearOfCommonEra]] stringByExpandingTildeInPath];

    file = fopen([filePath cString], "a");

    sprintf(oString, "+ (%i:%02i:%02i %s) %s: %s\n", ([theDate hourOfDay] > 12 ? [theDate hourOfDay]-12 : [theDate hourOfDay]), [theDate minuteOfHour], [theDate secondOfMinute], ([theDate hourOfDay] > 12 ? "PM" : "AM"), [senderName cString], [text cString]);

    fputs(oString, file);

    fclose(file);
}

- (void)adiumReceivedContent:(NSNotification *)notification {
    AIContentMessage *content = [[notification userInfo] objectForKey:@"Object"];
    id sender = [content source];
    id receiver = [content destination];
    NSString *text = [[content message] string];
    NSString *filePath;
    FILE *file;
    NSCalendarDate *theDate = [NSCalendarDate calendarDate];

    NSString *senderName;
    NSString *receiverName;

    NSString *basePath = [[[[owner loginController] userDirectory] stringByExpandingTildeInPath] stringByAppendingString:@"/Logs"];
    NSString *destinationPath;

    char oString[1024];

    if ([sender isKindOfClass:[AIContactHandle class]]) {
        senderName = [sender UID];
    } else {
        senderName = [sender accountDescription];
    }

    if ([receiver isKindOfClass:[AIContactHandle class]]) {
        receiverName = [receiver UID];
    } else {
        receiverName = [receiver accountDescription];
    }

    destinationPath = [basePath stringByAppendingString:[NSString stringWithFormat:@"/%@", senderName]];
    [self makeDir:destinationPath];

    filePath = [[NSString stringWithFormat:@"%@/%i-%i-%i.log", destinationPath, [theDate monthOfYear], [theDate dayOfMonth], [theDate yearOfCommonEra]] stringByExpandingTildeInPath];

    file = fopen([filePath cString], "a");

    sprintf(oString, "- (%i:%02i:%02i %s) %s: %s\n", ([theDate hourOfDay] > 12 ? [theDate hourOfDay]-12 : [theDate hourOfDay]), [theDate minuteOfHour], [theDate secondOfMinute], ([theDate hourOfDay] > 12 ? "PM" : "AM"), [senderName cString], [text cString]);

    fputs(oString, file);

    fclose(file);
}

- (void)showLogViewer {
    
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
