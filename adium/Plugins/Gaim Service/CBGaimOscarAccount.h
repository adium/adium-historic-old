/*
 *  CBGaimOscarAccount.h
 *  Adium XCode
 *
 *  Created by Colin Barrett on Thu Nov 06 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

#import "CBGaimAccount.h"
#import "aim.h"

@interface CBGaimOscarAccount : CBGaimAccount {

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
