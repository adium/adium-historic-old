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

#import "AIEditorListHandle.h"
#import "AIEditorListGroup.h"
#import <Adium/Adium.h>


@implementation AIEditorListHandle

- (id)initWithUID:(NSString *)inUID temporary:(BOOL)inTemporary
{
    [super init];

    UID = [inUID retain];
    temporary = inTemporary;
    containingGroup = nil;
    orderIndex = -1;
    
    return(self);
}

- (void)dealloc
{
    [UID release];
    [containingGroup release];
    
    [super dealloc];
}


//UID
- (NSString *)UID
{
    return(UID);
}
- (void)setUID:(NSString *)inUID
{
    [UID release];
    UID = [inUID retain];
}


//Index
- (float)orderIndex
{
    return(orderIndex);
}
- (void)setOrderIndex:(float)inIndex
{
    orderIndex = inIndex;
}


//Temporary
- (BOOL)temporary
{
    return(temporary);
}
- (void)setTemporary:(BOOL)inTemporary
{
    temporary = inTemporary;
}


//Containing group
- (void)setContainingGroup:(AIEditorListGroup *)inGroup
{
    [containingGroup release];
    containingGroup = [inGroup retain];
}
- (AIEditorListGroup *)containingGroup
{
    return(containingGroup);
}

@end
