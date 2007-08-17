//
//  adiumPurpleAccounts.m
//  Adium
//
//  Created by Evan Schoenberg on 12/3/06.
//

#import "adiumPurpleAccounts.h"
#import <Adium/AIContactControllerProtocol.h>

static NSMutableSet *authRequests = nil;

/* A buddy we already have added us to their buddy list. */
static void adiumPurpleAccountNotifyAdded(PurpleAccount *account, const char *remote_user,
							 const char *id, const char *alias,
							 const char *message)
{
	
}

static void adiumPurpleAccountStatusChanged(PurpleAccount *account, PurpleStatus *status)
{
	
}

/* Someone we don't have on our list added us. Will prompt to add them. */
static void adiumPurpleAccountRequestAdd(PurpleAccount *account, const char *remote_user,
					const char *accountID, const char *alias,
					const char *message)
{
#warning Something is better than nothing, but we should display a message which includes message and alias
	/* purple displays something like "Add remote_user to your list? remote_user (alias) has made accountID his buddy." */
	[accountLookup(account) requestAddContactWithUID:[NSString stringWithUTF8String:remote_user]];
}

/*
 * @brief A contact requests authorization to add us to her list
 *
 * @param account PurpleAccount being added
 * @param remote_user The UID of the contact
 * @param anId May be NULL; an ID associated with the authorization request (?)
 * @param alias The contact's alias. May be NULL.
 * @param mess A message accompanying the request. May be NULL.
 * @param authorize_cb Call if authorization granted
 * @param deny_cb Call if authroization denied
 * @param user_data Data for the process; be sure to return it in the callback
 */
static void *adiumPurpleAccountRequestAuthorize(PurpleAccount *account, const char *remote_user, const char *anId,
										const char *alias, const char *message, 
										gboolean on_list, PurpleAccountRequestAuthorizationCb authorize_cb, PurpleAccountRequestAuthorizationCb deny_cb,
										void *user_data)
{
	NSMutableDictionary	*infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithUTF8String:remote_user], @"Remote Name",
		[NSValue valueWithPointer:authorize_cb], @"authorizeCB",
		[NSValue valueWithPointer:deny_cb], @"denyCB",
		[NSValue valueWithPointer:user_data], @"userData",
		nil];
	
	if (message && strlen(message)) [infoDict setObject:[NSString stringWithUTF8String:message] forKey:@"Reason"];
	
	id authRequestWindow = [accountLookup(account) authorizationRequestWithDict:infoDict];
	
	if(authRequestWindow) {
		if (!authRequests) authRequests = [[NSMutableSet alloc] init];
		[authRequests addObject:authRequestWindow];
	}
	
	return authRequestWindow;
}

static void adiumPurpleAccountRequestClose(void *ui_handle)
{
	id	ourHandle = (id)ui_handle;

	if ([ourHandle respondsToSelector:@selector(purpleRequestClose)]) {
		[ourHandle performSelector:@selector(purpleRequestClose)];
		
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

void adiumPurpleAccountRegisterCb(PurpleAccount *account, gboolean succeeded, void *user_data) {
	id ourHandle = user_data;
	
	if([ourHandle respondsToSelector:@selector(purpleAccountRegistered:)])
		[ourHandle purpleAccountRegistered:(succeeded ? YES : NO)];
}

static PurpleAccountUiOps adiumPurpleAccountOps = {
	&adiumPurpleAccountNotifyAdded,
	&adiumPurpleAccountStatusChanged,
	&adiumPurpleAccountRequestAdd,
	&adiumPurpleAccountRequestAuthorize,
	&adiumPurpleAccountRequestClose
};

PurpleAccountUiOps *adium_purple_accounts_get_ui_ops(void)
{
	return &adiumPurpleAccountOps;
}
