/*
 * Project:     Adium Rendezvous Plugin
 * File:        AWRendezvousPlugin.m
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004 Andrew Wellington.
 * All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AWRendezvousAccount.h"
#import "AWRendezvousPlugin.h"

@implementation AWRendezvousPlugin

- (void)installPlugin
{
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:[self identifier]
                                                      description:[self description]
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[[NSCharacterSet illegalCharacterSet] invertedSet]
						ignoredCharacters:[NSCharacterSet characterSetWithCharactersInString:@""]
						    allowedLength:999] retain];

    //Register this service
    [[adium accountController] registerService:self];
}


//Return a new account with the specified properties
- (id)accountWithUID:(NSString *)inUID objectID:(int)inObjectID
{
    return([[[AWRendezvousAccount alloc] initWithUID:inUID service:self objectID:inObjectID] autorelease]);
}

// Return a view for the connection window
- (AIAccountViewController *)accountView{
    return(nil);
}

// Return a Plugin-specific ID and description
- (NSString *)identifier
{
    return(RENDEZVOUS_SERVICE_IDENTIFIER);
}
- (NSString *)description
{
    return(@"Rendezvous");
}

// Return an ID, description, and image for handles owned by accounts of this type
- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}

@end

