//
//  ESGaimYahooAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimYahooAccountViewController.h"
#import "ESGaimYahooAccount.h"

#import <Libgaim/yahoo_filexfer.h>
#include <Libgaim/yahoo.h>

#define KEY_YAHOO_HOST  @"Yahoo:Host"
#define KEY_YAHOO_PORT  @"Yahoo:Port"

@implementation ESGaimYahooAccount

static BOOL				didInitYahoo = NO;
static NSDictionary		*presetStatusesDictionary = nil;

- (const char*)protocolPlugin
{
	if (!didInitYahoo) didInitYahoo = gaim_init_yahoo_plugin();
    return "prpl-yahoo";
}

- (void)initAccount
{
	if (!presetStatusesDictionary){
		presetStatusesDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
			AILocalizedString(@"Be Right Back",nil),	[NSNumber numberWithInt:YAHOO_STATUS_BRB],
			AILocalizedString(@"Busy",nil),				[NSNumber numberWithInt:YAHOO_STATUS_BUSY],
			AILocalizedString(@"Not At Home",nil),		[NSNumber numberWithInt:YAHOO_STATUS_NOTATHOME],
			AILocalizedString(@"Not At My Desk",nil),   [NSNumber numberWithInt:YAHOO_STATUS_NOTATDESK],
			AILocalizedString(@"Not In The Office",nil),[NSNumber numberWithInt:YAHOO_STATUS_NOTINOFFICE],
			AILocalizedString(@"On The Phone",nil),		[NSNumber numberWithInt:YAHOO_STATUS_ONPHONE],
			AILocalizedString(@"On Vacation",nil),		[NSNumber numberWithInt:YAHOO_STATUS_ONVACATION],
			AILocalizedString(@"Out To Lunch",nil),		[NSNumber numberWithInt:YAHOO_STATUS_OUTTOLUNCH],
			AILocalizedString(@"Stepped Out",nil),		[NSNumber numberWithInt:YAHOO_STATUS_STEPPEDOUT],
			AILocalizedString(@"Invisible",nil),		[NSNumber numberWithInt:YAHOO_STATUS_INVISIBLE],
			AILocalizedString(@"Idle",nil),				[NSNumber numberWithInt:YAHOO_STATUS_IDLE],
			AILocalizedString(@"Offline",nil),			[NSNumber numberWithInt:YAHOO_STATUS_OFFLINE],nil] retain];
	}
}

#pragma mark Connection
- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
	}
	return nil;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	if (disconnectionError && ([disconnectionError rangeOfString:@"Incorrect password"].location != NSNotFound)) {
		[[adium accountController] forgetPasswordForAccount:self];
	}
		
	return YES;
}

- (NSString *)hostKey
{
	return KEY_YAHOO_HOST;
}

- (NSString *)portKey
{
	return KEY_YAHOO_PORT;
}

#pragma mark Encoding
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{	
	return([AIHTMLDecoder encodeHTML:inAttributedString
							 headers:NO
							fontTags:YES
				  includingColorTags:YES
					   closeFontTags:YES
						   styleTags:YES
		  closeStyleTagsOnFontChange:YES
					  encodeNonASCII:NO
						  imagesPath:nil
				   attachmentsAsText:YES
						  simpleTagsOnly:YES]);
}

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
	
	return yahoo_xfer_new(gc,destsn);
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}


#pragma mark Status Messages
- (void)updateContact:(AIListContact *)theContact forEvent:(GaimBuddyEvent) event
{
	[super updateContact:theContact forEvent:event];
	
	SEL updateSelector = nil;
	
	switch (event){
		case GAIM_BUDDY_STATUS_MESSAGE: {
			updateSelector = @selector(updateStatusMessage:);
			break;
		}
	}
	
	if (updateSelector){
		[self performSelector:updateSelector
				   withObject:theContact];
	}
}

- (void)updateStatusMessage:(AIListContact *)theContact
{
	struct yahoo_data   *od;
	struct yahoo_friend *userInfo;
	GaimBuddy			*buddy;

	const char				*buddyName = [[theContact UID] UTF8String];
	
	if ((od = gc->proto_data) &&
		(userInfo = g_hash_table_lookup(od->friends, buddyName))) {
		
		NSString		*statusMsgString = nil;
		NSString		*oldStatusMsgString = [theContact statusObjectForKey:@"StatusMessageString"];
		
		if (userInfo != NULL){
			if (userInfo->msg != NULL) {
				//<muse>if it is, why is status custom??</muse>
				statusMsgString = [NSString stringWithUTF8String:userInfo->msg];
			} else if (userInfo->status != YAHOO_STATUS_AVAILABLE) {
				statusMsgString = [presetStatusesDictionary objectForKey:[NSNumber numberWithInt:userInfo->status]];
			}
			
			if (statusMsgString && [statusMsgString length]) {
				if (![statusMsgString isEqualToString:oldStatusMsgString]) {
					NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString:statusMsgString] autorelease];
					
					[theContact setStatusObject:statusMsgString forKey:@"StatusMessageString" notify:NO];
					[theContact setStatusObject:attrStr forKey:@"StatusMessage" notify:NO];
					
					//apply changes
					[theContact notifyOfChangedStatusSilently:silentAndDelayed];
				}
				
			} else if (oldStatusMsgString && [oldStatusMsgString length]) {
				//If we had a message before, remove it
				[theContact setStatusObject:nil forKey:@"StatusMessageString" notify:NO];
				[theContact setStatusObject:nil forKey:@"StatusMessage" notify:NO];
				
				//apply changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];
			}
		}
	}
}

@end
