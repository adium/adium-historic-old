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
#import "InstantMessageFramework.h"

@interface AIMiChatAccount : AIAccount <AIAccount_Content, AIAccount_Handles, FZServiceListener, FZDaemonListener> {

    NSConnection	*connection;
    id <FZDaemon>	FZDaemon;
    id <FZService>	AIMService;

    NSString		*screenName;

    NSMutableDictionary	*handleDict;

    NSMutableArray	*idleHandleArray;
    NSTimer		*idleHandleTimer;

    
    BOOL		isOnline;

    BOOL		processingSignOnUpdates;
    BOOL		waitingForFirstUpdate;
    int			numberOfSignOnUpdates;
}

@end
