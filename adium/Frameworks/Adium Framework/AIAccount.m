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
    
    //Set the account status to offline (or NA if status does not apply)
    if([self conformsToProtocol:@protocol(AIAccount_Status)]){
        status = STATUS_OFFLINE;
    }else{
        status = STATUS_NA;
    }

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

//Dealloc
- (void)dealloc
{
    [propertiesDict release]; propertiesDict = nil;
    [owner release];
    [service release];

    [super dealloc];
}

//Functions for subclasses to override
- (void)initAccount{};
- (NSView *)accountView{return(nil);};
- (NSString *)accountID{return(nil);};
- (NSString *)accountDescription{return(nil);};
- (BOOL)sendMessageObject:(AIMessageObject *)object toHandle:(AIContactHandle *)inHandle{return(NO);};

@end
