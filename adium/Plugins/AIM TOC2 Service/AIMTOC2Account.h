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

@class AISocket, AIGroup, AIMTOC2AccountViewController;

@interface AIMTOC2Account : AIAccount <AIAccount_Content, AIAccount_GroupedContacts> {
    
    AIMTOC2AccountViewController	*accountViewController;

    AISocket 		*socket;		// The connection socket
    int			connectionPhase;	// Offline/Connecting/Online/Disconnecting

    NSString		*screenName;		// Current signed on screenName
    NSString		*password;		// Current signed on password

    NSMutableArray	*outQue;		// Que of outgoing packets
    NSMutableDictionary	*groupDict;		// Remembers the group each handle is in

    NSMutableArray	*idleHandleArray;
    NSTimer		*idleHandleTimer;
    
    unsigned short	localSequence;		// Current local packet sequence
    unsigned short	remoteSequence;		// Current remote packet sequence

    NSTimer		*updateTimer;		// Timer that drives the main client<->server code
    
    NSMutableDictionary	*deleteDict;		// A dictionary of handles waiting to be deleted
    NSMutableDictionary	*addDict;		// A dictionary of handles waiting to be added
    NSTimer		*messageDelayTimer;	// Timer that drives the delayed handle updating
    
    NSDictionary	*preferencesDict;	// Our preferences dictionary

    NSTimer		*pingTimer;
    NSTimeInterval	pingInterval;
    NSDate		*firstPing;
}

- (void)initAccount;
- (NSString *)accountID;
- (NSString *)accountDescription;
- (void)dealloc;

@end
