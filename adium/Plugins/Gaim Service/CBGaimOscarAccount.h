/*
 *  CBGaimOscarAccount.h
 *  Adium XCode
 *
 *  Created by Colin Barrett on Thu Nov 06 2003.
 *
 */

#import "CBGaimAccount.h"
#import "aim.h"

@interface CBGaimOscarAccount : CBGaimAccount <AIAccount_Files,AIAccount_Privacy>
{
	NSMutableArray		*delayedUpdateTimers;
}

//Overriden from CBGaimAccount
//- (void)accountUpdateBuddy:(GaimBuddy*)buddy;
- (NSArray *)supportedPropertyKeys;

extern gchar *oscar_encoding_to_utf8(const char *encoding, char *text, int textlen);
extern GaimXfer *oscar_xfer_new(GaimConnection *gc, const char *destsn);
/*
	extern void oscar_xfer_init(GaimXfer *xfer);
	extern void oscar_xfer_start(GaimXfer *xfer);
	extern void oscar_xfer_end(GaimXfer *xfer);
	extern void oscar_xfer_cancel_send(GaimXfer *xfer);
	extern void oscar_xfer_cancel_recv(GaimXfer *xfer);
	extern void oscar_xfer_ack(GaimXfer *xfer, const char *buffer, size_t size);
*/
@end
