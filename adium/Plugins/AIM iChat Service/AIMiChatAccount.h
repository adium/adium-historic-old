/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@protocol FZServiceListener <NSObject>
- (oneway void)service:(id)service requestOutgoingFileXfer:(id)file;
- (oneway void)service:(id)service requestIncomingFileXfer:(id)file;
- (oneway void)service:(id)service chat:(id)chat member:(id)member statusChanged:(int)status;
- (oneway void)service:(id)service chat:(id)chat showError:(id)error;
- (oneway void)service:(id)service chat:(id)chat messageReceived:(id)message;
- (oneway void)service:(id)service chat:(id)chat statusChanged:(int)status;
- (oneway void)service:(id)service directIMRequestFrom:(id)from invitation:(id)invitation;
- (oneway void)service:(id)service invitedToChat:(id)chat isChatRoom:(char)isRoom invitation:(id)invitation;
- (oneway void)service:(id)service youAreDesignatedNotifier:(char)notifier;
- (oneway void)service:(id)service buddyPictureChanged:(id)buddy imageData:(id)image;
- (oneway void)service:(id)inService buddyPropertiesChanged:(NSArray *)inProperties;
- (oneway void)service:(id)inService loginStatusChanged:(int)inStatus message:(id)inMessage reason:(int)inReason;
@end

@protocol FZDaemonListener <NSObject>
- (oneway void)openNotesChanged:(id)unknown;
- (oneway void)myStatusChanged:(id)unknown;
@end


@interface AIMiChatAccount : AIAccount <AIAccount_Required, AIAccount_Content, AIAccount_GroupedHandles, AIAccount_Status, FZServiceListener, FZDaemonListener> {

    NSConnection	*connection;
    id			FZDaemon;
    id			AIMService;




    BOOL		queEvents;
    NSMutableArray	*buddyPropertiesQue;
}

@end
