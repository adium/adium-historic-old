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

#import <AIUtilities/AIUtilities.h>
#import "AIContactHandle.h"
#import "AIAccount.h"
#import "AIServiceType.h"

@interface AIContactHandle (PRIVATE)
- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID;
@end

@implementation AIContactHandle

//Creates and returns a new contact handle
+ (id)handleWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
    return([[[self alloc] initWithServiceID:inServiceID UID:inUID] autorelease]);
}

//Handle service, UID, and display name
- (NSString *)serviceID
{
    return(serviceID);
}

- (NSString *)UID
{
    return(UID);
}

- (NSString *)displayName
{
    AIMutableOwnerArray	*displayName;
    NSString		*outName;
    
    //'Alias' Dislay Name
    displayName = [self displayArrayForKey:@"Display Name"];
    if(displayName != nil && [displayName count] != 0){
        outName = [displayName objectAtIndex:0];

    }else{ //Server Dislay Name
        displayName = [self statusArrayForKey:@"Display Name"];
        if(displayName != nil && [displayName count] != 0){
            outName = [displayName objectAtIndex:0];

        }else{//UID
            outName = UID;

	}
    }
    
    return(outName);
}

- (void)setUID:(NSString *)inUID
{
    [UID release]; UID = nil;
    UID = [inUID retain];
}

//Returns the requested status array for this object
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [statusDictionary objectForKey:inKey];
    
    if(!array){
        array = [[AIMutableOwnerArray alloc] init];
        [statusDictionary setObject:array forKey:inKey];
        [array release];
    }

    return(array);
}

//Compares our display name (and other factors) to another handle
//If we come first, result is -1.  If object comes first, the result is 1.
- (NSComparisonResult)compare:(AIContactObject *)object
{
    NSComparisonResult 	result;
    BOOL		weAreInvisible = NO;
    BOOL		theyAreInvisible = NO;
    
    if([[self displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1]){
        weAreInvisible = YES;
    }
    if([object isKindOfClass:[AIContactHandle class]] && [[(AIContactHandle *)object displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1]){
        theyAreInvisible = YES;
    }
    
    if(weAreInvisible && !theyAreInvisible){
        result = 1;
    }else if(!weAreInvisible && theyAreInvisible){
        result = -1;
    }else{
        result = [[self displayName] caseInsensitiveCompare:[object displayName]];
    }

    return(result);
}

//Return our array of content objects
- (NSArray *)contentObjectArray
{
    return(contentObjectArray);
}

//Add a message object to this handle
- (void)addContentObject:(id <AIContentObject>)inObject
{
    //Add the object
    [contentObjectArray insertObject:inObject atIndex:0];

    //Keep the array under X number of objects
    
}

// Private ----------------------------------------------------------------------------------
//Init
- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
    [super init];

    //Retain our information
    serviceID = [inServiceID retain];
    UID = [inUID retain];
   
    //init
    statusDictionary = [[NSMutableDictionary alloc] init];
    contentObjectArray = [[NSMutableArray alloc] init];

    return(self);
}

- (void)dealloc
{
    [statusDictionary release];
    [contentObjectArray release];
    [UID release];
    [serviceID release];

    [super dealloc];
}



@end
