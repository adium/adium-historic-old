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

@interface AIListObject (PRIVATE)
- (NSMutableArray *)_recursivePreferencesForKey:(NSString *)inKey group:(NSString *)groupName;
@end

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
	delayedStatusTimers = nil;
	
	visible = YES;
    statusDictionary = [[NSMutableDictionary alloc] init];
    changedStatusKeys = [[NSMutableArray alloc] init];
	
    return(self);
}

- (void)dealloc
{
	NSEnumerator	*enumerator;
	NSTimer			*timer;

	//Invalidate any outstanding delayed status changes
	enumerator = [delayedStatusTimers objectEnumerator];
	while(timer = [enumerator nextObject]){
		[timer invalidate];
	}
	[delayedStatusTimers release];
	
	//
    [displayDictionary release];
    [statusDictionary release];
    [serviceID release];

    [super dealloc];
}


//Identification -------------------------------------------------------------------------------------------------------
#pragma mark Identification
//Unique identification string for this object
- (NSString *)UID
{
    return(UID);
}

//Identification string for the service owning this contact
- (NSString *)serviceID
{
    return(serviceID);
}

//Super unique ID string, combining both UID and service ID
- (NSString *)UIDAndServiceID
{
    if(serviceID){
        return([NSString stringWithFormat:@"%@.%@",serviceID,UID]);
    }else{
        return(UID);
    }
}


//Visibility -----------------------------------------------------------------------------------------------------------
#pragma mark Visibility
//Toggle visibility of this object
- (void)setVisible:(BOOL)inVisible
{	
	if(visible != inVisible){
		visible = inVisible;

		//Let our containing group know about the visibility change
		[containingGroup visibilityOfContainedObject:self changedTo:inVisible];
	}
}

//Return current visibility of this object
- (BOOL)isVisible
{
	return(visible);
}


//Grouping / Ownership -------------------------------------------------------------------------------------------------
#pragma mark Grouping / Ownership
//Return the local group this object is in (will be nil for the root object)
- (AIListGroup *)containingGroup
{
    return(containingGroup);
}

//Set the local grouping for this object (PRIVATE: These are for AIListGroup ONLY)
- (void)setContainingGroup:(AIListGroup *)inGroup
{
	containingGroup = inGroup;
}

//Returns our desired placement within a group
- (float)orderIndex
{
	return(orderIndex);
}

//Alter the placement of this object in a group (PRIVATE: These are for AIListGroup ONLY)
- (void)setOrderIndex:(float)inIndex
{
	orderIndex = inIndex;
}


//Dynamic Status and Display -------------------------------------------------------------------------------------------
#pragma mark Dynamic Status and Display
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

//Quickly set a status key for this object
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify
{
	if(key){
		if(value){
			[statusDictionary setObject:value forKey:key];
		}else{
			[statusDictionary removeObjectForKey:key];
		}
		if(!changedStatusKeys) changedStatusKeys = [[NSMutableArray alloc] init];
		[changedStatusKeys addObject:key];
	}
    
    if(notify && [changedStatusKeys count]){
		[[adium contactController] listObjectStatusChanged:self
										modifiedStatusKeys:changedStatusKeys
													silent:NO];
		[changedStatusKeys release]; changedStatusKeys = nil;
    }
}

//Perform a status change after a short delay
- (void)setStatusObject:(id)value forKey:(NSString *)key afterDelay:(NSTimeInterval)delay
{
	if(!delayedStatusTimers) delayedStatusTimers = [[NSMutableArray alloc] init];
	NSTimer		*timer = [NSTimer scheduledTimerWithTimeInterval:delay
														  target:self
														selector:@selector(_applyDelayedStatus:)
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															key, @"Key",
															value, @"Value",
															nil]
														 repeats:NO];
	[delayedStatusTimers addObject:timer];
}
- (void)_applyDelayedStatus:(NSTimer *)inTimer
{
	NSDictionary	*infoDict = [inTimer userInfo];
	
	[self setStatusObject:[infoDict objectForKey:@"Value"]
				   forKey:[infoDict objectForKey:@"Key"]
				   notify:YES];
	[delayedStatusTimers removeObject:inTimer];
	if([delayedStatusTimers count] == 0){
		[delayedStatusTimers release]; delayedStatusTimers = nil;
	}
}

//Nofity of any queued status changes
- (void)notifyOfChangedStatusSilently:(BOOL)silent
{
    if([changedStatusKeys count]){
		//Clear changedStatusKeys incase this status change invokes another, and we re-enter this code
		NSArray	*keys = changedStatusKeys;
		changedStatusKeys = nil;
		
		//
		[[adium contactController] listObjectStatusChanged:self
										modifiedStatusKeys:keys
													silent:silent];
		[keys release];
    }
}

