/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

DeclareString(ObjectStatusCache);
DeclareString(DisplayName);
DeclareString(LongDisplayName);
DeclareString(Key);
DeclareString(Group);
DeclareString(DisplayServiceID);
DeclareString(FormattedUID);

//Init
- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
    [super init];

	InitString(ObjectStatusCache,@"Object Status Cache");
	InitString(DisplayName,@"Display Name");
	InitString(LongDisplayName,@"Long Display Name");
	InitString(Key,@"Key");
	InitString(Group,@"Group");
	InitString(DisplayServiceID,@"DisplayServiceID");
	InitString(FormattedUID,@"FormattedUID");
	
    containingObject = nil;
    UID = [inUID retain];	
    serviceID = [inServiceID retain];
	uniqueObjectID = nil;
	orderIndex = -1;
	delayedStatusTimers = nil;
	
	//Unless a subclass does otherwise, containedObjects is nil for a list object
	containedObjects = nil;
	
	visible = YES;

	
	NSString *formattedUID = [self preferenceForKey:FormattedUID 
											  group:ObjectStatusCache 
							  ignoreInheritedValues:YES];
	if (formattedUID && ![formattedUID isEqualToString:UID]){
		//No need to go through the whole rigamarole of setStatusObject:forKey:, especially since that will end up resaving the preference we just loaded
		//This whole formattedUID preference thing is basically just a hack for protocols which have a formatted UID we only get once we sign on; this way
		//offline contacts display with the properly formatted UID instead of the compactedString version Adium generally uses for internal bookkeeping.
		[statusDictionary setObject:formattedUID forKey:FormattedUID];
	}
	
    return(self);
}

- (void)dealloc
{	
	//
    [serviceID release];
	[UID release];
	[uniqueObjectID release];
	[containedObjects release];

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

//Unique ID string shared by this object and all objects which are, to most intents and purposes, identical to this object.
- (NSString *)uniqueObjectID
{
	if (!uniqueObjectID){
		uniqueObjectID = [[AIListObject uniqueObjectIDForUID:UID serviceID:serviceID] retain];
	}
	
	return uniqueObjectID;
}

+ (NSString *)uniqueObjectIDForUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
	return (inServiceID ? [NSString stringWithFormat:@"%@.%@",inServiceID,inUID] : inUID);
}

//Ultra unique ID string, potentially providing information to differentiate this list object from other 'identical' ones
//For a non-subclassed AIListObject, this is the same as the uniqueObjectID
- (NSString *)ultraUniqueObjectID
{
	return [self uniqueObjectID];
}

//Visibility -----------------------------------------------------------------------------------------------------------
#pragma mark Visibility
//Toggle visibility of this object
- (void)setVisible:(BOOL)inVisible
{	
	if(visible != inVisible){
		visible = inVisible;

		//Let our containing group know about the visibility change
		[containingObject visibilityOfContainedObject:self changedTo:inVisible];
	}
}

//Return current visibility of this object
- (BOOL)visible
{
	return(visible);
}


//Grouping / Ownership -------------------------------------------------------------------------------------------------
#pragma mark Grouping / Ownership
//Return the local group this object is in (will be nil for the root object)
- (AIListObject *)containingObject
{
    return(containingObject);
}

