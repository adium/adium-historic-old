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

#import "AIStatus.h"
#import "AIStatusController.h"
#import "AIStatusIcons.h"
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@implementation AIStatus

/*!
 * @brief Create an autoreleased AIStatus
 *
 * @result New autoreleased AIStatus
 */
+ (AIStatus *)status
{
	AIStatus	*newStatus = [[[self alloc] init] autorelease];
	
	//Configure defaults as necessary
	[newStatus setAutoReplyIsStatusMessage:YES];

	return newStatus;
}

/*!
 * @brief Crate an AIStatus from a dictionary
 *
 * @param inDictionary A dictionary of keys to use as the new AIStatus's statusDict
 * @result AIStatus from inDictionary
 */
+ (AIStatus *)statusWithDictionary:(NSDictionary *)inDictionary
{
	AIStatus	*status = [self status];
	[status->statusDict addEntriesFromDictionary:inDictionary];

	return status; 
}

/*!
 * @brief Create an autoreleased AIStatus of a specified type
 *
 * The new AIStatus will have its statusType and statusName set appropriately.
 *
 * @result New autoreleased AIStatus
 */
+ (AIStatus *)statusOfType:(AIStatusType)inStatusType
{
	AIStatus	*status = [self status];
	[status setStatusType:inStatusType];
	[status setStatusName:[[[AIObject sharedAdiumInstance] statusController] defaultStatusNameForType:inStatusType]];
	
	if (inStatusType == AIAwayStatusType) {
		[status setHasAutoReply:YES];
	}
	
	return status;
}

/*!
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		statusDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/*!
 * @brief Copy
 */
- (id)copyWithZone:(NSZone *)zone
{
	return [self retain];
}

- (id)mutableCopy
{
	AIStatus	*status = [[[self class] alloc] init];
	
	[status->statusDict release];
	status->statusDict = [statusDict mutableCopy];

	//Clear the unique ID for this new status, since it should not share our ID.
	[status->statusDict removeObjectForKey:STATUS_UNIQUE_ID];
		
	return status;
}

/*!
 * @brief Encode with Coder
 */
- (void)encodeWithCoder:(NSCoder *)encoder
{
	//Ensure we have a unique status ID before encoding
	[self uniqueStatusID];
	
	if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:statusDict forKey:@"AIStatusDict"];

    } else {
        [encoder encodeObject:statusDict];
    }
}

/*!
 * @brief Initialize with coder
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		if ([decoder allowsKeyedCoding]) {
			// Can decode keys in any order		
			statusDict = [[decoder decodeObjectForKey:@"AIStatusDict"] mutableCopy];
			
		} else {
			// Must decode keys in same order as encodeWithCoder:		
			statusDict = [[decoder decodeObject] mutableCopy];
		}
	}
	
	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[statusDict release];
	
	[super dealloc];
}

/*!
 * @brief Returns an appropriate icon for this state
 *
 * This method will generate an appropriate status icon based on the state's content.
 *
 * @param iconType The AIStatusIconType to use
 * @result An <tt>NSImage</tt>
 */
- (NSImage *)iconOfType:(AIStatusIconType)iconType
{
	NSString		*statusName;
	AIStatusType	statusType;
	
	if ([self shouldForceInitialIdleTime]) {
		statusName = @"Idle";
		statusType = AIAwayStatusType;
	} else {
		statusName = [self statusName];
		statusType = [self statusType];
	}
	
	return [AIStatusIcons statusIconForStatusName:statusName
									   statusType:statusType
										 iconType:iconType
										direction:AIIconNormal];
}

/*!
 * @brief Returns an appropriate icon for this state
 *
 * This method will generate an appropriate status icon based on the state's content.
 *
 * @result An <tt>NSImage</tt>
 */ 
- (NSImage *)icon
{
	return [self iconOfType:AIStatusIconList];
}

- (NSImage *)menuIcon
{
	return [self iconOfType:AIStatusIconMenu];	
}

/*!
 * @brief The status message for this status
 *
 * @result An NSAttributedString status message, or nil if no status message or a 0-length status message is set
 */
