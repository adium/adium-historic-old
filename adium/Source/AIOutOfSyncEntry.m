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

#import "AIOutOfSyncEntry.h"
#import <Adium/Adium.h>

@interface AIOutOfSyncEntry (PRIVATE)
- (id)initWithHandle:(AIContactHandle *)inHandle serverGroup:(AIContactGroup *)inServerGroup;
@end

@implementation AIOutOfSyncEntry

+ (id)entryWithHandle:(AIContactHandle *)inHandle serverGroup:(AIContactGroup *)inServerGroup
{
    return([[[self alloc] initWithHandle:inHandle serverGroup:inServerGroup] autorelease]);
}

- (id)initWithHandle:(AIContactHandle *)inHandle serverGroup:(AIContactGroup *)inServerGroup
{
    [super init];
    
    handle = [inHandle retain];
    serverGroup = [inServerGroup retain];
    
    return(self);
}

- (AIContactHandle *)handle
{
    return(handle);
}

- (AIContactGroup *)serverGroup
{
    return(serverGroup);
}

- (void)dealloc
{
    [handle release]; handle = nil;
    [serverGroup release]; serverGroup = nil;

    [super dealloc];
}

@end
