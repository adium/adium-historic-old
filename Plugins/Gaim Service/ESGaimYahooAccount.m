/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIAccountController.h"
#import "AIStatusController.h"
#import "ESGaimYahooAccount.h"
#import "ESGaimYahooAccountViewController.h"
#import "SLGaimCocoaAdapter.h"
#import <AIUtilities/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatus.h>
#import <Adium/ESFileTransfer.h>
#import <Libgaim/yahoo.h>
#import <Libgaim/yahoo_filexfer.h>
#import <Libgaim/yahoo_friend.h>

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
	[super initAccount];

	if (!presetStatusesDictionary){
		presetStatusesDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
			STATUS_DESCRIPTION_BRB,				[NSNumber numberWithInt:YAHOO_STATUS_BRB],
			STATUS_DESCRIPTION_BUSY,			[NSNumber numberWithInt:YAHOO_STATUS_BUSY],
			STATUS_DESCRIPTION_NOT_AT_HOME,		[NSNumber numberWithInt:YAHOO_STATUS_NOTATHOME],
			STATUS_DESCRIPTION_NOT_AT_DESK,		[NSNumber numberWithInt:YAHOO_STATUS_NOTATDESK],
			STATUS_DESCRIPTION_NOT_IN_OFFICE,	[NSNumber numberWithInt:YAHOO_STATUS_NOTINOFFICE],
			STATUS_DESCRIPTION_PHONE,			[NSNumber numberWithInt:YAHOO_STATUS_ONPHONE],
			STATUS_DESCRIPTION_VACATION,		[NSNumber numberWithInt:YAHOO_STATUS_ONVACATION],
			STATUS_DESCRIPTION_LUNCH,			[NSNumber numberWithInt:YAHOO_STATUS_OUTTOLUNCH],
			STATUS_DESCRIPTION_STEPPED_OUT,		[NSNumber numberWithInt:YAHOO_STATUS_STEPPEDOUT],
			AILocalizedString(@"Invisible",nil),[NSNumber numberWithInt:YAHOO_STATUS_INVISIBLE],nil] retain];
	}
}

- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys){
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"AvailableMessage",
			@"Invisible",
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
	
	return supportedPropertyKeys;
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
	BOOL shouldAttemptReconnect = YES;
	
	if (disconnectionError){
		if ([disconnectionError rangeOfString:@"Incorrect password"].location != NSNotFound) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if ([disconnectionError rangeOfString:@"logged in on a different machine or device"].location != NSNotFound) {
			shouldAttemptReconnect = NO;
		}
	}
	
	return shouldAttemptReconnect;
}

#pragma mark Encoding
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{	
	if (inListObject){
		return([AIHTMLDecoder encodeHTML:inAttributedString
								 headers:NO
								fontTags:YES
					  includingColorTags:YES
						   closeFontTags:YES
							   styleTags:YES
			  closeStyleTagsOnFontChange:YES
						  encodeNonASCII:NO
							encodeSpaces:NO
							  imagesPath:nil
					   attachmentsAsText:YES
		  attachmentImagesOnlyForSending:NO
						  simpleTagsOnly:YES
						  bodyBackground:NO]);
	}else{
		return [inAttributedString string];
	}
}

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)){
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];
		
		return yahoo_xfer_new(account->gc,destsn);
	}
	
	return nil;
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

#pragma mark Status Messages
- (void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
	SEL updateSelector = nil;
	
	switch ([event intValue]){
		case GAIM_BUDDY_STATUS_MESSAGE: {
			updateSelector = @selector(updateStatusMessage:);
			break;
		}
	}
	
	if (updateSelector){
		[self performSelector:updateSelector
				   withObject:theContact];
	}
	
	[super updateContact:theContact forEvent:event];
}

