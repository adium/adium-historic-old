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
#import "AIAccount.h"
#import "AIAdium.h"

@interface AIAccount (PRIVATE)
@end

@implementation AIAccount

//-------------------
//  Public Methods
//-----------------------
//Init the connection
- (id)initWithProperties:(NSDictionary *)inProperties service:(id <AIServiceController>)inService owner:(id)inOwner
{
    [super init];

    NSParameterAssert(inProperties != nil);

    //Retain our owner
    owner = [inOwner retain];
    service = [inService retain];

    //Retain the properties dictionary
    propertiesDict = [inProperties mutableCopy];

    //Load the account's status properties
    statusDict = [[propertiesDict objectForKey:@"Status"] mutableCopy];
    if(!statusDict) statusDict = [[NSMutableDictionary alloc] init];
    [propertiesDict setObject:statusDict forKey:@"Status"];

    //Init the account
    [self initAccount];

    return(self);
}

//Return the service that spawned this account
- (id <AIServiceController>)service
{
    return(service);
}

//Return the properties dictionary for this connection
- (NSMutableDictionary *)properties
{
    return(propertiesDict);
}

//Set a status value
- (void)setStatusObject:(id)inValue forKey:(NSString *)key
{
    [statusDict setObject:inValue forKey:key];
}

//Retrieve a status value
- (id)statusObjectForKey:(NSString *)key
{
    return([statusDict objectForKey:key]);
}


//Dealloc
- (void)dealloc
{
    [propertiesDict release]; propertiesDict = nil;
    [owner release];
    [service release];

    [super dealloc];
}

//The display name for this account
#warning- (NSString *)displayName
/*{
    NSString	*displayName;

    displayName = [[self statusArrayForKey:@"Display Name"] objectWithOwner:self];
    if(displayName != nil && [displayName length] != 0){
        return(displayName);
    }else{
        return(UID);
    }
}*/

//Functions for subclasses to override
- (void)initAccount{};
- (NSView *)accountView{return(nil);};
- (NSString *)accountID{return(nil);}; 		//Specific to THIS account plugin, and the user's account name
- (NSString *)UID{return(nil);};		//The user's account name
- (NSString *)serviceID{return(nil);};		//The service ID (shared by any account code accessing this service)
- (NSString *)UIDAndServiceID{return(nil);}; 	//ServiceID.UID
- (NSString *)accountDescription{return(nil);};
- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue{};
- (NSArray *)supportedStatusKeys{return([NSArray array]);}

@end
