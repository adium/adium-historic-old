//
//  AIService.h
//  Adium
//
//  Created by Adam Iser on 8/24/04.
//

#import <Cocoa/Cocoa.h>

@class AIAccountViewController, DCJoinChatViewController;

//Service importance, used to group and order services
typedef enum {
	AIServicePrimary,
	AIServiceSecondary,
	AIServiceUnsupported
} AIServiceImportance;

@interface AIService : AIObject {

}

//Account Creation
- (id)accountWithUID:(NSString *)inUID accountNumber:(int)inAccountNumber;
- (Class)accountClass;
- (AIAccountViewController *)accountView;
- (DCJoinChatViewController *)joinChatView;

//Service Description
- (NSString *)serviceCodeUniqueID;
- (NSString *)serviceID;
- (NSString *)serviceClass;
- (NSString *)shortDescription;
- (NSString *)longDescription;
- (NSCharacterSet *)allowedCharacters;
- (NSCharacterSet *)allowedCharactersForUIDs;
- (NSCharacterSet *)allowedCharactersForAccountName;
- (NSCharacterSet *)ignoredCharacters;
- (int)allowedLength;
- (int)allowedLengthForUIDs;
- (int)allowedLengthForAccountName;
- (BOOL)caseSensitive;
- (AIServiceImportance)serviceImportance;

//Utilities
- (NSString *)filterUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored;

//Attributes
- (BOOL)canCreateGroupChats;
- (BOOL)canRegisterNewAccounts;

@end
