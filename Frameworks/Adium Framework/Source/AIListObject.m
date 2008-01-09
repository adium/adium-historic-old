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

#import <Adium/AIListObject.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIService.h>
#import <Adium/AIUserIcons.h>
#import <AIUtilities/AIMutableOwnerArray.h>

#define ObjectStatusCache	@"Object Status Cache"
#define DisplayName			@"Display Name"
#define LongDisplayName		@"Long Display Name"
#define Key					@"Key"
#define Group				@"Group"
#define DisplayServiceID	@"DisplayServiceID"
#define FormattedUID		@"FormattedUID"

@interface AIListObject (PRIVATE)
- (void)determineOrderIndex;
@end

/*!
 * @class AIListObject
 * @brief Base class for all contacts, groups, and accounts
 */
@implementation AIListObject

/*!
 * @brief Initialize
 *
 * Designated initializer for AIListObject
 */
- (id)initWithUID:(NSString *)inUID service:(AIService *)inService
{
	if ((self = [super init])) {
		containingObject = nil;
		UID = [inUID retain];	
		service = inService;

		visible = YES;
		orderIndex = 0;

		[[adium preferenceController] addObserver:self
									   forKeyPath:@"Always Visible.Visible"
										 ofObject:self
										  options:NSKeyValueObservingOptionNew
										  context:NULL];
		[self observeValueForKeyPath:@"Always Visible.Visible"
							ofObject:nil
							  change:nil
							 context:NULL];
	}

	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	//
	[UID release]; UID = nil;
	[internalObjectID release]; internalObjectID = nil;
	[containingObject release]; containingObject = nil;

    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath hasSuffix:@"Visible"]) {
		alwaysVisible = [[self preferenceForKey:@"Visible" group:PREF_GROUP_ALWAYS_VISIBLE] boolValue];
	}
}

//Identification -------------------------------------------------------------------------------------------------------
#pragma mark Identification

/*!
 * @brief UID for this object
 *
 * The UID is the name of the object.  If the object's name is not case sensitive, it is normalized.  If the object's
 * name should be compared ignoring spaces, it has no spaces.  For an account, this is the account name.  For a contact,
 * this is the screen name, buddy name, etc.
 */
- (NSString *)UID
{
    return UID;
}

/*!
 * @brief Service of this object
 */
- (AIService *)service
{
	return service;
}

/*!
 * @brief ServiceID of this object's service
 *
 * The serviceID is completely unique to the specific service.
 */
- (NSString *)serviceID
{
	return [service serviceID];
}

/*!
 * @brief ServiceClass of this object's service
 *
 * A serviceClass may be shared by multiple compatible services.
 * For example, AIM and ICQ share the serviceClass @"AIM-compatible"
 * 
 */
- (NSString *)serviceClass
{
	return [service serviceClass];
}

/*!
 * @brief Internal ID for this object
 *
 * An object ID generated by Adium that is shared by all objects which are, to most intents and purposes, identical to
 * this object.  Ths ID is composed of the service ID and UID, so any object with identical services and object IDs
 * will have the same value here.
 */
- (NSString *)internalObjectID
{
	if (!internalObjectID) {
		internalObjectID = [[AIListObject internalObjectIDForServiceID:[[self service] serviceID] UID:[self UID]] retain];
	}
	return internalObjectID;
}

/*!
 * @brief Generate an internal object ID
 *
 * @result The internalObjectID for an object with the specified serviceID and UID
 */
+ (NSString *)internalObjectIDForServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
	return [NSString stringWithFormat:@"%@.%@",inServiceID, inUID];
}


//Visibility -----------------------------------------------------------------------------------------------------------
#pragma mark Visibility
/*!
 * @brief Toggle visibility of this object
 *
 * How visibility works:
 * Code elsewhere will later query this object to determine if it is visible.  The object's containing group tracks
 * the number of visibile objects within it.  Visible objects are always sorted to the top of their group; a group
 * only displays as many objects as are visible, so invisible objects are not shown.
 */
- (void)setVisible:(BOOL)inVisible
{	
	if (visible != inVisible) {
		visible = inVisible;
		
		if ([containingObject isKindOfClass:[AIListGroup class]]) {
			//Let our containing group know about the visibility change
			[(AIListGroup *)containingObject visibilityOfContainedObject:self changedTo:inVisible];			
		}
	}
}

/*!
 * @brief Is the object visible?
 */
- (BOOL)visible
{
	return visible || [self alwaysVisible];
}

/*!
 * @brief Sets if list object should always be visible
 */
