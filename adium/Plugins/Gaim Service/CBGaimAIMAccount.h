//
//  CBGaimAIMAccount.h
//  Adium XCode
//
//  Created by Colin Barrett on Sat Nov 01 2003.
//

#import "CBGaimAccount.h"
#import "aim.h"

@interface CBGaimAIMAccount : CBGaimAccount {

}

//Overriden from CBGAimAccount
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)UIDAndServiceID;
- (NSString *)accountDescription;
- (void)accountBlistUpdate:(GaimBuddyList *)list withNode:(GaimBlistNode *)node;
- (NSArray *)supportedPropertyKeys;

//- (void)accountBlistNewNode:(GaimBlistNode *)node;

extern gchar *oscar_encoding_to_utf8(const char *encoding, char *text, int textlen);

@end
