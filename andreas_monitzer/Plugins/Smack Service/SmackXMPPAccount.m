//
//  SmackXMPPAccount.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPAccount.h"


@implementation SmackXMPPAccount

- (void)initAccount {
	[super initAccount];
}

- (void)connect {
    [super connect];
}

- (void)disconnect {
    [super disconnect];
}

- (void)performRegisterWithPassword:(NSString *)inPassword {
    [super performReigsterWithPassword:inPassword];
}

- (NSString *)accountWillSetUID:(NSString *)proposedUID {
	return [super accountWillSetUID:proposedUID];
}

- (void)didChangeUID {
    [super didChangeUID];
}

- (void)willBeDeleted {
    [super willBeDeleted];
}

- (NSString *)explicitFormattedUID {
	return [super explicitFormattedUID];
}

#pragma mark Properties

- (BOOL)shouldSendAutoresponsesWhileAway {
	return NO;
}

- (BOOL)disconnectOnFastUserSwitch {
	return NO;
}

- (BOOL)connectivityBasedOnNetworkReachability {
	return YES;
}

- (BOOL)suppressTypingNotificationChangesAfterSend {
	return NO;
}

- (BOOL)supportsOfflineMessaging {
	return YES;
}

- (BOOL)allowsNewlinesInMessages {
	return YES;
}

/*- (BOOL)supportsFolderTransfer {
	return NO;
}*/

#pragma mark Status

- (NSSet *)supportedPropertyKeys {
	static	NSSet	*supportedPropertyKeys = nil;
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSSet alloc] initWithObjects:
			@"Online",
			@"FormattedUID",
			KEY_ACCOUNT_DISPLAY_NAME,
			@"Display Name",
			@"StatusState",
			KEY_USER_ICON,
			@"Enabled",
            @"TextProfile",
            @"DefaultUserIconFilename",
			nil];
	}
    
	return supportedPropertyKeys;
}

- (void)delayedUpdateContactStatus:(AIListContact *)inContact {
    [super delayedUpdateContactStatus:inContact];
}

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage {
}


#pragma mark Messaging, Chatting, Strings

- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact {
    return NO;
}

- (BOOL)openChat:(AIChat *)chat {
    return YES;
}

- (BOOL)closeChat:(AIChat *)chat {
    return YES;
}

- (BOOL)inviteContact:(AIListObject *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage {
    return NO;
}

- (BOOL)joinGroupChatNamed:(NSString *)name {
    return NO;
}

- (BOOL)sendTypingObject:(AIContentTyping *)inTypingObject {
    return YES;
}

- (BOOL)sendMessageObject:(AIContentMessage *)inMessageObject {
	return NO;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject {
    return [super encodedAttributedString:inAttributedString forListObject:inListObject];
}

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage {
    return [super encodedAttributedStringForSendingContentMessage:inContentMessage];
}

#pragma mark Presence Tracking

- (BOOL)contactListEditable {
	return YES;
}

- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)group {
    
}

- (void)removeContacts:(NSArray *)objects {
    
}

- (void)deleteGroup:(AIListGroup *)group {
    
}

- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group {
    
}

- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName {
    
}

- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    return [super menuItemsForContact:inContact];
}

- (NSArray *)accountActionMenuItems {
    return [super accountActionMenuItems];
}

#pragma mark Secure messsaging

- (BOOL)allowSecureMessagingTogglingForChat:(AIChat *)inChat
{
	return [super allowSecureMessagingTogglingForChat:inChat];
}

- (void)authorizationWindowController:(NSWindowController *)inWindowController authorizationWithDict:(NSDictionary *)infoDict didAuthorize:(BOOL)inDidAuthorize {
}

@end
