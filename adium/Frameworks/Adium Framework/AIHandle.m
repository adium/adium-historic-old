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

#import "AIHandle.h"

@implementation AIHandle

//Init
+ (id)handleWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount
{
    return([[[self alloc] initWithServiceID:inServiceID UID:inUID serverGroup:inGroup temporary:inTemporary forAccount:inAccount] autorelease]);    
}

- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount
{
    [super init];

    //Retain our information
    UID = [inUID retain];
    serviceID = [inServiceID retain];

    UIDAndServiceID = [[NSString stringWithFormat:@"%@.%@",serviceID,UID] retain];
    
    serverGroup = [inGroup retain];
    account = [inAccount retain];
    temporary = inTemporary;
    
    containingContact = nil;

    statusDictionary = [[NSMutableDictionary alloc] init];
    
    return(self);
}

- (void)dealloc
{
    [UID release];
    [serviceID release];
    [serverGroup release];
    [account release];
    [UIDAndServiceID release];
    [statusDictionary release];

    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    AIHandle *newItem = [[AIHandle alloc] 
        initWithServiceID:[self serviceID] 
        UID:[self UID]
        serverGroup:[self serverGroup]
        temporary:[self temporary]
        forAccount:[self account]];
    
    [newItem setContainingContact:[self containingContact]];
    
    [[newItem statusDictionary] setDictionary:[self statusDictionary]];
    
    return newItem;
}

//Identifying information
- (NSString *)UID
{
    return(UID);
}
- (NSString *)serviceID
{
    return(serviceID);
}
- (NSString *)UIDAndServiceID //ServiceID.UID
{
    return(UIDAndServiceID);
}
- (NSString *)serverGroup
{
    return(serverGroup);
}
- (void)setServerGroup:(NSString *)inServerGroup
{
    [serverGroup release];
    serverGroup = [inServerGroup retain];
}
- (BOOL)temporary
{
    return(temporary);
}

//Ownership
- (AIAccount *)account
{
    return(account);
}

- (void)setContainingContact:(AIListContact *)inContact
{
    [containingContact release]; containingContact = nil;

    if(inContact != nil){
        containingContact = [inContact retain];
    }
}
- (AIListContact *)containingContact
{
    return(containingContact);
}


//Status
- (NSMutableDictionary *)statusDictionary
{
    return(statusDictionary);
}

@end
