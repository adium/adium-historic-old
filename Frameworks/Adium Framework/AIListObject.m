/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactController.h"
#import "AIListGroup.h"
#import "AIListObject.h"
#import "AIPreferenceController.h"
#import "AIService.h"
#import "AIUserIcons.h"
#import <AIUtilities/AIMutableOwnerArray.h>

@interface AIListObject (PRIVATE)
- (void)determineOrderIndex;
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
- (id)initWithUID:(NSString *)inUID service:(AIService *)inService
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
	service = inService;

	visible = YES;
	orderIndex = 0;

    return(self);
}

- (void)dealloc
{	
	//
	[UID release]; UID = nil;
	[internalObjectID release]; internalObjectID = nil;
	[containingObject release]; containingObject = nil;
	
    [super dealloc];
}


//Identification -------------------------------------------------------------------------------------------------------
#pragma mark Identification
//UID of this object.  For contacts, this is basically the user name.
- (NSString *)UID
{
    return(UID);
}

//Service of this object
- (AIService *)service
{
	return(service);
}

- (NSString *)serviceID
{
	return([service serviceID]);
}
- (NSString *)serviceClass
{
	return([service serviceClass]);
}

//An object ID generated by Adium that is shared by all objects which are, to most intents and purposes, identical to
//this object.  Ths ID is composed of the service ID and UID, so any object with identical services and object ID's
//will have the same value here.
- (NSString *)internalObjectID
{
	if(!internalObjectID){
		internalObjectID = [[AIListObject internalObjectIDForServiceID:[[self service] serviceID] UID:[self UID]] retain];
	}
	return(internalObjectID);
}

+ (NSString *)internalObjectIDForServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
	return([NSString stringWithFormat:@"%@.%@",inServiceID, inUID]);
}


