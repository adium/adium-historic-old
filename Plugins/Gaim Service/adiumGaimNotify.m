//
//  adiumGaimNotify.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimNotify.h"
#import "ESGaimNotifyEmailController.h"

static void *adiumGaimNotifyMessage(GaimNotifyMsgType type, const char *title, const char *primary, const char *secondary, GCallback cb,void *userData)
{
    //Values passed can be null
    GaimDebug (@"adiumGaimNotifyMessage: %s: %s, %s", title, primary, secondary);
	return ([[SLGaimCocoaAdapter sharedInstance] handleNotifyMessageOfType:type
																 withTitle:title
																   primary:primary
																 secondary:secondary]);
}

static void *adiumGaimNotifyEmails(size_t count, gboolean detailed, const char **subjects, const char **froms, const char **tos, const char **urls, GCallback cb,void *userData)
{
    //Values passed can be null
    return([ESGaimNotifyEmailController handleNotifyEmails:count 
												  detailed:detailed
												  subjects:subjects
													 froms:froms
													   tos:tos
													  urls:urls]);
}

static void *adiumGaimNotifyEmail(const char *subject, const char *from, const char *to, const char *url, GCallback cb,void *userData)
{
	return(adiumGaimNotifyEmails(1,
								 TRUE,
								 (subject ? &subject : NULL),
								 (from ? &from : NULL),
								 (to ? &to : NULL),
								 (url ? &url : NULL),
								 cb, userData));
}

static void *adiumGaimNotifyFormatted(const char *title, const char *primary, const char *secondary, const char *text, GCallback cb,void *userData)
{
    return(adium_gaim_get_handle());
}

static void *adiumGaimNotifyUserinfo(GaimConnection *gc, const char *who, const char *title, const char *primary, const char *secondary, const char *text, GCallback cb,void *userData)
{
	//	NSLog(@"%s - %s: %s\n%s\n%s\n%s",gc->account->username,who,title,primary, secondary, text);
	//	NSString	*titleString = [NSString stringWithUTF8String:title];
	//	NSString	*primaryString = [NSString stringWithUTF8String:primary];
	//	NSString	*secondaryString = [NSString stringWithUTF8String:secondary];
	NSString	*textString = [NSString stringWithUTF8String:text];
	
	if (GAIM_CONNECTION_IS_VALID(gc)){
		GaimAccount		*account = gc->account;
		GaimBuddy		*buddy = gaim_find_buddy(account,who);
		AIListContact   *theContact = contactLookupFromBuddy(buddy);
		
		
		[accountLookup(account) mainPerformSelector:@selector(updateUserInfo:withData:)
										 withObject:theContact
										 withObject:textString];
	}
	
    return(adium_gaim_get_handle());
}

static void *adiumGaimNotifyUri(const char *uri)
{
	if (uri){
		NSURL   *notifyURI = [NSURL URLWithString:[NSString stringWithUTF8String:uri]];
		[[NSWorkspace sharedWorkspace] openURL:notifyURI];
	}
	
	return(adium_gaim_get_handle());
}

static void adiumGaimNotifyClose(GaimNotifyType type,void *uiHandle)
{
	GaimDebug (@"adiumGaimNotifyClose");
}

static GaimNotifyUiOps adiumGaimNotifyOps = {
    adiumGaimNotifyMessage,
    adiumGaimNotifyEmail,
    adiumGaimNotifyEmails,
    adiumGaimNotifyFormatted,
	adiumGaimNotifyUserinfo,
    adiumGaimNotifyUri,
    adiumGaimNotifyClose
};

GaimNotifyUiOps *adium_gaim_notify_get_ui_ops(void)
{
	return &adiumGaimNotifyOps;
}
