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

@interface CBGaimOscarAccount : CBGaimAccount <AIAccount_Files>
{

}

//Overriden from CBGaimAccount
- (void)accountUpdateBuddy:(GaimBuddy*)buddy;
- (NSArray *)supportedPropertyKeys;

extern gchar *oscar_encoding_to_utf8(const char *encoding, char *text, int textlen);

@end
