//
//  RAFjoscarAccount.h
//  Adium
//
//  Created by Augie Fackler on 11/21/05.
//

#import <Adium/AIAccount.h>
#import "ESjoscarCocoaAdapter.h"

#define KEY_DISPLAY_RECENT_BUDDIES	@"Display Recent Buddies"
@protocol ChatInvitation;

@interface RAFjoscarAccount : AIAccount <AIAccount_Privacy> {
	ESjoscarCocoaAdapter	*joscarAdapter;
	NSMutableDictionary		*fileTransferDict;
	
	BOOL					inSignOnDelay;
}

- (NSString *)serversideUID;
- (AIListContact *)contactWithUID:(NSString *)inUID;

- (void)contactWithUID:(NSString *)inUID setStatusMessage:(NSString *)statusMessage;
- (void)contactWithUID:(NSString *)inUID setProfile:(NSString *)profile;
- (void)contactWithUID:(NSString *)inUID
		  formattedUID:(NSString *)inFormattedUID
			  isOnline:(BOOL)isOnline
				isAway:(BOOL)isAway
			 idleSince:(NSDate *)idleSince
		   onlineSince:(NSDate *)onlineSince
		  warningLevel:(int)warningLevel
				mobile:(BOOL)inMobile
			   aolUser:(BOOL)inAolUser;
- (void)contactWithUID:(NSString *)inUID
			  isOnline:(NSNumber *)isOnline;
- (void)contactWithUID:(NSString *)inUID removedFromGroup:(NSString *)groupName;
- (void)contactWithUID:(NSString *)inUID changedToAlias:(NSString *)alias;
- (void)contactWithUID:(NSString *)inUID changedToBuddyComment:(NSString *)comment;
- (void)contactWithUID:(NSString *)inUID iconUpdate:(NSData *)iconData;

- (void)chatWithUID:(NSString *)inUID receivedMessage:(NSString *)inHTML isAutoreply:(NSNumber *)isAutoreply;
- (void)chatWithUID:(NSString *)inUID receivedDirectMessage:(NSString *)inHTML isAutoreply:(NSNumber *)isAutoreply joscarData:(id)joscarData;
- (void)chatWithUID:(NSString *)inUID gotTypingState:(NSNumber *)typingState;
- (void)chatWithUID:(NSString *)inUID setDirectIMConnected:(BOOL)isConnected;

- (void)newIncomingFileTransferWithUID:(NSString *)inUID
							  fileName:(NSString *)fileName
							  fileSize:(NSNumber *)fileSize
							identifier:(NSValue *)identifier;
- (void)updateFileTransferWithIdentifier:(NSValue *)identifier toFileTransferStatus:(NSNumber *)fileTransferStatusNumber;
- (void)updateFileTransferWithIdentifier:(NSValue *)identifier toPosition:(NSNumber *)positionNumber;

- (void)setAccountProfileTo:(NSAttributedString *)profile;
- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage;
- (void)setAccountIdleSinceTo:(NSDate *)idleSince;
- (void)setAccountUserIconData:(NSData *)imageData;
- (void)setListContact:(AIListContact *)listContact toAlias:(NSString *)inAlias;- (void)contactWithUID:(NSString *)inUID
		  formattedUID:(NSString *)formattedUID
				 alias:(NSString *)alias
			   comment:(NSString *)comment
		  addedToGroup:(NSString *)groupName;

- (void)stateChangedTo:(NSString *)newState
	 errorMessageShort:(NSString *)errorMessageShort 
			 errorCode:(NSString *)errorCode;

- (void)inviteToChat:(NSString *)name fromContact:(NSString *)uid withMessage:(NSString *)message inviteObject:(id)invite;

- (void)gotMessage:(NSString *)message onGroupChatNamed:(NSString *)name fromUID:(NSString *)uid;
- (AIChat *)mainThreadChatWithName:(NSString *)name;
- (void)chatFailed:(NSString *)name;
- (void)objectsLeftChat:(NSArray *)objects chatName:(NSString *)name;
- (void)objectsJoinedChat:(NSArray *)objects chatName:(NSString *)name;
- (void)addChat:(AIChat *)chat;

- (NSString *)getSecurid;

- (void)chatWithUID:(NSString *)inUID gotError:(NSNumber *)errorType;

@end
