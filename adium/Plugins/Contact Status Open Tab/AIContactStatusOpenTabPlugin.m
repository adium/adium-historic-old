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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIContactStatusOpenTabPlugin.h"

@implementation AIContactStatusOpenTabPlugin

- (void)installPlugin
{
    [[owner notificationCenter] addObserver:self selector:@selector(initiateMessage:) name:Interface_InitiateMessage object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(didRecieveContent:) name:Content_DidReceiveContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(closeMessage:) name:Interface_CloseMessage object:nil];
}

- (void)initiateMessage:(NSNotification *)notification
{
    AIListObject	*listObject = [[notification userInfo] objectForKey:@"To"];

    [self updateOpenTabStatusOnListObject:listObject withStatus:YES];
}

- (void)didRecieveContent:(NSNotification *)notification
{
    AIChat		*chat = [notification object];
    AIListObject	*listObject = [chat object];

    [self updateOpenTabStatusOnListObject:listObject withStatus:YES];
}

- (void)closeMessage:(NSNotification *)notification
{
    AIChat		*chat = [notification object];
    AIListObject	*listObject = [chat object];

    [self updateOpenTabStatusOnListObject:listObject withStatus:NO];
}

- (void)updateOpenTabStatusOnListObject:(AIListObject *)inObject withStatus:(BOOL)inStatus
{
    [[inObject statusArrayForKey:@"Open Tab"] setObject:[NSNumber numberWithBool:inStatus] withOwner:self];
    [[owner contactController] listObjectStatusChanged:inObject modifiedStatusKeys:[NSArray arrayWithObject:@"Open Tab"] delayed:NO silent:NO];
}

@end