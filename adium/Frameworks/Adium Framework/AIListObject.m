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
    containingGroups = [[NSMutableArray alloc] init];
    UID = [inUID retain];
    serviceID = [inServiceID retain];

	orderIndex = 0;
	orderIndexGroup = nil;
	multipleOrderIndex = nil;
	delayedStatusTimers = nil;
	
	visible = YES;
    statusDictionary = [[NSMutableDictionary alloc] init];
    changedStatusKeys = [[NSMutableArray alloc] init];

    //Load our object specific preferences
    prefDict = [[NSDictionary dictionaryAtPath:[self pathToPreferences]
									  withName:[self UIDAndServiceID] create:NO] mutableCopy];
	
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
    [containingGroups release];
    [statusDictionary release];
    [serviceID release];
    [prefDict release];

    [super dealloc];
}


//Identification --------------------------------------------------------------------------------
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
//Toggle visibility of this object
- (void)setVisible:(BOOL)inVisible
{	
	if(visible != inVisible){
		NSEnumerator	*enumerator = [containingGroups objectEnumerator];
		AIListGroup		*group;
		
		//
		visible = inVisible;

		//Let our containing groups know about the visibility change
		while(group = [enumerator nextObject]){
			[group visibilityOfContainedObject:self changedTo:inVisible];
		}
	}
}

//Return current visibility of this object
- (BOOL)isVisible
{
	return(visible);
}


//Grouping / Ownership ------------------------------------------------------------------------------------------
//Return the local groups this object is in (will be nil for the root object)
- (NSArray *)containingGroups
{
    return(containingGroups);
}

//Returns our desired placement within a group
- (float)orderIndexForGroup:(AIListGroup *)inGroup
{
	if(orderIndexGroup == inGroup){
		return(orderIndex);
	}else if(multipleOrderIndex){
		return([[multipleOrderIndex objectWithOwner:inGroup] floatValue]);
	}else{
		return(0);
	}
}

//Alter the placement of this object in a group (PRIVATE: These are for AIListGroup ONLY)
- (void)setOrderIndex:(float)inIndex forGroup:(AIListGroup *)inGroup
{
	if(inIndex != 0){ //Add
		if((orderIndexGroup == nil && multipleOrderIndex == nil) || orderIndexGroup == inGroup){
			//This is our first grouping, or an update to the existing grouping
			orderIndex = inIndex;
			orderIndexGroup = inGroup;
		}else{
			if(multipleOrderIndex == nil){
				//This is a new group, giving us two groups total
				multipleOrderIndex = [[AIMutableOwnerArray alloc] init];
				[multipleOrderIndex setObject:[NSNumber numberWithFloat:orderIndex] withOwner:orderIndexGroup];
				[multipleOrderIndex setObject:[NSNumber numberWithFloat:inIndex] withOwner:inGroup];
				orderIndex = 0;
				orderIndexGroup = nil;
				
			}else{
				//This is an update or addition to the existing multiple groups
				[multipleOrderIndex setObject:[NSNumber numberWithFloat:inIndex] withOwner:inGroup];
				
			}
		}
	}else{ //Remove
		//Whoops, can't do that yet :)
	}
}

//Alter the local grouping for this object (PRIVATE: These are for AIListGroup ONLY)
- (void)addContainingGroup:(AIListGroup *)inGroup
{
	[containingGroups addObject:inGroup];
}
- (void)removeContainingGroup:(AIListGroup *)inGroup
{
	[containingGroups removeObject:inGroup];
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

//Access to the status array for this object
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

//Quickly set a status key for this object (owned by this object)
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify
{
	[self setStatusObject:value withOwner:self forKey:key notify:notify];
}

//Quickly set a status key for this object
- (void)setStatusObject:(id)value withOwner:(id)owner forKey:(NSString *)key notify:(BOOL)notify
{
	if(key){
		[[self statusArrayForKey:key] setObject:value withOwner:owner];
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
- (void)setStatusObject:(id)value withOwner:(id)owner forKey:(NSString *)key afterDelay:(NSTimeInterval)delay
{
	if(!delayedStatusTimers) delayedStatusTimers = [[NSMutableArray alloc] init];
	NSTimer		*timer = [NSTimer scheduledTimerWithTimeInterval:delay
														  target:self
														selector:@selector(_applyDelayedStatus:)
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															owner, @"Owner",
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
				withOwner:[infoDict objectForKey:@"Owner"]
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

//Quickly retrieve a status key for this object (owned by this object)
- (id)statusObjectForKey:(NSString *)key
{
    return([[self statusArrayForKey:key] objectWithOwner:self]);
}

//Quickly retrieve a status key for this object
- (id)statusObjectForKey:(NSString *)key withOwner:(id)owner
{
    return([[self statusArrayForKey:key] objectWithOwner:owner]);
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
    [prefDict writeToPath:[self pathToPreferences] withName:[self UIDAndServiceID]];
    
    //Broadcast a preference changed notification
    [[adium notificationCenter] postNotificationName:Preference_GroupChanged
											  object:self
											userInfo:[NSDictionary dictionaryWithObjectsAndKeys:groupName,@"Group",inKey,@"Key",nil]];
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
    
    //### TEMPORARY (OLD LIST OBJECT PREFERENCE IMPORT CODE) #######
    if(!value && [[adium preferenceController] tempImportOldPreferenceForKey:inKey group:groupName object:self]){
	[prefDict release];
	prefDict = [[NSDictionary dictionaryAtPath:[self pathToPreferences] withName:[self UIDAndServiceID] create:NO] mutableCopy];
	if(prefDict) value = [prefDict objectForKey:inKey];
    }
    //#########################################################
    
    //If we don't have a value
    if(!value){
#warning Adam: Preferences will only inherit from the first occurence of a list object.
		//Is the ability to inherit from multiple locations worth the performance impact it would have
		//for those contacts?  Is inheriting from multiple places the behavior we want?
		if([containingGroups count]){
			//return the value of the group that contains us
			value = [[containingGroups objectAtIndex:0] preferenceForKey:inKey group:groupName];
			
		}else{
			//If we are the root group, return Adium's global preference for this key
			value = [[adium preferenceController] preferenceForKey:inKey group:groupName];
		}
    }
    
    return(value);
}

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
    id				value = nil;
    NSMutableArray  *returnArray = [NSMutableArray arrayWithCapacity:1];
    
    //Get our value for the preference
    if(prefDict){
        if(value = [prefDict objectForKey:inKey]){
            [returnArray addObject:value];
        }
    }
    
    //so long as we aren't the root group, add our containingGroups' preferences
    if([containingGroups count]){
        NSEnumerator    *enumerator = [containingGroups objectEnumerator];
        AIListObject    *containingGroup;
        while (containingGroup = [enumerator nextObject]) {
            [returnArray addObjectsFromArray:[containingGroup _recursivePreferencesForKey:inKey group:groupName]];
        }
    }
    
    return returnArray;
}


//Path for storing our reference file
- (NSString *)pathToPreferences
{
    return([[[adium loginController] userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH]);
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
