/*
 *  CBGaimOscarAccount.h
 *  Adium
 *
 *  Created by Colin Barrett on Thu Nov 06 2003.
 *
 */

#import "CBGaimAccount.h"
//#import "aim.h"

@interface CBGaimOscarAccount : CBGaimAccount <AIAccount_Files,AIAccount_Privacy>
{

}

extern gchar *oscar_encoding_to_utf8(const char *encoding, char *text, int textlen);
extern GaimXfer *oscar_xfer_new(GaimConnection *gc, const char *destsn);

@end
