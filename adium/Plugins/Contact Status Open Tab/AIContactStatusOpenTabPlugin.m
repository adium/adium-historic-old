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
    AIListContact	*contact = (AIListContact *)[[notification userInfo] objectForKey:@"To"];
 
    [self applyOpenTabStatusOnContact:contact];
}

- (void)didRecieveContent:(NSNotification *)notification
{
    AIListContact	*contact = (AIListContact *)[notification object];

    [self applyOpenTabStatusOnContact:contact];
}

- (void)closeMessage:(NSNotification *)notification
{
    AIListContact	*contact = (AIListContact *)[notification object];

    [self clearOpenTabStatusOnContact:contact];
}

- (void)applyOpenTabStatusOnContact:(AIListContact *)inContact
{
    [[inContact statusArrayForKey:@"Open Tab"] setObject:[NSNumber numberWithInt:YES] withOwner:self];
    [[owner contactController] contactStatusChanged:inContact modifiedStatusKeys:[NSArray arrayWithObject:@"Open Tab"]];
}

- (void)clearOpenTabStatusOnContact:(AIListContact *)inContact
{
    [[inContact statusArrayForKey:@"Open Tab"] setObject:[NSNumber numberWithInt:NO] withOwner:self];
    [[owner contactController] contactStatusChanged:inContact modifiedStatusKeys:[NSArray arrayWithObject:@"Open Tab"]];
}

@end