//Set the local grouping for this object (PRIVATE: These are for AIListGroup ONLY)
- (void)setContainingObject:(AIListObject *)inGroup
{
	containingObject = inGroup;
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

//Status objects ------------------------------------------------------------------------------------------------------
#pragma mark Status objects

- (void)didModifyStatusKeys:(NSArray *)keys silent:(BOOL)silent
{
	[[adium contactController] listObjectStatusChanged:self
									modifiedStatusKeys:keys
												silent:silent];
}

//When we notify of queued status changes, our containing group should as well as it stays in sync with
//any changes it may have made in object:didSetStatusObject:forKey:notify:
- (void)didNotifyOfChangedStatusSilently:(BOOL)silent
{
	//Let our containing object know about the notification request
	if (containingObject)
		[containingObject notifyOfChangedStatusSilently:silent];
}

//Subclasses may wish to override these - they must be sure to call super's implementation, too!
- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{				
	//Inform our containing group about the new status object value
	if (containingObject){
		[containingObject object:self didSetStatusObject:value forKey:key notify:notify];
	}

	//Cache the setting of a formatted UID so we'll have it while offline after the next launch
	if (inObject == self) {
		if ([key isEqualToString:FormattedUID]){
			[self setPreference:value forKey:key group:ObjectStatusCache];
		}
	}
	
	[super object:inObject didSetStatusObject:value forKey:key notify:notify];
}

//AIMutableOwnerArray delegate ------------------------------------------------------------------------------------------
#pragma mark AIMutableOwnerArray delegate

//A mutable owner array (one of our displayArrays) set an object
- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner
{
	if (containingObject)
		[containingObject listObject:self mutableOwnerArray:inArray didSetObject:anObject withOwner:inOwner];
}

//Empty implementation by default - we do not need to take any action when a mutable owner array changes
- (void)listObject:(AIListObject *)listObject mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(AIListObject *)anObject withOwner:(AIListObject *)inOwner
{
#warning Evan: We could destroy empty mutable owner arrays here... worthwhile?
}

//Object specific preferences ------------------------------------------------------------------------------------------
#pragma mark Object specific preferences
//Set a preference value
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName
{   
	NSMutableDictionary	*prefDict = [[adium preferenceController] cachedObjectPrefsForKey:[self uniqueObjectID]
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
												forKey:[self uniqueObjectID]
												  path:[self pathToPreferences]];
    
    //Broadcast a preference changed notification
    [[adium notificationCenter] postNotificationName:Preference_GroupChanged
											  object:self
											userInfo:[NSDictionary dictionaryWithObjectsAndKeys:groupName,Group,inKey,Key,nil]];
}

//Retrieve a preference value (with the option of ignoring inherited values)
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore
{
	if(!ignore) return([self preferenceForKey:inKey group:groupName]);
	
	//Return our value for the preference only
	NSMutableDictionary	*prefDict = [[adium preferenceController] cachedObjectPrefsForKey:[self uniqueObjectID]
																					 path:[self pathToPreferences]];
	return([prefDict objectForKey:inKey]);
}

//Retrieve a preference value
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName
{
    id					value = nil;
	NSMutableDictionary	*prefDict = [[adium preferenceController] cachedObjectPrefsForKey:[self uniqueObjectID]
																					 path:[self pathToPreferences]];
    
    //Get our value for the preference
    value = [prefDict objectForKey:inKey];
    
    //If we don't have a value
    if(!value){
		if(containingObject){
			//return the value of the group that contains us
			value = [containingObject preferenceForKey:inKey group:groupName];
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
	NSMutableDictionary	*prefDict = [[adium preferenceController] cachedObjectPrefsForKey:[self uniqueObjectID]
																					 path:[self pathToPreferences]];
    
    //Get our value for the preference
	if(value = [prefDict objectForKey:inKey]){
		[returnArray addObject:value];
	}
    
    //so long as we aren't the root group, add our containingObjects' preferences
	if(containingObject){
		[returnArray addObjectsFromArray:[containingObject _recursivePreferencesForKey:inKey group:groupName]];
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
 - formattedUID, formating or alteration of the UID provided by the account code "AIser 123"
 - DisplayName, short formatted name provided by plugins "Adam Iser"
 - LongDisplayName, long formatted name provided by plugins "Adam Iser (AIser 123)"

 A value will always be returned by these methods, so if there is no long display name present it will fall back to
 display name, formattedUID, and finally UID (which is guaranteed to be present).  Use whichever one seems best
 suited for what is being displayed.
 */

//Server-formatted UID if present, otherwise the UID
- (NSString *)formattedUID
{
	NSString  *outName = [self statusObjectForKey:FormattedUID];
    return(outName ? outName : UID);	
}

//Long display name, influenced by plugins
- (NSString *)longDisplayName
{
    NSString	*outName = [[self displayArrayForKey:LongDisplayName] objectValue];
    return(outName ? outName : [self displayName]);
//	return(outName ? [NSString stringWithFormat:@"%@ (%f)",outName,[self orderIndex]] : [self displayName]);
}

- (NSString *)displayServiceID
{
	NSString  *outName = [self statusObjectForKey:DisplayServiceID];
	return (outName ? outName : serviceID);
}

#pragma mark Key-Value Pairing
- (NSImage *)userIcon
{
	return([[self displayArrayForKey:KEY_USER_ICON create:NO] objectValue]);
}

- (NSData *)userIconData
{
	NSImage *userIcon = [self userIcon];
	return ([userIcon TIFFRepresentation]);
}
- (void)setUserIconData:(NSData *)inData
{
	[self setPreference:inData
				 forKey:KEY_USER_ICON
				  group:PREF_GROUP_USERICONS];
}

- (NSNumber *)idleTime
{
	NSNumber *idleNumber = [self statusObjectForKey:@"Idle"];
	return (idleNumber ? idleNumber : [NSNumber numberWithInt:0]);
}

- (BOOL)online
{
	return ([self integerStatusObjectForKey:@"Online"] ? YES : NO);
}

- (AIStatusSummary)statusSummary
{
	if ([[self numberStatusObjectForKey:@"Online"] boolValue]){
		if ([[self numberStatusObjectForKey:@"Away"] boolValue]){
			if ([self statusObjectForKey:@"IdleSince"]){
				return AIAwayAndIdleStatus;
			}else{
				return AIAwayStatus;
			}
			
		}else if ([self statusObjectForKey:@"IdleSince"]){
			return AIIdleStatus;
			
		}else{
			return AIAvailableStatus;
			
		}
	}else{
		//We don't know the status of an stranger who isn't showing up as online
		if ([[self numberStatusObjectForKey:@"Stranger"] boolValue]){
			return AIUnknownStatus;
			
		}else{
			return AIOfflineStatus;
			
		}
	}
	
}

- (NSString *)statusMessage
{
	return [[self statusObjectForKey:@"StatusMessage"] string];
}

//Display name, influenced by plugins
- (NSString *)displayName
{
    NSString	*outName = [[self displayArrayForKey:DisplayName] objectValue];
    return(outName ? outName : [self formattedUID]);
}
//Apply an alias
- (void)setDisplayName:(NSString *)alias
{
	if([alias length] == 0) alias = nil; 
	
	NSString	*oldAlias = [self preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES];
	if ((!alias && oldAlias) ||
		(alias && !([alias isEqualToString:oldAlias]))){
		//Save the alias
		[self setPreference:alias forKey:@"Alias" group:PREF_GROUP_ALIASES];
		
		#warning There must be a cleaner way to do this alias stuff!  This works for now :)
		[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
												  object:self
												userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																					 forKey:@"Notify"]];
	}
}

- (NSString *)notes
{
	NSString *notes;
	
    notes = [self preferenceForKey:@"Notes" group:PREF_GROUP_NOTES ignoreInheritedValues:YES];
	if (!notes) notes = [self statusObjectForKey:@"Notes"];
	
	return notes;
}
- (void)setNotes:(NSString *)notes
{
	if([notes length] == 0) notes = nil; 

	NSString	*oldNotes = [self preferenceForKey:@"Notes" group:PREF_GROUP_NOTES ignoreInheritedValues:YES];
	if ((!notes && oldNotes) ||
		(notes && (![notes isEqualToString:oldNotes]))){
		//Save the note
		[self setPreference:notes forKey:@"Notes" group:PREF_GROUP_NOTES];
	}
}

- (NSComparisonResult)compare:(AIListObject *)otherObject
{
	return ([[self uniqueObjectID] caseInsensitiveCompare:[otherObject uniqueObjectID]]);
}

#pragma mark Debugging
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@:%@",[super description],[self uniqueObjectID]];
}

//Contained Contacts (should be subclassed) ----------------------------------------------------------------------------
#pragma mark Contained Contacts (Subclassed)
- (BOOL)addObject:(AIListObject *)inObject { return NO; };
- (void)removeObject:(AIListObject *)inObject {};
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible {};
- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController {};

//Contained Contacts (handled for subclasses) --------------------------------------------------------------------------
//All these methods will have no effect, returning 0 or nil as appropriate, for non-subclassed AIListObject
#pragma mark Contained Contacts (Handled for subclasses)

//Return our contained objects
- (NSArray *)containedObjects
{
	return(containedObjects);
}

- (unsigned)containedObjectsCount
{
    return([containedObjects count]);
}

// Return an array of all objects. Defaults to just ourself.
- (NSArray *)listContacts
{
	return [NSArray arrayWithObject:self];
}
	

// Return a dictionary whose keys are serviceID's
// and whose objects are arrays of contained contacts with those serviceID's
- (NSDictionary *)dictionaryOfServicesAndListContacts
{
	NSMutableDictionary *contacts = [NSMutableDictionary dictionary];
	AIListObject		*current;
	NSString			*service;
	NSMutableArray		*contactList;
	int i;
	NSArray				*listContacts = [self listContacts];
	
	for( i = 0; i < [listContacts count]; i++ ) {
		current = [listContacts objectAtIndex:i];
		service = [current serviceID];
		
		// Is there already an entry for this service?
		if( contactList = [contacts objectForKey:service] ) {
			[contactList addObject:current];
			[contacts setObject:contactList forKey:service];
		} else {
			NSMutableArray *tempList = [NSMutableArray arrayWithObject:current];
			[contacts setObject:tempList forKey:service];
		}
	}
	NSLog(@"#### dictionaryOfServicesAndListContacts: %@",contacts);
	
	return contacts;
}

- (NSArray *)arrayOfServices
{
	NSMutableArray		*services = [NSMutableArray array];
	AIListObject		*current;
	NSString			*service;
	NSMutableArray		*contactList;
	int i;
	
	for( i = 0; i < [containedObjects count]; i++ ) {
		service = [[containedObjects objectAtIndex:i] serviceID];
		
		// Is there already an entry for this service?
		if( [services indexOfObject:service] == NSNotFound ) {
			[services addObject:service];
		}
	}
	
	return services;
}

//Test for the presence of an object in our group
- (BOOL)containsObject:(AIListObject *)inObject
{
	return([containedObjects containsObject:inObject]);
}

//Retrieve an object by index
- (id)objectAtIndex:(unsigned)index
{
    return([containedObjects objectAtIndex:index]);
}

//Retrieve the index of an object
- (int)indexOfObject:(AIListObject *)inObject
{
    return([containedObjects indexOfObject:inObject]);
}

//Return an enumerator of our content
- (NSEnumerator *)objectEnumerator
{
    return([containedObjects objectEnumerator]);
}

//Remove all the objects from this group (PRIVATE: For contact controller only)
- (void)removeAllObjects
{
	//Remove all the objects
	while([containedObjects count]){
		[self removeObject:[containedObjects objectAtIndex:0]];
	}
}

//
- (AIListObject *)objectWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
	NSEnumerator	*enumerator = [containedObjects objectEnumerator];
	AIListObject	*object;
	
	while(object = [enumerator nextObject]){
		if([inUID isEqualToString:[object UID]] && [inServiceID isEqualToString:[object serviceID]]){
			return(object);
		}
	}
	
	return(nil);
}

@end