- (void)setAlwaysVisible:(BOOL)inVisible {
	if (inVisible != alwaysVisible) {
		[self setPreference:[NSNumber numberWithBool:inVisible] 
					 forKey:@"Visible" 
					  group:PREF_GROUP_ALWAYS_VISIBLE];
		
		if ([containingObject isKindOfClass:[AIListGroup class]]) {
			//Let our containing group know about the visibility change
			[(AIListGroup *)containingObject visibilityOfContainedObject:self changedTo:[self visible]];			
		}
	}
}

/*!
 * @returns If object should always be visible
 */
- (BOOL)alwaysVisible {
	return alwaysVisible;
}

//Grouping / Ownership -------------------------------------------------------------------------------------------------
#pragma mark Grouping / Ownership
/*!
 * @brief Containing object of this object
 */
- (AIListObject<AIContainingObject> *)containingObject
{
    return containingObject;
}

/*!
 * @brief Set the local grouping for this object
 *
 * PRIVATE: This is only for use by AIListObjects conforming to the AIContainingObject protocol.
 */
- (void)setContainingObject:(AIListObject <AIContainingObject> *)inGroup
{
    if (containingObject != inGroup) {
	   [containingObject release];
	   containingObject = [inGroup retain];

	   //Always set the current orderIndex in the containingObject.
	   [(AIListObject<AIContainingObject> *)containingObject listObject:self 
													   didSetOrderIndex:[self orderIndex]];
	}
}
	
/*!
 * @brief Returns our desired placement within a group
 */
- (float)orderIndex
{
	if (!orderIndex) [self determineOrderIndex];
	
	return orderIndex;
}

- (void)determineOrderIndex
{	
	//Load the order index for this object (which will be appropriate for the last group it was in)
	NSNumber	*orderIndexNumber = [self preferenceForKey:KEY_ORDER_INDEX
													 group:ObjectStatusCache 
									 ignoreInheritedValues:YES];
	if (orderIndexNumber) {
		float storedOrderIndex;
		
		storedOrderIndex = [orderIndexNumber floatValue];
		
		//Evan: I don't know how we got up to infinity.. perhaps pref corruption in a previous version?
		//In any case, check against it; if we stored it, reset to a reasonable number.
		if (storedOrderIndex < INFINITY) {
			orderIndex = storedOrderIndex;
		}
	}

	if (!orderIndex) {
		[self setOrderIndex:([[self containingObject] largestOrder] + 1)];
	}
	
	if (!orderIndex) {
		AILog(@"WARNING: %@ could not determine its order index. Containing object: %@; preference yields %@",self,[self containingObject],orderIndexNumber);
	}
}

/*!
 * @brief Alter the placement of this object in a group
 *
 * PRIVATE: These are for AIListGroup ONLY
 */
- (void)setOrderIndex:(float)inIndex
{
	orderIndex = inIndex;
	[[self containingObject] listObject:self didSetOrderIndex:orderIndex];
	
	//Save it
	[self setPreference:[NSNumber numberWithFloat:orderIndex] forKey:KEY_ORDER_INDEX group:ObjectStatusCache];
	
	//Sort the contained object
//	[[adium contactController] sortListObject:self];
}

- (BOOL)containsMultipleContacts
{
	return NO;
}

//Status objects ------------------------------------------------------------------------------------------------------
#pragma mark Status objects
/*!
 * @brief Called after status keys have been modified; informs the contact controller.
 *
 * @param keys The keys
 * @param silent YES indicates that this should not trigger 'noisy' notifications - it is appropriate for notifications as an account signs on and notes tons of contacts.
 */
- (void)didModifyStatusKeys:(NSSet *)keys silent:(BOOL)silent
{
	[[adium contactController] listObjectStatusChanged:self
									modifiedStatusKeys:keys
												silent:silent];
}
/*!
 * @brief Called after status changes have been modified and notifications posted
 *
 * When we notify of queued status changes, our containing group should notify as well so it can stay in sync with
 * any changes it may have made in object:didSetStatusObject:forKey:notify:
 *
 * @param silent YES indicates that this should not trigger 'noisy' notifications - it is appropriate for notifications as an account signs on and notes tons of contacts.
 */
- (void)didNotifyOfChangedStatusSilently:(BOOL)silent
{
	//Let our containing object know about the notification request
	if (containingObject)
		[containingObject notifyOfChangedStatusSilently:silent];
}

/*!
 * @brief Notifcation of changed status keys
 *
 * Subclasses may wish to override these - they must be sure to call super's implementation, too!
 */
- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{				
	//Inform our containing group about the new status object value
	if (containingObject) {
		[containingObject object:self didSetStatusObject:value forKey:key notify:notify];
	}
	
	[super object:inObject didSetStatusObject:value forKey:key notify:notify];
}

//AIMutableOwnerArray delegate ------------------------------------------------------------------------------------------
#pragma mark AIMutableOwnerArray delegate

/*!
 * @brief One of our mutable owners set an object
 *
 * A mutable owner array (one of our displayArrays) set an object
 */
- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority
{
	if (containingObject) {
		[containingObject listObject:self mutableOwnerArray:inArray didSetObject:anObject withOwner:inOwner priorityLevel:priority];
	}
}

/*!
 * @brief Another object changed one of our mutable owner arrays
 *
 * Empty implementation by default - we do not need to take any action when a mutable owner array changes
 */
- (void)listObject:(AIListObject *)listObject mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(AIListObject *)inOwner priorityLevel:(float)priority
{

}

//Object specific preferences ------------------------------------------------------------------------------------------
#pragma mark Object specific preferences
/*!
 * @brief Set a preference value
 */
- (void)setPreference:(id)value forKey:(NSString *)key group:(NSString *)group
{   
	[[adium preferenceController] setPreference:value forKey:key group:group object:self];
}
- (void)setPreferences:(NSDictionary *)prefs inGroup:(NSString *)group
{
	[[adium preferenceController] setPreferences:prefs inGroup:group object:self];	
}

- (void)setFormattedUID:(NSString *)inFormattedUID notify:(NotifyTiming)notify
{
	[self setStatusObject:inFormattedUID
				   forKey:FormattedUID
				   notify:notify];
}

/*!
 * @brief Retrieve a preference value
 */
- (id)preferenceForKey:(NSString *)key group:(NSString *)group
{
	return [[adium preferenceController] preferenceForKey:key group:group object:self];
}

/*!
 * @brief Retrieve a preference value, possibly ignoring inheritance
 */
- (id)preferenceForKey:(NSString *)key group:(NSString *)group ignoreInheritedValues:(BOOL)ignore
{
	if (ignore) {
		return [[adium preferenceController] preferenceForKey:key group:group objectIgnoringInheritance:self];
	} else {
		return [[adium preferenceController] preferenceForKey:key group:group object:self];
	}
}

/*!
 * @brief Path for storing our reference file
 */
- (NSString *)pathToPreferences
{
    return OBJECT_PREFS_PATH;
}

//Display Name  -------------------------------------------------------------------------------------
#pragma mark Display Name 
/*
 * A list object basically has 4 different variations of display.
 *
 * - UID, the base UID of the contact "aiser123"
 * - formattedUID, formating or alteration of the UID provided by the account code "AIser 123"
 * - DisplayName, short formatted name provided by plugins "Adam Iser"
 * - LongDisplayName, long formatted name provided by plugins "Adam Iser (AIser 123)"
 *
 * A value will always be returned by these methods, so if there is no long display name present it will fall back to
 * display name, formattedUID, and finally UID (which is guaranteed to be present).  Use whichever one seems best
 * suited for what is being displayed.
 */

/*!
 * @brief Server-formatted UID
 *
 * @result NSString of the server-formatted UID if present; otherwise the same as the UID
 */
- (NSString *)formattedUID
{
	NSString  *outName = [self statusObjectForKey:FormattedUID];
    return outName ? outName : UID;	
}

/*!
 * @brief Long display name
 *
 * Though in many cases the same as the display name, a long display name allows additional information about the object
 * to be displayed.  One preference, for example, sets a long display names formatted as "Alias (Username)".
 */
- (NSString *)longDisplayName
{
    NSString	*outName = [[self displayArrayForKey:LongDisplayName create:NO] objectValue];
	
    return outName ? outName : [self displayName];
}

/*!
* @brief Display name
 *
 * Display name, drawing first from any externally-provided display name, then falling back to 
 * the formatted UID.
 */
- (NSString *)displayName
{
    NSString	*displayName = [[self displayArrayForKey:DisplayName create:NO] objectValue];
    return displayName ? displayName : [self formattedUID];
}

/*!
* @brief The way this object's name should be spoken
 *
 * If not found, the display name is returned.
 */
- (NSString *)phoneticName
{
	NSString	*phoneticName = [[self displayArrayForKey:@"Phonetic Name" create:NO] objectValue];
    return phoneticName ? phoneticName : [self displayName];
}

