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
#define	STATUS_STATUS_MESSAGE				@"Status Message NSAttributedString"
#define	STATUS_HAS_AUTO_REPLY				@"Has AutoReply"
#define	STATUS_AUTO_REPLY_IS_STATUS_MESSAGE	@"AutoReply is Status Message"
#define	STATUS_AUTO_REPLY_MESSAGE			@"AutoReply Message NSAttributedString"
#define	STATUS_TITLE						@"Title"
#define	STATUS_STATUS_TYPE					@"Status Type"
#define	STATUS_STATUS_NAME					@"Status Name"
#define STATUS_SHOULD_FORCE_INITIAL_IDLE_TIME @"Should Force Initial Idle Time"
#define	STATUS_FORCED_INITIAL_IDLE_TIME		@"Forced Initial Idle Time"
#define STATUS_INVISIBLE					@"Invisible"
#define STATUS_MUTABILITY_TYPE				@"Mutability Type"
#define STATUS_UNIQUE_ID					@"Unique ID"

//Mutability types
typedef enum {
	AIEditableStatusState = 0, /* A user created state which can be modified -- the default, should be 0 */
	AILockedStatusState, /* A state which is built into Adium and can not be modified */
	AITemporaryEditableStatusState, /* A user created state which is not part of the permanent stored state array */
	AISecondaryLockedStatusState /* A state which is managed by Adium and grouped separately from other states of the same type */
} AIStatusMutabilityType;

//General status types
typedef enum {
	AIAvailableStatusType = 0, /* Must be first in the enum */
	AIAwayStatusType,
	AIInvisibleStatusType,
	AIOfflineStatusType
} AIStatusType;
#define STATUS_TYPES_COUNT 4

typedef enum {
	AIAvailableStatusTypeAS = 'avaL',
	AIAwayStatusTypeAS = 'awaY',
	AIInvisibleStatusTypeAS = 'aSaI',
	AIOfflineStatusTypeAS = 'offL'
} AIStatusTypeApplescript;

@interface AIStatus : AIObject<NSCoding> {
	NSMutableDictionary	*statusDict;
}

+ (AIStatus *)status;
+ (AIStatus *)statusWithDictionary:(NSDictionary *)inDictionary;
+ (AIStatus *)statusOfType:(AIStatusType)inStatusType;

- (NSImage *)menuIcon;
- (NSImage *)icon;

- (NSAttributedString *)statusMessage;
- (void)setStatusMessage:(NSAttributedString *)statusMessage;

- (NSString *)statusMessageString;
- (void)setStatusMessageString:(NSString *)statusMessageString;

- (NSAttributedString *)autoReply;
- (void)setAutoReply:(NSAttributedString *)autoReply;

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

- (AIStatusMutabilityType)mutabilityType;
- (void)setMutabilityType:(AIStatusMutabilityType)mutabilityType;

- (NSNumber *)uniqueStatusID;
- (int)preexistingUniqueStatusID;
- (void)setUniqueStatusID:(NSNumber *)inUniqueStatusID;

#pragma mark Applescript
- (AIStatusTypeApplescript)statusTypeApplescript;
- (void)setStatusTypeApplescript:(AIStatusTypeApplescript)statusTypeApplescript;

@end
