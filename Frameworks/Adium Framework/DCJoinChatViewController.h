//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

@interface DCJoinChatViewController : AIObject {
	IBOutlet		NSView			*view;			// Custom view
	AIChat							*chat;			// The newly created chat
	
	id								delegate;		// Our delegate
}

+ (DCJoinChatViewController *)joinChatView;

- (id)init;
- (NSView *)view;
- (NSString *)nibName;

- (void)configureForAccount:(AIAccount *)inAccount;
- (void)joinChatWithAccount:(AIAccount *)inAccount;

- (NSString *)impliedCompletion:(NSString *)aString;

- (void)doJoinChatWithName:(NSString *)inName
				 onAccount:(AIAccount *)inAccount
		  chatCreationInfo:(NSDictionary *)inInfo 
		  invitingContacts:(NSArray *)contactsToInvite
	 withInvitationMessage:(NSString *)invitationMessage;
- (NSArray *)contactsFromNamesSeparatedByCommas:(NSString *)namesSeparatedByCommas onAccount:(AIAccount *)inAccount;

- (void)setDelegate:(id)inDelegate;
- (id)delegate;

@end
