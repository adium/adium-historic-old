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
#import <Adium/Adium.h>


@implementation AIEditorListHandle

- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID temporary:(BOOL)inTemporary
{
    [super initWithUID:inUID temporary:inTemporary];

    serviceID = [inServiceID retain];
    
    return(self);
}

- (void)dealloc
{
    [serviceID release];
    
    [super dealloc];
}

- (NSString *)serviceID
{
    return(serviceID);
}

- (void)setServiceID:(NSString *)inServiceID
{
    [serviceID release];
    serviceID = [inServiceID retain];
}


@end