- (NSAttributedString *)statusMessage
{
	NSAttributedString	*statusMessage;
	
	statusMessage = [statusDict objectForKey:STATUS_STATUS_MESSAGE];

	if (![statusMessage length]) statusMessage = nil;

	return statusMessage;
}

/*!
 * @brief Return the status message as a string
 */
- (NSString *)statusMessageString
{
	return [[self statusMessage] string];
}

/*!
 * @brief Set the status message
 */
- (void)setStatusMessage:(NSAttributedString *)statusMessage
{
	if (statusMessage) {
		[statusDict setObject:statusMessage
					   forKey:STATUS_STATUS_MESSAGE];
	} else {
		[statusDict removeObjectForKey:STATUS_STATUS_MESSAGE];
	}
}

/*!
 * @brief Set the status message as a string
 *
 * @param statusMessageString The status message as a string; HTML may be passed if desired
 */
- (void)setStatusMessageString:(NSString *)statusMessageString
{
	[self setStatusMessage:[AIHTMLDecoder decodeHTML:statusMessageString]];
}

/*!
 * @brief The auto reply to send when in this status
 *
 * @result An NSAttributedString auto reply, or nil if no auto reply should be sent
 */
- (NSAttributedString *)autoReply
{
	NSAttributedString	*autoReply = nil;

	if ([self hasAutoReply]) {
		autoReply = ([self autoReplyIsStatusMessage] ?
					 [self statusMessage] :
					 [statusDict objectForKey:STATUS_AUTO_REPLY_MESSAGE]);
	}

	if (![autoReply length]) autoReply = nil;
	
	return autoReply;
}

/*!
 * @brief Autoreply as a string
 */
- (NSString *)autoReplyString
{
	return [[self autoReplyString] string];
}

/*!
 * @brief Set the autoReply
 */
- (void)setAutoReply:(NSAttributedString *)autoReply
{
	if (autoReply) {
		[statusDict setObject:autoReply
					   forKey:STATUS_AUTO_REPLY_MESSAGE];
	} else {
		[statusDict removeObjectForKey:STATUS_AUTO_REPLY_MESSAGE];
	}
}

/*
 * @brief Set the autoreply as a string
 *
 * @param autoReplyString The autoreply as a string; HTML may be passed if desired
 */
- (void)setAutoReplyString:(NSString *)autoReplyString
{
	[self setAutoReply:[AIHTMLDecoder decodeHTML:autoReplyString]];
}

/*!
 * @brief Does this status state send an autoReeply?
 */
- (BOOL)hasAutoReply
{
	return [[statusDict objectForKey:STATUS_HAS_AUTO_REPLY] boolValue];
}

/*!
 * @brief Set if this status sends an autoReply
 */
- (void)setHasAutoReply:(BOOL)hasAutoReply
{
	[statusDict setObject:[NSNumber numberWithBool:hasAutoReply]
				   forKey:STATUS_HAS_AUTO_REPLY];
}

/*!
 * @brief Is the autoReply the same as the status message?
 */
- (BOOL)autoReplyIsStatusMessage
{
	return [[statusDict objectForKey:STATUS_AUTO_REPLY_IS_STATUS_MESSAGE] boolValue];
}

/*!
 * @brief Set if the autoReply is the same as the status message
 */
- (void)setAutoReplyIsStatusMessage:(BOOL)autoReplyIsStatusMessage
{
	[statusDict setObject:[NSNumber numberWithBool:autoReplyIsStatusMessage]
				   forKey:STATUS_AUTO_REPLY_IS_STATUS_MESSAGE];
}

/*!
* @brief Returns an appropriate title
 *
 * Not all states provide a title.  This method will generate an appropriate title based on the states' content.
 * If the state has a specified title, it will always be used.
 */ 
