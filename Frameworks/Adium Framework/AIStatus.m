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
#import <AIUtilities/AIAttributedStringAdditions.h>

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
	
	return(newStatus);
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

	return(status); 
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
	
	return(status);
}

/*!
 * @brief Initialize
 */
- (id)init
{
	if(self = [super init]){
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

	return status;
}

/*!
 * @brief Encode with Coder
 */
- (void)encodeWithCoder:(NSCoder *)encoder
{
	if([encoder allowsKeyedCoding]){
        [encoder encodeObject:statusDict forKey:@"AIStatusDict"];

    }else{
        [encoder encodeObject:statusDict];
    }
}

/*!
 * @brief Initialize with coder
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];

    if ([decoder allowsKeyedCoding]){
        // Can decode keys in any order		
        statusDict = [[decoder decodeObjectForKey:@"AIStatusDict"] mutableCopy];
		
    }else{
        // Must decode keys in same order as encodeWithCoder:		
        statusDict = [[decoder decodeObject] mutableCopy];
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
 * @result An <tt>NSImage</tt>
 */ 
- (NSImage *)icon
{
	NSString	*statusID;

	if([self shouldForceInitialIdleTime]){
		statusID = @"idle";
	}else{
		switch([self statusType])
		{
			case AIAvailableStatusType:
				statusID = @"available";
				break;			
			case AIAwayStatusType:
				statusID = @"away";
				break;
		}
	}

	return([AIStatusIcons statusIconForStatusID:statusID type:AIStatusIconList direction:AIIconNormal]);
}

/*!
 * @brief The status message for this status
 *
 * @result An NSAttributedString status message, or nil if no status message or a 0-length status message is set
 */
- (NSAttributedString *)statusMessage
{
	NSAttributedString	*statusMessage = nil;
	NSData				*statusMessageData;
	
	if(statusMessageData = [statusDict objectForKey:STATUS_STATUS_MESSAGE]){
		statusMessage = [NSAttributedString stringWithData:statusMessageData];
	}
	
	if(statusMessage && ([statusMessage length] == 0)){
		statusMessage = nil;
	}
	
	return statusMessage;
}

/*!
 * @brief Set the status message
 */
- (void)setStatusMessage:(NSAttributedString *)statusMessage
{
	if(statusMessage){
		[statusDict setObject:[statusMessage dataRepresentation]
					   forKey:STATUS_STATUS_MESSAGE];
	}else{
		[statusDict removeObjectForKey:STATUS_STATUS_MESSAGE];
	}
}

/*!
 * @brief Set the status message data
 */
- (void)setStatusMessageData:(NSData *)statusMessageData
{
	if(statusMessageData){
		[statusDict setObject:statusMessageData
					   forKey:STATUS_STATUS_MESSAGE];
	}else{
		[statusDict removeObjectForKey:STATUS_STATUS_MESSAGE];
	}
}

/*!
 * @brief The auto reply to send when in this status
 *
 * @result An NSAttributedString auto reply, or nil if no auto reply should be sent
 */
- (NSAttributedString *)autoReply
{
	NSAttributedString	*autoReply = nil;

	if([self hasAutoReply]){
		if([self autoReplyIsStatusMessage]){
			autoReply = [self statusMessage];
		}else{
			NSData				*autoReplyData;

			if(autoReplyData = [statusDict objectForKey:STATUS_AUTO_REPLY_MESSAGE]){
				autoReply = [NSAttributedString stringWithData:autoReplyData];				
			}
		}
	}

	if(autoReply && ([autoReply length] == 0)){
		autoReply = nil;
	}
	
	return autoReply;
}

/*!
 * @brief Set the autoReply
 */
- (void)setAutoReply:(NSAttributedString *)autoReply
{
	if(autoReply){
		[statusDict setObject:[autoReply dataRepresentation]
					   forKey:STATUS_AUTO_REPLY_MESSAGE];
	}else{
		[statusDict removeObjectForKey:STATUS_AUTO_REPLY_MESSAGE];
	}
}

/*!
 * @brief Set the autReply data
 */
- (void)setAutoReplyData:(NSData *)autoReplyData
{
	if(autoReplyData){
		[statusDict setObject:autoReplyData
					   forKey:STATUS_AUTO_REPLY_MESSAGE];
	}else{
		[statusDict removeObjectForKey:STATUS_AUTO_REPLY_MESSAGE];
	}
}

/*!
 * @brief Does this status state send an autoReeply?
 */
- (BOOL)hasAutoReply
{
	return([[statusDict objectForKey:STATUS_HAS_AUTO_REPLY] boolValue]);
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
	return([[statusDict objectForKey:STATUS_AUTO_REPLY_IS_STATUS_MESSAGE] boolValue]);
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

	//If the state has a title, we simply use it
	if(!title){
		NSString *string = [statusDict objectForKey:STATUS_TITLE];
		if(string && [string length]) title = string;
	}

	//If the state has a status message, use it.
	if(!title && 
	   (statusMessage = [self statusMessage]) &&
	   ([statusMessage length])){
		title = [statusMessage string];
	}

	//If the state has an autoreply (but no status message), use it.
	if(!title &&
	   (autoReply = [self autoReply]) &&
	   ([autoReply length])){
		title = [autoReply string];
	}
	
	//If the state is an away state, use the description of the away state
	if(!title &&
	   ([self statusType] == AIAwayStatusType)){
		title = [[adium statusController] descriptionForStateOfStatus:self];
	}
	
	//If the state is simply idle, use the string "Idle"
	if(!title && [self shouldForceInitialIdleTime]){
		title = AILocalizedString(@"Idle",nil);
	}
	
	//If the state is simply invisible, use the string "Invisible"
	if(!title && [self invisible]){
		title = AILocalizedString(@"Invisible",nil);
	}
	
	//If the state is none of the above, use the string "Available"
	if(!title) title = AILocalizedString(@"Available",nil);
	
	return(title);
}

/*!
 * @brief Set the title
 */
- (void)setTitle:(NSString *)inTitle
{
	if(inTitle){
		[statusDict setObject:inTitle
					   forKey:STATUS_TITLE];
	}else{
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
	return([[statusDict objectForKey:STATUS_STATUS_TYPE] intValue]);
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
	return([statusDict objectForKey:STATUS_STATUS_NAME]);
}

/*!
 * @brief Set the specific status name
 *
 * Set the name which will be used by accounts to know which specific state to apply when this status is made active.
 * This name is for internal use only and should not be localized.
 */
- (void)setStatusName:(NSString *)statusName
{
	if(statusName){
		[statusDict setObject:statusName
					   forKey:STATUS_STATUS_NAME];
	}else{
		[statusDict removeObjectForKey:statusName];
	}
}

//XXX
- (BOOL)shouldForceInitialIdleTime
{
	return([[statusDict objectForKey:STATUS_SHOULD_FORCE_INITIAL_IDLE_TIME] boolValue]);	
}
//XXX
- (void)setShouldForceInitialIdleTime:(BOOL)shouldForceInitialIdleTime
{
	[statusDict setObject:[NSNumber numberWithBool:shouldForceInitialIdleTime]
				   forKey:STATUS_SHOULD_FORCE_INITIAL_IDLE_TIME];
}
//XXX
- (double)forcedInitialIdleTime
{
	return([[statusDict objectForKey:STATUS_FORCED_INITIAL_IDLE_TIME] doubleValue]);
}
//XXX
- (void)setForcedInitialIdleTime:(double)forcedInitialIdleTime
{
	[statusDict setObject:[NSNumber numberWithDouble:forcedInitialIdleTime]
				   forKey:STATUS_FORCED_INITIAL_IDLE_TIME];
}

/*!
 * @brief Is this an invisible status?
 */
- (BOOL)invisible
{
	return([[statusDict objectForKey:STATUS_INVISIBLE] boolValue]);
}

/*!
 * @brief Set if this is an invisible status
 *
 * This is treated independently of the status name/status type, even though for many protocols
 * it will superceded whatever status is set.  This is to allow a status to be specified both to be
 * invisible where possible and to also be a specific state (e.g. Away with the message "No Purple Dinosaurs!")
 * for those protocols which don't support invisible.
 */
- (void)setInvisible:(BOOL)invisible
{
	[statusDict setObject:[NSNumber numberWithBool:invisible]
				   forKey:STATUS_INVISIBLE];
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
	return([[statusDict objectForKey:STATUS_MUTABILITY_TYPE] intValue]);
}

/*!
 * @brief Set the mutability type of this status. The default is AIEditableState
 */
- (void)setMutabilityType:(AIStatusMutabilityType)mutabilityType
{
	[statusDict setObject:[NSNumber numberWithInt:mutabilityType]
				   forKey:STATUS_MUTABILITY_TYPE];
}

+ (NSImage *)statusIconForStatusType:(AIStatusType)inStatusType
{
	NSString	*statusID;
	
	switch(inStatusType)
	{
		case AIAvailableStatusType:
			statusID = @"available";
			break;			
		case AIAwayStatusType:
			statusID = @"away";
			break;
	}

	return([AIStatusIcons statusIconForStatusID:statusID type:AIStatusIconList direction:AIIconNormal]);
}

- (NSString *)description
{
	return([NSString stringWithFormat:@"%@ : %@",[super description], statusDict]);
}

@end
