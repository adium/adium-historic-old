//
//  ESGaimMSNAccount.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//

#import "ESGaimMSNAccount.h"

#define KEY_MSN_HOST	@"MSN:Host"
#define KEY_MSN_PORT	@"MSN:Port"

@interface ESGaimMSNAccount (PRIVATE)
-(void)_setFriendlyNameTo:(NSString *)inAlias;
@end

@implementation ESGaimMSNAccount

static BOOL didInitMSN = NO;

- (const char*)protocolPlugin
{
	[super initSSL];
	if (!didInitMSN) didInitMSN = gaim_init_msn_plugin();
    return "prpl-msn";
}

#pragma mark Connection
- (void)createNewGaimAccount
{
	[super createNewGaimAccount];
	
	BOOL HTTPConnect = [[self preferenceForKey:KEY_MSN_HTTP_CONNECT_METHOD group:GROUP_ACCOUNT_STATUS] boolValue];
	gaim_account_set_bool(account, "http_method", HTTPConnect);
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 2:
			return AILocalizedString(@"Syncing with server",nil);
			break;			
		case 3:
			return AILocalizedString(@"Requesting to send password",nil);
			break;
		case 4:
			return AILocalizedString(@"Syncing with server",nil);
			break;
		case 5:
			return AILocalizedString(@"Requesting to send password",nil);
			break;
		case 6:
			return AILocalizedString(@"Password sent",nil);
			break;
		case 7:
			return AILocalizedString(@"Retrieving buddy list",nil);
			break;
			
	}
	return nil;
}

- (NSString *)hostKey
{
	return KEY_MSN_HOST;
}
- (NSString *)portKey
{
	return KEY_MSN_PORT;
}

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	if (disconnectionError){
		//Remove "signed on from another location" check for libgaim 0.77
		/*if (([disconnectionError rangeOfString:@"signed on from another location"].location != NSNotFound)) {
			return NO;
		}else */if (([disconnectionError rangeOfString:@"Type your e-mail address and password correctly"].location != NSNotFound)) {
			[[adium accountController] forgetPasswordForAccount:self];
		}
	}
	
	return YES;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	NSLog(@"I'm sending %@",[AIHTMLDecoder encodeHTML:inAttributedString
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

#pragma mark Status
//Update our status
- (void)updateStatusForKey:(NSString *)key
{    
	[super updateStatusForKey:key];
	
    //Now look at keys which only make sense while online
	if([[self statusObjectForKey:@"Online"] boolValue]){
		if([key compare:@"FullName"] == 0){
			[self updateStatusString:[self preferenceForKey:key group:GROUP_ACCOUNT_STATUS] forKey:@"FullName"];
		}
	}
}

- (void)setStatusString:(NSString *)inString forKey:(NSString *)key
{
	if([key compare:@"FullName"] == 0){
		[self _setFriendlyNameTo:inString];
	}
}

-(void)_setFriendlyNameTo:(NSString *)inAlias
{
 	if (gc && account) 
 		msn_set_friendly_name(gc,[inAlias UTF8String]);
}

//Update all our status keys
- (void)updateAllStatusKeys
{
	[super updateAllStatusKeys];
	[self updateStatusForKey:@"FullName"];
}

/*
 //Added to msn.c
//**ADIUM
void msn_set_friendly_name(GaimConnection *gc, const char *entry)
{
	msn_act_id(gc, entry);
}
*/
 
@end

