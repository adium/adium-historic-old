//
//  AIStatus.m
//  Adium
//
//  Created by Evan Schoenberg on 2/3/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIStatus.h"


@implementation AIStatus

/*
 * @brief Create an autoreleased AIStatus
 *
 * @result New autoreleased AIStatus
 */
+ (AIStatus *)status
{
	return([[[self alloc] init] autorelease]);
}

/*
 * @brief Crate an AIStatus from a dictionary
 *
 * @param inDictionary A dictionary of keys to use as the new AIStatus's statusDict
 * @result AIStatus from inDictionary
 */
+ (AIStatus *)statusWithDictionary:(NSDictionary *)inDictionary
{
	AIStatus	*status = [[[self alloc] init] autorelease];
	[status->statusDict addEntriesFromDictionary:inDictionary];

	return(status); 
}

/*
 * @brief Initialize
 *
 * Objective C has no multiple inheritance, so emulate inheriting from AIObject by setting our adium variable manually.
 */
- (id)init
{
	if(self = [super init]){
		statusDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/*
 * @brief Copy
 */
- (id)copyWithZone:(NSZone *)zone
{
	AIStatus	*status = [[[self class] allocWithZone:zone] init];

	[status->statusDict release];
	status->statusDict = [statusDict copy];

	return status;
}

/*
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

/*
 * @brief Initialize with coder
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];

    if ([decoder allowsKeyedCoding]){
        // Can decode keys in any order		
        statusDict = [[decoder decodeObjectForKey:@"AIStatusDict"] retain];
		
    }else{
        // Must decode keys in same order as encodeWithCoder:		
        statusDict = [[decoder decodeObject] retain];
    }
	
	return self;
}

/*
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
	
	switch([self statusType])
	{
		case AIAvailableStatusType:
			statusID = @"available";
			break;			
		case AIAwayStatusType:
			statusID = @"away";
			break;
	}/*else if([self isIdleState]){
		statusID = @"idle";
	}*/

	return([AIStatusIcons statusIconForStatusID:statusID type:AIStatusIconList direction:AIIconNormal]);
}

/*
 * @brief The status message for this status
 *
 * @result An NSAttributedString status message, or nil if no status message or a 0-length status message is set
 */
- (NSAttributedString *)statusMessage
{
	NSAttributedString	*statusMessage = nil;
	NSData				*statusMessageData;
	
	if(statusMessageData = [statusDict objectForKey:STATE_STATUS_MESSAGE]){
		statusMessage = [NSAttributedString stringWithData:statusMessageData];
	}
	
	if(statusMessage && ([statusMessage length] == 0)){
		statusMessage = nil;
	}
	
	return statusMessage;
}

/*
 * @brief Set the status message
 */
- (void)setStatusMessage:(NSAttributedString *)statusMessage
{
	if(statusMessage){
		[statusDict setObject:[statusMessage dataRepresentation]
					   forKey:STATE_STATUS_MESSAGE];
	}else{
		[statusDict removeObjectForKey:STATE_STATUS_MESSAGE];
	}
}

/*
 * @brief Set the status message data
 */
- (void)setStatusMessageData:(NSData *)statusMessageData
{
	if(statusMessageData){
		[statusDict setObject:statusMessageData
					   forKey:STATE_STATUS_MESSAGE];
	}else{
		[statusDict removeObjectForKey:STATE_STATUS_MESSAGE];
	}
}

/*
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

			if(autoReplyData = [statusDict objectForKey:STATE_AUTO_REPLY_MESSAGE]){
				autoReply = [NSAttributedString stringWithData:autoReplyData];				
			}
		}
	}

	if(autoReply && ([autoReply length] == 0)){
		autoReply = nil;
	}
	
	return autoReply;
}

/*
 * @brief Set the autoReply
 */
- (void)setAutoReply:(NSAttributedString *)autoReply
{
	if(autoReply){
		[statusDict setObject:[autoReply dataRepresentation]
					   forKey:STATE_AUTO_REPLY_MESSAGE];
	}else{
		[statusDict removeObjectForKey:STATE_AUTO_REPLY_MESSAGE];
	}
}

/*
 * @brief Set the autReply data
 */
- (void)setAutoReplyData:(NSData *)autoReplyData
{
	if(autoReplyData){
		[statusDict setObject:autoReplyData
					   forKey:STATE_AUTO_REPLY_MESSAGE];
	}else{
		[statusDict removeObjectForKey:STATE_AUTO_REPLY_MESSAGE];
	}
}

/*
 * @brief Does this status state send an autoReeply?
 */
- (BOOL)hasAutoReply
{
	return([[statusDict objectForKey:STATE_HAS_AUTO_REPLY] boolValue]);
}

/*
 * @brief Set if this status sends an autoReply
 */
- (void)setHasAutoReply:(BOOL)hasAutoReply
{
	[statusDict setObject:[NSNumber numberWithBool:hasAutoReply]
				   forKey:STATE_HAS_AUTO_REPLY];
}

/*
 * @brief Is the autoReply the same as the status message?
 */
- (BOOL)autoReplyIsStatusMessage
{
	return([[statusDict objectForKey:STATE_AUTO_REPLY_IS_STATUS_MESSAGE] boolValue]);
}

/*
 * @brief Set if the autoReply is the same as the status message
 */
- (void)setAutoReplyIsStatusMessage:(BOOL)autoReplyIsStatusMessage
{
	[statusDict setObject:[NSNumber numberWithBool:autoReplyIsStatusMessage]
				   forKey:STATE_AUTO_REPLY_IS_STATUS_MESSAGE];
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
		NSString *string = [statusDict objectForKey:STATE_TITLE];
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
		
		[[adium statusController] descriptionForStateOfStatus:self];
	}
	
	//If the state is simply idle, use the string "Idle"
	if(!title && [self forcedInitialIdleTime]){
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

/*
 * @brief Set the title
 */
- (void)setTitle:(NSString *)inTitle
{
	if(inTitle){
		[statusDict setObject:inTitle
					   forKey:STATE_TITLE];
	}else{
		[statusDict removeObjectForKey:STATE_TITLE];
	}
}

/*
 * @brief The general status type
 *
 * @result An AIStatusType broadly indicating the type of state
 */
- (AIStatusType)statusType
{
	return([[statusDict objectForKey:STATE_STATUS_TYPE] intValue]);
}

/*
 * @brief Set the general status type
 *
 * @param statusType An AIStatusType broadly indicating the type of state
 */
- (void)setStatusType:(AIStatusType)statusType
{
	[statusDict setObject:[NSNumber numberWithInt:statusType]
				   forKey:STATE_STATUS_TYPE];
}

/*
 * @brief The specific status name
 *
 * This is a name which was added as available by one or more installed AIService objects. Accounts should
 * use this name if possible, handle the other Adium default statusName values if not, and then, if all else fails
 * use the return of statusType to know the general type of status.
 */
- (NSString *)statusName
{
	return([statusDict objectForKey:STATE_STATUS_NAME]);
}

/*
 * @brief Set the specific status name
 *
 * Set the name which will be used by accounts to know which specific state to apply when this status is made active.
 * This name is for internal use only and should not be localized.
 */
- (void)setStatusName:(NSString *)statusName
{
	if(statusName){
		[statusDict setObject:statusName
					   forKey:STATE_STATUS_NAME];
	}else{
		[statusDict removeObjectForKey:statusName];
	}
}

//XXX
- (BOOL)shouldForceInitialIdleTime
{
	return([[statusDict objectForKey:STATE_SHOULD_FORCE_INITIAL_IDLE_TIME] boolValue]);	
}
//XXX
- (void)setShouldForceInitialIdleTime:(BOOL)shouldForceInitialIdleTime
{
	[statusDict setObject:[NSNumber numberWithBool:shouldForceInitialIdleTime]
				   forKey:STATE_SHOULD_FORCE_INITIAL_IDLE_TIME];
}
//XXX
- (double)forcedInitialIdleTime
{
	return([[statusDict objectForKey:STATE_FORCED_INITIAL_IDLE_TIME] doubleValue]);
}
//XXX
- (void)setForcedInitialIdleTime:(double)forcedInitialIdleTime
{
	[statusDict setObject:[NSNumber numberWithDouble:forcedInitialIdleTime]
				   forKey:STATE_FORCED_INITIAL_IDLE_TIME];
}

/*
 * @brief Is this an invisible status?
 */
- (BOOL)invisible
{
	return([[statusDict objectForKey:STATE_INVISIBLE] boolValue]);
}

/*
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
				   forKey:STATE_INVISIBLE];
}

/*
 * @brief Is this state mutable?
 *
 * If this method indicates the state is not mutable,  it should not be presented to the user for editing. This should be the 
 * condition for (and only for) basic saved states built in to Adium.
 *
 * @result AIStateMutabilityType value
 */
- (AIStateMutabilityType)mutabilityType
{
	return([[statusDict objectForKey:STATE_MUTABILITY_TYPE] intValue]);
}

/*
 * @brief Set the mutability type of this status. The default is AIEditableState
 */
- (void)setMutabilityTpye:(AIStateMutabilityType)mutabilityType
{
	[statusDict setObject:[NSNumber numberWithInt:mutabilityType]
				   forKey:STATE_MUTABILITY_TYPE];
}

@end