//Quickly retrieve a status key for this object
- (id)statusObjectForKey:(NSString *)key
{
    return([statusDictionary objectForKey:key]);
}

//Access to the status array for this object
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [[[AIMutableOwnerArray alloc] init] autorelease];

	[array setObject:[statusDictionary objectForKey:inKey] withOwner:self];

    return(array);
}


//Object specific preferences ------------------------------------------------------------------------------------------
#pragma mark Object specific preferences
//Set a preference value
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName
{   
	NSMutableDictionary	*prefDict = [[adium preferenceController] cachedObjectPrefsForKey:[self UIDAndServiceID]
																					 path:[self pathToPreferences]];

    //Set the new value
    if(value != nil){
		if(!prefDict) prefDict = [[NSMutableDictionary alloc] init];
		[prefDict setObject:value forKey:inKey];
    }else{
        [prefDict removeObjectForKey:inKey];
    }
    
    //Save
	[[adium preferenceController] setCachedObjectPrefs:prefDict
												forKey:[self UIDAndServiceID]
												  path:[self pathToPreferences]];
    
    //Broadcast a preference changed notification
    [[adium notificationCenter] postNotificationName:Preference_GroupChanged
											  object:self
											userInfo:[NSDictionary dictionaryWithObjectsAndKeys:groupName,@"Group",inKey,@"Key",nil]];
}

//Retrieve a preference value (with the option of ignoring inherited values)
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore
{
	if(!ignore) return([self preferenceForKey:inKey group:groupName]);
	
	//Return our value for the preference only
	NSMutableDictionary	*prefDict = [[adium preferenceController] cachedObjectPrefsForKey:[self UIDAndServiceID]
																					 path:[self pathToPreferences]];
	return([prefDict objectForKey:inKey]);
}

//Retrieve a preference value
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName
{
    id					value = nil;
	NSMutableDictionary	*prefDict = [[adium preferenceController] cachedObjectPrefsForKey:[self UIDAndServiceID]
																					 path:[self pathToPreferences]];
    
    //Get our value for the preference
    value = [prefDict objectForKey:inKey];
    
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

//
- (NSArray *)allPreferencesForKey:(NSString *)inKey group:(NSString *)groupName
{
    NSMutableArray *returnArray = [self _recursivePreferencesForKey:inKey group:groupName];
    id      rootValue = [[adium preferenceController] preferenceForKey:inKey group:groupName];
    if (rootValue){
        if (returnArray){
            return [returnArray addObject:rootValue];
        }else{
            return [NSArray arrayWithObject:rootValue];
        }
    }
    
    return returnArray;
}

- (NSMutableArray *)_recursivePreferencesForKey:(NSString *)inKey group:(NSString *)groupName
{
    id					value = nil;
    NSMutableArray  	*returnArray = [NSMutableArray arrayWithCapacity:1];
	NSMutableDictionary	*prefDict = [[adium preferenceController] cachedObjectPrefsForKey:[self UIDAndServiceID]
																					 path:[self pathToPreferences]];
    
    //Get our value for the preference
	if(value = [prefDict objectForKey:inKey]){
		[returnArray addObject:value];
	}
    
    //so long as we aren't the root group, add our containingGroups' preferences
	if(containingGroup){
		[returnArray addObjectsFromArray:[containingGroup _recursivePreferencesForKey:inKey group:groupName]];
	}
    
    return returnArray;
}

//Path for storing our reference file
- (NSString *)pathToPreferences
{
    return(OBJECT_PREFS_PATH);
}


//Display Name Convenience Methods -------------------------------------------------------------------------------------
#pragma mark Display Name Convenience Methods
/*
 A list object basically has 4 different variations of display.

 - UID, the base UID of the contact "aiser123"
 - ServerDisplayName, formating or alteration of the UID provided by the account code "AIser 123"
 - DisplayName, short formatted name provided by plugins "Adam Iser"
 - LongDisplayName, long formatted name provided by plugins "Adam Iser (AIser 123)"

 A value will always be returned by these methods, so if there is no long display name present it will fall back to
 display name, serverDisplayName, and finally UID (which is guaranteed to be present).  Use whichever one seems best
 suited for what is being displayed.
 */

//Server display name, specified by server
- (NSString *)serverDisplayName
{
    AIMutableOwnerArray	*serverDisplayName;
    NSString			*outName;

    serverDisplayName = [self statusArrayForKey:@"Display Name"];
    if(serverDisplayName != nil && [serverDisplayName count] != 0){
        outName = [serverDisplayName objectAtIndex:0];
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
