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
#import <AIUtilities/AIUtilities.h>

#define CONTENT_OBJECT_SCROLLBACK	5  //Number of content object that say in the scrollback

@implementation AIListContact

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
    [super initWithUID:inUID];
    
    serviceID = [inServiceID retain];
    handleArray = [[NSMutableArray alloc] init];
    statusDictionary = [[NSMutableDictionary alloc] init];
    contentObjectArray = [[NSMutableArray alloc] init];
    
    return(self);
}

- (NSString *)serviceID
{
    return(serviceID);
}

- (NSString *)UIDAndServiceID //ServiceID.UID
{
    return([NSString stringWithFormat:@"%@.%@",serviceID,UID]);
}

- (NSString *)description
{
    return([NSString stringWithFormat:@"%@.%@ (%@)",serviceID,UID,[super description]]);
}


//Contained Handles
- (NSEnumerator *)handleEnumerator
{
    return([handleArray objectEnumerator]);
}

- (void)addHandle:(AIHandle *)inHandle
{
    [inHandle setContainingContact:self];    
    [handleArray addObject:inHandle];
}

- (void)removeHandle:(AIHandle *)inHandle
{
    NSEnumerator	*enumerator;
    AIMutableOwnerArray	*array;
    
    //Remove all the status values this handle applied to us
    enumerator = [[statusDictionary allValues] objectEnumerator];
    while((array = [enumerator nextObject])){
        [array setObject:nil withOwner:inHandle];
    }

    //remove it
    [inHandle setContainingContact:nil];
    [handleArray removeObject:inHandle];
}

- (void)removeAllHandles
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;

    //Remove all handles
    enumerator = [handleArray objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self removeHandle:handle];
    }
}

- (int)numberOfHandles
{
    return([handleArray count]);
}



//Content
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
/*    if([contentObjectArray count] > CONTENT_OBJECT_SCROLLBACK){
        int i;

        NSLog(@"Flush %i",([contentObjectArray count] - CONTENT_OBJECT_SCROLLBACK));
        for(i = 0;i < ([contentObjectArray count] - CONTENT_OBJECT_SCROLLBACK); i++){
            [contentObjectArray removeLastObject];
        }

        //let everyone know we flushed
        //        [[owner notificationCenter] postNotificationName:Content_ContentObjectsChanged object:self userInfo:nil];
    }*/

}


//Status
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

        }else if([handleArray count] != 0){ //UID
            outName = [[handleArray objectAtIndex:0] UID];

        }else{
            outName = UID;

        }
    }

    return(outName);
    //return([NSString stringWithFormat:@"(%0.3f) %@",orderIndex,outName]);
}

@end
