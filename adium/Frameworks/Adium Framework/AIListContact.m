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

#import "AIListContact.h"
#import "AIHandle.h"

#define CONTENT_OBJECT_SCROLLBACK	5  //Number of content object that say in the scrollback

@implementation AIListContact

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
    [super initWithUID:inUID serviceID:inServiceID];
    
	remoteGroups = [[AIMutableOwnerArray alloc] init];
    
    return(self);
}

- (void)dealloc
{
    [remoteGroups release];
    
    [super dealloc];
}

//Set the desired group for an account that owns this contact
//Pass nil to indicate an account no longer owns this object
- (void)setRemoteGroupName:(NSString *)groupName forAccount:(AIAccount *)inAccount
{
	NSString	*oldGroup = [remoteGroups objectWithOwner:inAccount];
	
	//Change it here
	[remoteGroups setObject:groupName withOwner:inAccount];
	
	//Tell core it changed
	[[adium contactController] listObjectRemoteGroupingChanged:self oldGroupName:oldGroup];
}

- (AIMutableOwnerArray *)remoteGroupArray
{
	return(remoteGroups);
}

@end
