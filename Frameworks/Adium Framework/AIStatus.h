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

#import "AIObject.h"

//Keys used for storage and retrieval
#define	STATE_STATUS_MESSAGE				@"Status Message"
#define	STATE_HAS_AUTO_REPLY				@"Has AutoReply"
#define	STATE_AUTO_REPLY_IS_STATUS_MESSAGE	@"AutoReply is Status Message"
#define	STATE_AUTO_REPLY_MESSAGE			@"AutoReply Message"
#define	STATE_TITLE							@"Title"
#define	STATE_STATUS_TYPE					@"Status Type"
#define	STATE_STATUS_NAME					@"Status Name"
#define STATE_SHOULD_FORCE_INITIAL_IDLE_TIME @"Should Force Initial Idle Time"
#define	STATE_FORCED_INITIAL_IDLE_TIME		@"Forced Initial Idle Time"
#define STATE_INVISIBLE						@"Invisible"
#define STATE_MUTABILITY_TYPE				@"Mutability Type"

//Mutability types
typedef enum {
	AIEditableState = 0, /* A user created state which can be modified -- the default, should be 0 */
	AILockedState /* A state which is built into Adium and can not be modified */
} AIStateMutabilityType;

//General status types
typedef enum {
	AIAvailableStatusType = 0, /* Must be first in the enum */
	AIAwayStatusType
} AIStatusType;
#define STATUS_TYPES_COUNT 2

@interface AIStatus : AIObject<NSCoding> {
	NSMutableDictionary	*statusDict;
}

+ (AIStatus *)status;
+ (AIStatus *)statusWithDictionary:(NSDictionary *)inDictionary;

- (NSImage *)icon;

- (NSAttributedString *)statusMessage;
- (void)setStatusMessage:(NSAttributedString *)statusMessage;
- (void)setStatusMessageData:(NSData *)statusMessageData;

- (NSAttributedString *)autoReply;
- (void)setAutoReply:(NSAttributedString *)autoReply;
- (void)setAutoReplyData:(NSData *)autoReplyData;

- (BOOL)hasAutoReply;
- (void)setHasAutoReply:(BOOL)hasAutoReply;
- (BOOL)autoReplyIsStatusMessage;
- (void)setAutoReplyIsStatusMessage:(BOOL)autoReplyIsStatusMessage;

- (NSString *)title;
- (void)setTitle:(NSString *)inTitle;

- (AIStatusType)statusType;
- (void)setStatusType:(AIStatusType)statusType;

- (NSString *)statusName;
- (void)setStatusName:(NSString *)statusName;

- (BOOL)shouldForceInitialIdleTime;
- (void)setShouldForceInitialIdleTime:(BOOL)shouldForceInitialIdleTime;
- (double)forcedInitialIdleTime;
- (void)setForcedInitialIdleTime:(double)forcedInitialIdleTime;

- (BOOL)invisible;
- (void)setInvisible:(BOOL)invisible;

- (AIStateMutabilityType)mutabilityType;
- (void)setMutabilityType:(AIStateMutabilityType)mutabilityType;

@end