//Visibility -----------------------------------------------------------------------------------------------------------
#pragma mark Visibility
//Toggle visibility of this object
- (void)setVisible:(BOOL)inVisible
{	
	if(visible != inVisible){
		visible = inVisible;

		if([containingObject isKindOfClass:[AIListGroup class]]){
			//Let our containing group know about the visibility change
			[(AIListGroup *)containingObject visibilityOfContainedObject:self changedTo:inVisible];			
		}
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
- (AIListObject <AIContainingObject> *)containingObject
{
    return(containingObject);
}

//Set the local grouping for this object (PRIVATE: These are for AIListGroup ONLY)
- (void)setContainingObject:(AIListObject <AIContainingObject> *)inGroup
{
    if (containingObject != inGroup){
	   [containingObject release];
	   containingObject = [inGroup retain];
	}
#if 0
	BOOL hadContainingObject = (containingObject != nil);

	if (!hadContainingObject){
		//When we get our first containing object, our ordering information is appropriate
		[containingObject listObject:self didSetOrderIndex:orderIndex];
	}else{
		//Otherwise, clear it pending getting new ordering information, putting us the bottom of
		//the containing object for now (but not saving that data)
		orderIndex = ([containingObject largestOrder] + 1.0);

		[containingObject listObject:self didSetOrderIndex:orderIndex];
	}
#else
	//Always set the current orderIndex in the containingObject.  The above block may be clearing data after a 
	//disconnect/reconnect cycle?
	[containingObject listObject:self didSetOrderIndex:orderIndex];
#endif
}

//Returns the group this contact is ultimately within, traversing any other containing objects to find it
- (AIListGroup *)parentGroup
{
	AIListObject	*parentGroup = [[[adium contactController] parentContactForListObject:self] containingObject];
	if (parentGroup && [parentGroup isKindOfClass:[AIListGroup class]]){
		return((AIListGroup *)parentGroup);
	}else{
		return(nil);
	}
}
	
//Returns our desired placement within a group
- (float)orderIndex
{
	if(!orderIndex) [self determineOrderIndex];
	
	return(orderIndex);
}

- (void)determineOrderIndex
{	
	//Load the order index for this object (which will be appropriate for the last group it was in)
	NSNumber	*orderIndexNumber = [self preferenceForKey:KEY_ORDER_INDEX
													 group:ObjectStatusCache 
									 ignoreInheritedValues:YES];
	if (orderIndexNumber){
		float storedOrderIndex;
		
		storedOrderIndex = [orderIndexNumber floatValue];
		
		//Evan: I don't know how we got up to infinity.. perhaps pref corruption in a previous version?
		//In any case, check against it; if we stored it, reset to a reasonable number.
		if(storedOrderIndex < INFINITY){
			orderIndex = storedOrderIndex;
		}else{
			[self setOrderIndex:[[adium contactController] nextOrderIndex]];
		}
	}else{
		[self setOrderIndex:[[adium contactController] nextOrderIndex]];
	}
}

//Alter the placement of this object in a group (PRIVATE: These are for AIListGroup ONLY)
- (void)setOrderIndex:(float)inIndex
{
	orderIndex = inIndex;
	[[self containingObject] listObject:self didSetOrderIndex:orderIndex];
	
	//Save it
	[self setPreference:[NSNumber numberWithFloat:orderIndex] forKey:KEY_ORDER_INDEX group:ObjectStatusCache];
	
	//Sort the contained object
//	[[adium contactController] sortListObject:self];
}


//Status objects ------------------------------------------------------------------------------------------------------
#pragma mark Status objects
//
- (void)didModifyStatusKeys:(NSSet *)keys silent:(BOOL)silent
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
	
	[super object:inObject didSetStatusObject:value forKey:key notify:notify];
}

//AIMutableOwnerArray delegate ------------------------------------------------------------------------------------------
#pragma mark AIMutableOwnerArray delegate

//A mutable owner array (one of our displayArrays) set an object
- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority
{
	if (containingObject){
		[containingObject listObject:self mutableOwnerArray:inArray didSetObject:anObject withOwner:inOwner priorityLevel:priority];
	}
}

//Empty implementation by default - we do not need to take any action when a mutable owner array changes
- (void)listObject:(AIListObject *)listObject mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(AIListObject *)anObject withOwner:(AIListObject *)inOwner priorityLevel:(float)priority
{

}

//Object specific preferences ------------------------------------------------------------------------------------------
#pragma mark Object specific preferences
//Set a preference value
- (void)setPreference:(id)value forKey:(NSString *)key group:(NSString *)group
{   
	[[adium preferenceController] setPreference:value forKey:key group:group object:self];
}

//Retrieve a preference value
- (id)preferenceForKey:(NSString *)key group:(NSString *)group
{
	return([[adium preferenceController] preferenceForKey:key group:group object:self]);
}
- (id)preferenceForKey:(NSString *)key group:(NSString *)group ignoreInheritedValues:(BOOL)ignore
{
	if(ignore){
		return([[adium preferenceController] preferenceForKey:key group:group objectIgnoringInheritance:self]);
	}else{
		return([[adium preferenceController] preferenceForKey:key group:group object:self]);
	}
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
    NSString	*outName = [[self displayArrayForKey:LongDisplayName create:NO] objectValue];
	
    return(outName ? outName : [self displayName]);
}

//- (NSString *)displayServiceID
//{
//	NSString  *outName = [self statusObjectForKey:DisplayServiceID];
//	return (outName ? outName : [serviceType identifier]);
//}

#pragma mark Key-Value Pairing
- (NSImage *)userIcon
{
	return([self displayUserIcon]);
}
- (NSImage *)displayUserIcon
{
	return([[self displayArrayForKey:KEY_USER_ICON create:NO] objectValue]);	
}

- (void)setDisplayUserIcon:(NSImage *)inImage
{
	[self setDisplayUserIcon:inImage withOwner:self priorityLevel:Highest_Priority];
}
- (void)setDisplayUserIcon:(NSImage *)inImage withOwner:(id)inOwner priorityLevel:(float)inPriorityLevel
{
	AIMutableOwnerArray *userIconDisplayArray;
	NSImage				*oldImage;
	
	//If inImage is nil, we don't want to create the display array if it doesn't already exist
	userIconDisplayArray = (inImage ?
							[self displayArrayForKey:KEY_USER_ICON] :
							[self displayArrayForKey:KEY_USER_ICON create:NO]);
	oldImage = [self displayUserIcon];
	
	[[self displayArrayForKey:KEY_USER_ICON] setObject:inImage
											 withOwner:inOwner
										 priorityLevel:inPriorityLevel];
	
	//If the displayUserIcon changed, flush our cache and send out a notification
	if (oldImage != [self displayUserIcon]){
		[AIUserIcons flushCacheForContact:(AIListContact *)self];
		//Notify
		[[adium contactController] listObjectAttributesChanged:self
												  modifiedKeys:[NSSet setWithObject:KEY_USER_ICON]];
	}
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

//A standard listObject is never a stranger
- (BOOL)isStranger{
	return NO;
}

/*!
 * @brief Display name
 *
 * A listObject attempts to have the same displayName as its containing contact (potentially its metaContact).
 * If it is not in a metaContact, its display name is return by [self ownDisplayName].
 */
- (NSString *)displayName
{
    NSString	*outName;
	
	//Look for a parent contact and draw a display name from by default to provide a consistent naming
	AIListObject	*parentObject = [[adium contactController] parentContactForListObject:self];
	if (parentObject != self){
		outName = [parentObject displayName];
	}else{
		outName = [self ownDisplayName];
	}

	//If a display name was found, return it; otherwise, return the formattedUID
    return(outName ? outName : [self formattedUID]);
}

/*!
 * @brief This object's own display name
 *
 * Display name, drawing first from any externally-provided display name, then falling back to 
 * the formatted UID.
 */
- (NSString *)ownDisplayName
{
    NSString	*outName = [[self displayArrayForKey:DisplayName create:NO] objectValue];
    return(outName ? outName : [self formattedUID]);	
}

/*
 * @brief The way this object's name should be spoken
 *
 * If not found, the display name is returned.
 */
- (NSString *)phoneticName
{
	NSString	*outName;

	//Look for a parent contact and draw a display name from by default to provide a consistent naming
	AIListObject	*parentObject = [[adium contactController] parentContactForListObject:self];
	if (parentObject != self){
		outName = [parentObject phoneticName];
	}else{
		outName = [self ownPhoneticName];
	}
	
	//If a phonetic name was found, return it; otherwise, return the display name
    return(outName ? outName : [self displayName]);
}

- (NSString *)ownPhoneticName
{
    NSString	*outName = [[self displayArrayForKey:@"Phonetic Name" create:NO] objectValue];
    return(outName ? outName : [self displayName]);
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

		//XXX - There must be a cleaner way to do this alias stuff!  This works for now :)
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

- (NSComparisonResult)compare:(id)otherObject
{
	return ([otherObject isKindOfClass:[self class]] &&
			[[self internalObjectID] caseInsensitiveCompare:[otherObject internalObjectID]]);
}

#pragma mark Status states

/*!
* @brief The current status state
 */
- (AIStatus *)statusState
{
	return [self statusObjectForKey:@"StatusState"];
}

/*!
 * @brief Set the current status state
 *
 * @param name State name. May be nil to use the default state name for type
 * @param type The <tt>AIStatusType</tt>
 * @param statusMessage Status message. May be nil.
 * @param noitfy How to notify of the change. See -[ESObjectWithStatus setStatusObject:forKey:notify:].
 */
- (void)setStatusWithName:(NSString *)name statusType:(AIStatusType)type statusMessage:(NSAttributedString *)statusMessage notify:(NotifyTiming)notify
{
	AIStatus	*statusState = [AIStatus status];
	[statusState setStatusType:type];

	if(name) [statusState setStatusName:name];
	if(statusMessage) [statusState setStatusMessage:statusMessage];

	[self setStatusObject:statusState forKey:@"StatusState" notify:notify];
}

- (void)setBaseAvailableStatusAndNotify:(NotifyTiming)notify
{
	[self setStatusObject:nil forKey:@"StatusState" notify:notify];
}

/*!
 * @brief Determine the status message to be displayed in the contact list
 */
- (NSAttributedString *)contactListStatusMessage
{
	NSAttributedString	*contactListStatusMessage = [self statusObjectForKey:@"ContactListStatusMessage"];
	if(!contactListStatusMessage){
		contactListStatusMessage = [[self statusState] statusMessage];
	}
	
	return contactListStatusMessage;
}

- (BOOL)online
{
	return ([self integerStatusObjectForKey:@"Online"] ? YES : NO);
}

- (AIStatusSummary)statusSummary
{
	if ([self integerStatusObjectForKey:@"Online"]){
		AIStatus		*statusState = [self statusState];
		AIStatusType	statusType = (statusState ? [statusState statusType] : AIAvailableStatusType);
		
		if ((statusType == AIAwayStatusType) || (statusType == AIInvisibleStatusType)){
			if ([self integerStatusObjectForKey:@"IsIdle" fromAnyContainedObject:NO]){
				return AIAwayAndIdleStatus;
			}else{
				return AIAwayStatus;
			}
			
		}else if ([self integerStatusObjectForKey:@"IsIdle" fromAnyContainedObject:NO]){
			return AIIdleStatus;
			
		}else{
			return AIAvailableStatus;
			
		}
	}else{
		//We don't know the status of an stranger who isn't showing up as online
		if ([self isStranger]){
			return AIUnknownStatus;
			
		}else{
			return AIOfflineStatus;
			
		}
	}
}

#pragma mark Debugging
- (NSString *)description
{
	return([NSString stringWithFormat:@"%@:%@",[super description],[self internalObjectID]]);
}

@end
