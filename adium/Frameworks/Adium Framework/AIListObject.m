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

#import "AIListObject.h"
#import "AIListGroup.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIListObject

//Init
- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
    [super init];

    displayDictionary = [[NSMutableDictionary alloc] init];
    containingGroup = nil;
    UID = [inUID retain];
    serviceID = [inServiceID retain];
    orderIndex = -1;
    statusDictionary = [[NSMutableDictionary alloc] init];

    return(self);
}

- (void)dealloc
{
    [displayDictionary release];
    [containingGroup release];
    [statusDictionary release];
    [serviceID release];

    [super dealloc];
}


//Identification --------------------------------------------------------------------------------
//UID, identification of this object
- (NSString *)UID
{
    return(UID);
}

//
- (NSString *)serviceID
{
    return(serviceID);
}

//
- (NSString *)UIDAndServiceID //ServiceID.UID
{
    if(serviceID){
        return([NSString stringWithFormat:@"%@.%@",serviceID,UID]);
    }else{
        return(UID);
    }
}

//Manual Ordering
- (void)setOrderIndex:(float)inIndex
{
    orderIndex = inIndex;
}
- (float)orderIndex{
    return(orderIndex);
}


// Display --------------------------------------------------------------------------------
/*
 A list object basically has 4 different variations of display.

 - UID, the base UID of the contact "aiser123"
 - ServerDisplayName, formating or alteration of the UID provided by the account code "AIser 123"
 - DisplayName, short formatted name provided by plugins "Adam Iser"
 - LongDisplayName, long formatted name provided by plugins "Adam Iser (AIser 123)"

 A value will always be returned by these methods, so if there is no long display name present it will fall back to display name, serverDisplayName, and finally UID (which is guaranteed to be present).  Use whichever one seems best suited for what is being displayed.
 */

//Server display name, specified by server
- (NSString *)serverDisplayName
{
    AIMutableOwnerArray	*displayName;
    NSString		*outName;

    displayName = [self statusArrayForKey:@"Display Name"];
    if(displayName != nil && [displayName count] != 0){
        outName = [displayName objectAtIndex:0];
    }else{
        outName = UID;
    }
    
    return(outName);
}

//Display name, influenced by plugins
- (NSString *)displayName
{
    AIMutableOwnerArray	*displayName;
    NSString		*outName;
    
    displayName = [self displayArrayForKey:@"Display Name"];
    if(displayName != nil && [displayName count] != 0){
        outName = [displayName objectAtIndex:0];
    }else{
        outName = [self serverDisplayName];
    }

    return(outName);
}

//Long display name, influenced by plugins
- (NSString *)longDisplayName
{
    AIMutableOwnerArray * longNameArray;
    NSString *outName;

    longNameArray = [self displayArrayForKey:@"Long Display Name"];
    if (longNameArray && [longNameArray count]){
        outName = [longNameArray objectAtIndex:0];
    } else{
        outName = [self displayName];
    }
    return (outName);
}

//Access to the display arrays for this object
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [displayDictionary objectForKey:inKey];

    if(!array){
        //	NSLog(@"array for key:%@ not found and created", inKey);
        array = [[AIMutableOwnerArray alloc] init];
        [displayDictionary setObject:array forKey:inKey];
        [array release];
    }

    return(array);
}


//Nesting --------------------------------------------------------------------------------
//Returns the group this object is in (will be nil for the root object)
- (AIListGroup *)containingGroup
{
    return(containingGroup);
}

//Sets the group this object is in
- (void)setContainingGroup:(AIListGroup *)inGroup
{
    if(inGroup == nil){
        [containingGroup release]; containingGroup = nil;

    }else{
        containingGroup = [inGroup retain];
    }
}


//Status --------------------------------------------------------------------------------
//Returns the requested status array for this object
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [statusDictionary objectForKey:inKey];

    if(!array){
//	NSLog(@"array for key:%@ not found and created", inKey);
        array = [[AIMutableOwnerArray alloc] init];
        [statusDictionary setObject:array forKey:inKey];
        [array release];
    }

    return(array);
}


@end
