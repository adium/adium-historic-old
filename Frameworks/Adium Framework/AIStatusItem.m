//
//  AIStatusItem.m
//  Adium
//
//  Created by Evan Schoenberg on 11/23/05.
//

#import "AIStatusItem.h"
#import "AIStatusIcons.h"
#import "AIStatusController.h"
#import <AIUtilities/AIStringAdditions.h>

@implementation AIStatusItem

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
	AIStatusItem *miniMe = [[[self class] alloc] init];
	
	[miniMe->statusDict release];
	miniMe->statusDict = [statusDict mutableCopy];
	
	//Clear the unique ID for this new status, since it should not share our ID.
	[miniMe->statusDict removeObjectForKey:STATUS_UNIQUE_ID];
	
	return miniMe;
}

/*!
* @brief Encode with Coder
 */
- (void)encodeWithCoder:(NSCoder *)encoder
{
	encoding = YES;

	//Ensure we have a unique status ID before encoding. We set encoding = YES so it won't trigger further saving/encoding.
	[self uniqueStatusID];
	
	if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:statusDict forKey:@"AIStatusDict"];
		
    } else {
        [encoder encodeObject:statusDict];
    }
	
	encoding = NO;
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

- (NSString *)title
{	
	NSString *title = [statusDict objectForKey:STATUS_TITLE];
	
	return ([title length] ? title : nil);
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
	NSNumber *statusType = [statusDict objectForKey:STATUS_STATUS_TYPE];

	return (statusType ? [statusType intValue] : AIAwayStatusType);
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

- (AIStatusMutabilityType)mutabilityType
{
	return AIEditableStatusState;
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
	AIStatusType	statusType;
	
	statusType = [self statusType];
	
	return [AIStatusIcons statusIconForStatusName:nil
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

#pragma mark Unique status ID

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
	
	if (!encoding) {
		[[adium statusController] statusStateDidSetUniqueStatusID];
	}
}

- (AIStatusGroup *)containingStatusGroup
{
	return containingStatusGroup;
}

- (void)setContainingStatusGroup:(AIStatusGroup *)inStatusGroup
{
	if (containingStatusGroup != inStatusGroup) {
		[containingStatusGroup release];
		containingStatusGroup = [inStatusGroup retain];
	}
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
