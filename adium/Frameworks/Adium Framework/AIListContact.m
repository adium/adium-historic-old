/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define CONTENT_OBJECT_SCROLLBACK	5  //Number of content object that say in the scrollback

@implementation AIListContact

- (id)initWithUID:(NSString *)inUID accountID:(NSString *)inAccountID serviceID:(NSString *)inServiceID
{
    [super initWithUID:inUID serviceID:inServiceID];
    
	accountID = [inAccountID retain];
	remoteGroupName = nil;
    
    return(self);
}

- (void)dealloc
{
	[accountID release];
    [remoteGroupName release];
    
    [super dealloc];
}

//
- (NSString *)accountID
{
	return(accountID);
}

//Remote Grouping ------------------------------------------------------------------------------------------------------
#pragma mark Remote Grouping
//Set the desired group for this contact.  Pass nil to indicate this object is no longer listed.
- (void)setRemoteGroupName:(NSString *)inName
{
	NSString	*oldGroupName = remoteGroupName;

	if(inName != nil || oldGroupName != nil){ //If both are nil, we can skip this operation
		[oldGroupName retain];

		//Change it here
		remoteGroupName = [inName retain];

		//Tell core it changed
		[[adium contactController] listObjectRemoteGroupingChanged:self];

		[oldGroupName release];
	}
}

- (NSString *)remoteGroupName
{
	return(remoteGroupName);
}

@end
