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

    //
    prefDict = [[NSMutableDictionary dictionaryWithContentsOfFile:[[[adium loginController] userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH]] retain];
    
    return(self);
}

- (void)dealloc
{
    [displayDictionary release];
    [containingGroup release];
    [statusDictionary release];
    [serviceID release];
    [prefDict release];

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


//Dynamic Status and Display -------------------------------------------------------------------
//Access to the display arrays for this object
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [displayDictionary objectForKey:inKey];

    if(!array){
        array = [[AIMutableOwnerArray alloc] init];
        [displayDictionary setObject:array forKey:inKey];
        [array release];
    }

    return(array);
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


//Object specific preferences -------------------------------------------------------------------
//Set a preference value
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName
{    
    //Set the new value
    if(value != nil){
	if(!prefDict) prefDict = [[NSMutableDictionary alloc] init];
	[prefDict setObject:value forKey:inKey];
    }else{
        [prefDict removeObjectForKey:inKey];
    }
    
    //Save
    [prefDict writeToPath:[[[adium loginController] userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH]
		 withName:[self UIDAndServiceID]];
    
    //Broadcast a preference changed notification
    [[adium notificationCenter] postNotificationName:Preference_GroupChanged object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:groupName,@"Group",inKey,@"Key",nil]];
}

//Retrieve a preference value (with the option of ignoring inherited values)
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore
{
    //If ignore is yes, retrieve a preference value for this list object only, returning nil if no value is present
    if(ignore){
	return([prefDict objectForKey:inKey]);
    }else{
	return([self preferenceForKey:inKey group:groupName]);
    }
}

//Retrieve a preference value
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName
{
    id		value = nil;
    
    //Get our value for the preference
    if(prefDict) value = [prefDict objectForKey:inKey];
    
    //### TEMPORARY (OLD OBJECT PREFERENCE IMPORT CODE) #######
    if(!value && [[adium preferenceController] tempImportOldPreferenceForKey:inKey group:groupName object:self]){
	[prefDict release];
	prefDict = [[NSMutableDictionary dictionaryWithContentsOfFile:[[[adium loginController] userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH]] retain];
	if(prefDict) value = [prefDict objectForKey:inKey];
    }
    //#########################################################
    
    //If we don't have a value
    if(!value){
	if(containingGroup){
	    //return the value of the group that contains us
	    value = [containingGroup preferenceForKey:inKey group:groupName];
	    
	}else{
	    //If we are the root group, return Adium's global preference for this key
	    value = [[adium preferenceController] preferenceForKey:inKey group:groupName];
	}
    }
    
    return(value);
}



// Display Name Convenience Methods -----------------------------------------------------------------------
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


@end