- (void)updateStatusMessage:(AIListContact *)theContact
{
	struct yahoo_data   *od;
	YahooFriend *f;

	const char				*buddyName = [[theContact UID] UTF8String];
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(f = g_hash_table_lookup(od->friends, buddyName))) {
		
		NSString		*statusMsgString = nil;
		NSString		*oldStatusMsgString = [theContact statusObjectForKey:@"StatusMessageString"];
		
		if (f->status == YAHOO_STATUS_IDLE){
			/*
			 //Now idle
			 int		idle = f->idle;
			 NSDate	*idleSince;
			 
			 NSLog(@"%@ YAHOO_STATUS_IDLE %i (%d)",[theContact UID],idle,idle);
			 
			 if (idle != -1){
				 idleSince = [NSDate dateWithTimeIntervalSinceNow:-idle];
				 NSLog(@"So that's %i minutes ago",([[NSDate date] timeIntervalSinceDate:idleSince]/60));
			 }else{
				 idleSince = [NSDate date];
			 }
			 
			 [theContact setStatusObject:idleSince
								  forKey:@"IdleSince"
								  notify:NO];
			 */
			
		}else{
			if (f->msg != NULL) {
				statusMsgString = [NSString stringWithUTF8String:f->msg];
				
				//Ensure the away/not away for a cusotm message is handled properly by double checking here.
				[self _updateAwayOfContact:theContact 
									toAway:(f->status != YAHOO_STATUS_AVAILABLE)];

			} else if (f->status != YAHOO_STATUS_AVAILABLE) {
				statusMsgString = [presetStatusesDictionary objectForKey:[NSNumber numberWithInt:f->status]];
			}
		}
		
		if (statusMsgString && [statusMsgString length]) {
			if (![statusMsgString isEqualToString:oldStatusMsgString]) {
				NSAttributedString *attrStr;
				
				attrStr = [[NSAttributedString alloc] initWithString:statusMsgString];
				
				[theContact setStatusObject:statusMsgString forKey:@"StatusMessageString" notify:NO];
				[theContact setStatusObject:attrStr forKey:@"StatusMessage" notify:NO];
				
				[attrStr release];
			}
			
		} else if (oldStatusMsgString && [oldStatusMsgString length]) {
			//If we had a message before, remove it
			[theContact setStatusObject:nil forKey:@"StatusMessageString" notify:NO];
			[theContact setStatusObject:nil forKey:@"StatusMessage" notify:NO];
		}
		
		//apply changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}

/*
 * @brief Return the gaim status type to be used for a status
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status equivalent
 * @param statusMessage A pointer to the statusMessage.  Set *statusMessage to nil if it should not be used directly for this status.
 *
 * @result The gaim status equivalent
 */
#warning msn invisible = "Hidden"
- (char *)gaimStatusTypeForStatus:(AIStatus *)statusState
						  message:(NSAttributedString **)statusMessage
{
	NSString		*statusName = [statusState statusName];
	AIStatusType	statusType = [statusState statusType];
	char			*gaimStatusType = NULL;
	
	switch(statusType){
		case AIAvailableStatusType:
		{
			if([statusName isEqualToString:STATUS_NAME_AVAILABLE])
				gaimStatusType = "Available";
			break;
		}
			
		case AIAwayStatusType:
		{
			if ([statusName isEqualToString:STATUS_NAME_BRB])
				gaimStatusType = "Be Right Back";
			else if ([statusName isEqualToString:STATUS_NAME_BUSY])
				gaimStatusType = "Busy";
			else if ([statusName isEqualToString:STATUS_NAME_NOT_AT_HOME])
				gaimStatusType = "Not At Home";
			else if ([statusName isEqualToString:STATUS_NAME_NOT_AT_DESK])
				gaimStatusType = "Not At Desk";
			else if ([statusName isEqualToString:STATUS_NAME_PHONE])
				gaimStatusType = "On The Phone";
			else if ([statusName isEqualToString:STATUS_NAME_VACATION])
				gaimStatusType = "On Vacation";
			else if ([statusName isEqualToString:STATUS_NAME_LUNCH])
				gaimStatusType = "Out To Lunch";
			else if ([statusName isEqualToString:STATUS_NAME_STEPPED_OUT])
				gaimStatusType = "Stepped Out";

			break;
		}
	}
	
	//If we are setting one of our custom statuses, clear a @"" statusMessage to nil
	if((gaimStatusType != NULL) && ([*statusMessage length])) *statusMessage = nil;
	
	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if(strcmp(label, "Add Buddy") == 0){
		//We handle Add Buddy ourselves
		return(nil);
	}else if(strcmp(label, "Join in Chat") == 0){
		return([NSString stringWithFormat:AILocalizedString(@"Join %@'s Chat",nil),[inContact formattedUID]]);
	}else if(strcmp(label, "Initiate Conference") == 0){
		return([NSString stringWithFormat:AILocalizedString(@"Initiate Conference with %@",nil), [inContact formattedUID]]);
	}

	return([super titleForContactMenuLabel:label forContact:inContact]);
}

@end