//Apply an alias
- (void)setDisplayName:(NSString *)alias
{
	if ([alias length] == 0) alias = nil; 
	
	NSString	*oldAlias = [self preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES];
	
	if ((!alias && oldAlias) ||
		(alias && !([alias isEqualToString:oldAlias]))) {
		//Save the alias
		[self setPreference:alias forKey:@"Alias" group:PREF_GROUP_ALIASES];
		
		//XXX - There must be a cleaner way to do this alias stuff!  This works for now :)
		[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
												  object:self
												userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																					 forKey:@"Notify"]];
	}
}

#pragma mark Key-Value Pairing
- (NSImage *)userIcon
{
	return [self internalUserIcon];
}
- (NSImage *)internalUserIcon
{
	return [AIUserIcons userIconForObject:self];
}

- (NSData *)userIconData
{
	NSImage *userIcon = [self userIcon];
	return ([userIcon TIFFRepresentation]);
}
- (void)setUserIconData:(NSData *)inData
{
	[AIUserIcons setManuallySetUserIconData:inData forObject:self];
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

- (NSString *)notes
{
	NSString *notes;
	
    notes = [self preferenceForKey:@"Notes" group:PREF_GROUP_NOTES ignoreInheritedValues:YES];
	if (!notes) notes = [self statusObjectForKey:@"Notes"];
	
	return notes;
}
- (void)setNotes:(NSString *)notes
{
	if ([notes length] == 0) notes = nil; 

	NSString	*oldNotes = [self preferenceForKey:@"Notes" group:PREF_GROUP_NOTES ignoreInheritedValues:YES];
	if ((!notes && oldNotes) ||
		(notes && (![notes isEqualToString:oldNotes]))) {
		//Save the note
		[self setPreference:notes forKey:@"Notes" group:PREF_GROUP_NOTES];
	}
}

#pragma mark Status states

/*!
 * @brief The name for the specific status of this object
 *
 * The statusName provides further detail after the statusType.  It may be a string such as @"Busy" or @"BRB".
 * Possible values are determined by installed services; many default possibilities are listed in AIStatusController.h.
 *
 * The statusName may be nil if no additional status information is available for the contact. For example, an AIM
 * contact will never have a statusName value, as the possibilities enumerated by AIStatusType -- and therefore returned
 * by -[AIListObject statusType] -- cover all possibilities.  An ICQ contact, on the other hand, might have a statusType
 * of AIAwayStatusType and then a statusName of @"Not Available" or @"DND".
 *
 * @result The statusName, or nil none exists
 */
- (NSString *)statusName
{
	return [self statusObjectForKey:@"StatusName"];
}

/*!
 * @brief The general type of this object's status
 *
 * @result The AIStatusType for this object, indicating if it is available, away, invisible, offline, etc.
 */
- (AIStatusType)statusType
{
	NSNumber		*statusTypeNumber = [self statusObjectForKey:@"StatusType"];
	AIStatusType	statusType = (statusTypeNumber ?
								  [statusTypeNumber intValue] :
								  ([self online] ? AIAvailableStatusType : AIOfflineStatusType));

	return statusType;
}

/*!
 * @brief Store the status name and type for this object
 *
 * This is used by account code to let the object know its name and status type
 * @param statusName The statusName, which further specifies the statusType, or nil if none is available
 * @param statusType The AIStatusType describing this object's status
 * @param notify The NotifyTiming for this operation
 */
- (void)setStatusWithName:(NSString *)statusName statusType:(AIStatusType)statusType notify:(NotifyTiming)notify
{
	AIStatusType	currentStatusType = [self statusType];
	NSString		*oldStatusName = [self statusName];
	
	if (currentStatusType != statusType) {
		[self setStatusObject:[NSNumber numberWithInt:statusType] forKey:@"StatusType" notify:NotifyLater];
	}
	
	if ((!statusName && oldStatusName) || (statusName && ![statusName isEqualToString:oldStatusName])) {
		[self setStatusObject:statusName forKey:@"StatusName" notify:NotifyLater];
	}
	
	if (notify) [self notifyOfChangedStatusSilently:NO];
}

/*!
 * @brief Return the status message for this object
 *
 * The statusMessage may supplement the statusType and statusName with a message describing the object's status; in AIM,
 * for example, both available and away statuses can have an associated, user-set message.
 *
 * @result The NSAttributedString statusMessagae, or nil if none is set
 */
- (NSAttributedString *)statusMessage
{
	return [self statusObjectForKey:@"StatusMessage"];
}

/*!
 * @brief Return the status message for this object as NSString
 *
 * The statusMessageString may supplement the statusType and statusName with a message describing the object's status; in AIM,
 * for example, both available and away statuses can have an associated, user-set message.
 *
 * @result The NSString statusMessage, or nil if none is set
 */
- (NSString *)statusMessageString;
{
	return [[self statusObjectForKey:@"StatusMessage"] string];
}

/*!
 * @brief Is this object connected via a mobile device?
 *
 * The default implementation simply returns NO.  Only an AIListContact can be mobile... but a base implementation here
 * makes code elsewhere much simpler.
 */
- (BOOL)isMobile
{
	return NO;
}

/*!
 * @brief Is this contact blocked?
 *
 * @result A boolean indicating if the object is blocked
 */
- (BOOL)isBlocked
{
	return NO;
}

/*!
 * @brief Set the current status message
 *
 * @param statusMessage Status message. May be nil.
 * @param noitfy How to notify of the change. See -[ESObjectWithStatus setStatusObject:forKey:notify:].
 */
- (void)setStatusMessage:(NSAttributedString *)statusMessage notify:(NotifyTiming)notify
{
	if (!statusMessage ||
	   ![[self statusObjectForKey:@"StatusMessage"] isEqualToAttributedString:statusMessage]) {
		[self setStatusObject:statusMessage forKey:@"StatusMessage" notify:notify];
	}
}

- (NSString *)scriptingStatusMessage
{
	return [self statusMessageString];
}
- (void)setScriptingStatusMessage:(NSString *)message
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
	[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't set the status of a contact."];
}

- (void)setBaseAvailableStatusAndNotify:(NotifyTiming)notify
{
	[self setStatusWithName:nil
				 statusType:AIAvailableStatusType
					 notify:NotifyLater];
	[self setStatusMessage:nil
					 notify:NotifyLater];

	if (notify) [self notifyOfChangedStatusSilently:NO];
}

- (BOOL)online
{
	return ([self integerStatusObjectForKey:@"Online"] ? YES : NO);
}

- (AIStatusSummary)statusSummary
{
	if ([self integerStatusObjectForKey:@"Online"]) {
		AIStatusType	statusType = [self statusType];
		
		if ((statusType == AIAwayStatusType) || (statusType == AIInvisibleStatusType)) {
			if ([self integerStatusObjectForKey:@"IsIdle" fromAnyContainedObject:NO]) {
				return AIAwayAndIdleStatus;
			} else {
				return AIAwayStatus;
			}
			
		} else if ([self integerStatusObjectForKey:@"IsIdle" fromAnyContainedObject:NO]) {
			return AIIdleStatus;
			
		} else {
			return AIAvailableStatus;
			
		}
	} else {
		//We don't know the status of an stranger who isn't showing up as online
		if ([self isStranger]) {
			return AIUnknownStatus;
			
		} else {
			return AIOfflineStatus;
			
		}
	}
}

- (void)notifyOfChangedStatusSilently:(BOOL)silent
{
	[super notifyOfChangedStatusSilently:silent];
}

/*!
 * @brief Are sounds for this object muted?
 */
- (BOOL)soundsAreMuted
{
	return NO;
}

#pragma mark Comparison
/*
- (BOOL)isEqual:(id)anObject
{
	return ([anObject isMemberOfClass:[self class]] &&
			[[(AIListObject *)anObject internalObjectID] isEqualToString:[self internalObjectID]]);
}
*/

- (NSComparisonResult)compare:(AIListObject *)other {
	NSParameterAssert([other isKindOfClass:[AIListObject class]]);
	return [[self internalObjectID] caseInsensitiveCompare:[other internalObjectID]];
}

#pragma mark Icons
- (NSImage *)menuIcon
{
	return [AIUserIcons menuUserIconForObject:self];
}

- (NSImage *)statusIcon
{
	NSImage *statusIcon = [self displayArrayObjectForKey:@"List State Icon"];
	if (!statusIcon) statusIcon = [self displayArrayObjectForKey:@"List Status Icon"];
	if (!statusIcon) statusIcon = [AIStatusIcons statusIconForUnknownStatusWithIconType:AIStatusIconList
																			 direction:AIIconNormal];
	return statusIcon;
}

#pragma mark Debugging
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%x %@>",NSStringFromClass([self class]), self, [self internalObjectID]];
}


- (int)scriptingStatusType
{
	AIStatusType statusType = [self statusType];
	switch (statusType) {
		case AIAvailableStatusType:
			return AIAvailableStatusTypeAS;
		case AIOfflineStatusType:
			return AIOfflineStatusTypeAS;
		case AIAwayStatusType:
			return AIAwayStatusTypeAS;
		case AIInvisibleStatusType:
			return AIInvisibleStatusTypeAS;
	}
	return 0;
}

@end
