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

#import "AIAccount.h"

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

    //Retain our owner
    owner = [inOwner retain];
    service = [inService retain];

    //Load the account's default properties, then apply the passed properties (overwriting any defaults)
    if(!(propertiesDict = [[self defaultProperties] mutableCopy])){
        propertiesDict = [[NSMutableDictionary alloc] init];
    }
    [propertiesDict addEntriesFromDictionary:inProperties];
    
    //Clear the online state.  'Auto-Connect' values are used, not the previous online state.
    [propertiesDict setObject:[NSNumber numberWithInt:STATUS_OFFLINE] forKey:@"Status"];
    [propertiesDict setObject:[NSNumber numberWithBool:NO] forKey:@"Online"];

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
- (NSDictionary *)properties
{
    return(propertiesDict);
}

//Return the default properties for this account
- (NSDictionary *)defaultProperties
{
    return(nil);
}

//Set a status value
- (void)setProperty:(id)inValue forKey:(NSString *)key
{
    [propertiesDict setObject:inValue forKey:key];
}

//Retrieve a status value
- (id)propertyForKey:(NSString *)key
{
    return([propertiesDict objectForKey:key]);
}

//Dealloc
- (void)dealloc
{
    [propertiesDict release]; propertiesDict = nil;
    [owner release];
    [service release];

    [super dealloc];
}

//Display name (Convenience)
- (NSString *)displayName
{
    NSString	*name = [[owner accountController] propertyForKey:@"FullName" account:self];
    if(!name || [name length] == 0) name = [self accountDescription];
    return(name);
}

//Server Display name (Convenience)
- (NSString *)serverDisplayName
{
    return([self displayName]);
}

- (NSString *)UIDAndServiceID {
    return [NSString stringWithFormat:@"%@.%@", [self serviceID], [self UID]];
}

//Functions for subclasses to override
- (void)initAccount{};
- (NSView *)accountView{return(nil);};
- (NSString *)accountID{return(nil);}; 		//Specific to THIS account plugin, and the user's account name
- (NSString *)UID{return(nil);};		//The user's account name
- (NSString *)serviceID{return(nil);};		//The service ID (shared by any account code accessing this service)
- (NSString *)accountDescription{return(nil);};
- (void)statusForKey:(NSString *)key willChangeTo:(id)inValue{};
- (NSArray *)supportedPropertyKeys{return([NSArray array]);}

@end