- (NSString *)title
{
	NSAttributedString	*statusMessage, *autoReply;
	NSString			*title = nil;
	AIStatusType		statusType;
	NSRange				linebreakRange;
	
	//If the state has a title, we simply use it
	if (!title) {
		NSString *string = [statusDict objectForKey:STATUS_TITLE];
		if (string && [string length]) title = string;
	}

	//If the state has a status message, use it.
	if (!title && 
	   (statusMessage = [self statusMessage]) &&
	   ([statusMessage length])) {
		title = [statusMessage string];
	}

	//If the state has an autoreply (but no status message), use it.
	if (!title &&
	   (autoReply = [self autoReply]) &&
	   ([autoReply length])) {
		title = [autoReply string];
	}
	
	/* If the state is not an available state, or it's an available state with a non-default statusName,
 	 * use the description of the state itself. */
	statusType = [self statusType];
	if (!title &&
	   (([self statusType] != AIAvailableStatusType) || (([self statusName] != nil) &&
														 ![[self statusName] isEqualToString:STATUS_NAME_AVAILABLE]))) {
		title = [[adium statusController] descriptionForStateOfStatus:self];
	}

	//If the state is simply idle, use the string "Idle"
	if (!title && [self shouldForceInitialIdleTime]) {
		title = AILocalizedStringFromTable(@"Idle", @"AdiumFramework", nil);
	}

	if (!title && (statusType == AIOfflineStatusType)) {
		title = [[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_OFFLINE];
	}

	//If the state is none of the above, use the string "Available"
	if (!title) title = [[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE];
	
	//Strip newlines and whitespace from the beginning and the end
	title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	//Only use the first line of a multi-line title
	linebreakRange = [title lineRangeForRange:NSMakeRange(0, 0)];
	//check to make sure that there actually is a linebreak to account for
	//	by comparing the linebreak range against the whole string's range.
	if ( !NSEqualRanges(linebreakRange, NSMakeRange(0, [title length])) ) {  
		title = [title substringWithRange:linebreakRange];  
	}
	
	return title;
}

/*!
 * @brief Set the title
 */
- (void)setTitle:(NSString *)inTitle
{
	if (inTitle) {
		[statusDict setObject:inTitle
					   forKey:STATUS_TITLE];
	} else {
		[statusDict removeObjectForKey:STATUS_TITLE];
	}
}

/*!
 * @brief The general status type
 *
 * @result An AIStatusType broadly indicating the type of state
 */
- (AIStatusType)statusType
{
	return [[statusDict objectForKey:STATUS_STATUS_TYPE] intValue];
}

/*!
 * @brief Set the general status type
 *
 * @param statusType An AIStatusType broadly indicating the type of state
 */
- (void)setStatusType:(AIStatusType)statusType
{
	[statusDict setObject:[NSNumber numberWithInt:statusType]
				   forKey:STATUS_STATUS_TYPE];
}

/*!
 * @brief The specific status name
 *
 * This is a name which was added as available by one or more installed AIService objects. Accounts should
 * use this name if possible, handle the other Adium default statusName values if not, and then, if all else fails
 * use the return of statusType to know the general type of status.
 */
- (NSString *)statusName
{
	return [statusDict objectForKey:STATUS_STATUS_NAME];
}

/*!
 * @brief Set the specific status name
 *
 * Set the name which will be used by accounts to know which specific state to apply when this status is made active.
 * This name is for internal use only and should not be localized.
 */
- (void)setStatusName:(NSString *)statusName
{
	if (statusName) {
		[statusDict setObject:statusName
					   forKey:STATUS_STATUS_NAME];
	} else {
		[statusDict removeObjectForKey:statusName];
	}
}

/*!
 * @brief Should this state force an account to be idle?
 *
 * @result YES if the account will be forced to be idle
 */
- (BOOL)shouldForceInitialIdleTime
{
	return [[statusDict objectForKey:STATUS_SHOULD_FORCE_INITIAL_IDLE_TIME] boolValue];	
}

/*!
 * @brief Set if this state should force an account to be idle?
 *
 * @param shouldForceInitialIdle YES if the account will be forced to be idle
 */- (void)setShouldForceInitialIdleTime:(BOOL)shouldForceInitialIdleTime
{
	[statusDict setObject:[NSNumber numberWithBool:shouldForceInitialIdleTime]
				   forKey:STATUS_SHOULD_FORCE_INITIAL_IDLE_TIME];
}

/*!
 * @brief The time the account should be set to have been idle when this state is set
 *
 * @result Number of seconds idle 
 */
- (double)forcedInitialIdleTime
{
	return [[statusDict objectForKey:STATUS_FORCED_INITIAL_IDLE_TIME] doubleValue];
}

/*!
 * @brief The time the account should be set to have been idle when this state is set
 *
 * @param forcedInitialIdleTime Number of seconds idle 
 */
- (void)setForcedInitialIdleTime:(double)forcedInitialIdleTime
{
	[statusDict setObject:[NSNumber numberWithDouble:forcedInitialIdleTime]
				   forKey:STATUS_FORCED_INITIAL_IDLE_TIME];
}

/*!
 * @brief Is this status state mutable?
 *
 * If this method indicates the status state is not mutable,  it should not be presented to the user for editing. 
 * This should be the condition for (and only for) basic saved states built in to Adium.
 *
 * @result AIStateMutabilityType value
 */
- (AIStatusMutabilityType)mutabilityType
{
	return [[statusDict objectForKey:STATUS_MUTABILITY_TYPE] intValue];
}

/*!
 * @brief Set the mutability type of this status. The default is AIEditableState
 */
- (void)setMutabilityType:(AIStatusMutabilityType)mutabilityType
{
	[statusDict setObject:[NSNumber numberWithInt:mutabilityType]
				   forKey:STATUS_MUTABILITY_TYPE];
}

/*!
 * @brief Return a unique ID for this status
 *
 * The unique ID will be assigned if necessary.
 */
- (NSNumber *)uniqueStatusID
{
	NSNumber	*uniqueStatusID = [statusDict objectForKey:STATUS_UNIQUE_ID];
	if (!uniqueStatusID) {
		uniqueStatusID = [[adium statusController] nextUniqueStatusID];
		[self setUniqueStatusID:uniqueStatusID];
	}
	
	return uniqueStatusID;
}

/*!
 * @brief Return the unique status ID for this status as an integer
 *
 * The unique ID will not be assigned if necessary. -1 is returned if no unique ID has been assigned previously.
 */
- (int)preexistingUniqueStatusID
{
	NSNumber	*uniqueStatusID = [statusDict objectForKey:STATUS_UNIQUE_ID];

	return uniqueStatusID ? [uniqueStatusID intValue] : -1;
}

- (void)setUniqueStatusID:(NSNumber *)inUniqueStatusID
{
	if (inUniqueStatusID) {
		[statusDict setObject:inUniqueStatusID
					   forKey:STATUS_UNIQUE_ID];		
	} else {
		[statusDict removeObjectForKey:STATUS_UNIQUE_ID];
	}
	
	[[adium statusController] statusStateDidSetUniqueStatusID];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %x [%@]>",
		NSStringFromClass([self class]),
		self,
		[[self title] stringWithEllipsisByTruncatingToLength:20]];
}

#pragma mark Applescript
- (AIStatusTypeApplescript)statusTypeApplescript
{
	AIStatusType			statusType = [self statusType];
	AIStatusTypeApplescript statusTypeApplescript;
	
	switch (statusType) {
		case AIAvailableStatusType: statusTypeApplescript = AIAvailableStatusTypeAS; break;
		case AIAwayStatusType: statusTypeApplescript = AIAwayStatusTypeAS; break;
		case AIInvisibleStatusType: statusTypeApplescript = AIInvisibleStatusTypeAS; break;
		case AIOfflineStatusType:
		default:
			statusTypeApplescript = AIOfflineStatusTypeAS; break;
	}
	
	return statusTypeApplescript;
}

- (void)setStatusTypeApplescript:(AIStatusTypeApplescript)statusTypeApplescript
{
	AIStatusType			statusType;
	
	switch (statusTypeApplescript) {
		case AIAvailableStatusTypeAS: statusType = AIAvailableStatusType; break;
		case AIAwayStatusTypeAS: statusType = AIAwayStatusType; break;
		case AIInvisibleStatusTypeAS: statusType = AIInvisibleStatusType; break;
		case AIOfflineStatusTypeAS:
		default:
			statusType = AIOfflineStatusType; break;
	}
	
	[self setStatusType:statusType];
}

@end
