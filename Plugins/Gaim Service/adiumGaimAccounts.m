//
//  adiumGaimAccounts.m
//  Adium
//
//  Created by Evan Schoenberg on 12/3/06.
//

#import "adiumGaimAccounts.h"
#import <Adium/AIContactControllerProtocol.h>

static NSMutableSet *authRequests = nil;

/* A buddy we already have added us to their buddy list. */
static void adiumGaimAccountNotifyAdded(GaimAccount *account, const char *remote_user,
							 const char *id, const char *alias,
							 const char *message)
{
	
}

static void adiumGaimAccountStatusChanged(GaimAccount *account, GaimStatus *status)
{
	
}

/* Someone we don't have on our list added us. Will prompt to add them. */
static void adiumGaimAccountRequestAdd(GaimAccount *account, const char *remote_user,
					const char *accountID, const char *alias,
					const char *message)
{
#warning Something is better than nothing, but we should display a message which includes message and alias
	/* gaim displays something like "Add remote_user to your list? remote_user (alias) has made accountID his buddy." */
	[accountLookup(account) requestAddContactWithUID:[NSString stringWithUTF8String:remote_user]];
}

/*
 * @brief A contact requests authorization to add us to her list
 *
 * @param account GaimAccount being added
 * @param remote_user The UID of the contact
 * @param anId May be NULL; an ID associated with the authorization request (?)
 * @param alias The contact's alias. May be NULL.
 * @param mess A message accompanying the request. May be NULL.
 * @param authorize_cb Call if authorization granted
 * @param deny_cb Call if authroization denied
 * @param user_data Data for the process; be sure to return it in the callback
 */
static void *adiumGaimAccountRequestAuthorize(GaimAccount *account, const char *remote_user, const char *anId,
									   const char *alias, const char *message, 
									   gboolean on_list, GCallback authorize_cb, GCallback deny_cb, void *user_data)
{
	NSMutableDictionary	*infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:remote_user], @"Remote Name",
		[NSValue valueWithPointer:authorize_cb], @"authorizeCB",
		[NSValue valueWithPointer:deny_cb], @"denyCB",
		[NSValue valueWithPointer:user_data], @"userData",
		nil];
	
	if (message && strlen(message)) [infoDict setObject:[NSString stringWithUTF8String:message] forKey:@"Reason"];
	
	id authRequestWindow = [[[AIObject sharedAdiumInstance] contactController] showAuthorizationRequestWithDict:infoDict
																									 forAccount:accountLookup(account)];
	if (!authRequests) authRequests = [[NSMutableSet alloc] init];
	[authRequests addObject:authRequestWindow];
	
	return authRequestWindow;
}

static void adiumGaimAccountRequestClose(void *ui_handle)
{
	id	ourHandle = (id)ui_handle;

	if ([ourHandle respondsToSelector:@selector(gaimRequestClose)]) {
		[ourHandle performSelector:@selector(gaimRequestClose)];
		
	} else if ([ourHandle respondsToSelector:@selector(closeWindow:)]) {
		[ourHandle performSelector:@selector(closeWindow:)
						withObject:nil];
	}
	
	[authRequests removeObject:(id)ui_handle];
	if (![authRequests count]) {
		[authRequests release];
		authRequests = nil;
	}
}

static GaimAccountUiOps adiumGaimAccountOps = {
	&adiumGaimAccountNotifyAdded,
	&adiumGaimAccountStatusChanged,
	&adiumGaimAccountRequestAdd,
	&adiumGaimAccountRequestAuthorize,
	&adiumGaimAccountRequestClose
};

GaimAccountUiOps *adium_gaim_accounts_get_ui_ops(void)
{
	return &adiumGaimAccountOps;
}
