//
//  CBGaimServicePlugin.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import <Security/Security.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "CBGaimServicePlugin.h"
#import "SLGaimCocoaAdapter.h"
#import "ESGaimRequestWindowController.h"

#import "GaimServices.h"

@interface CBGaimServicePlugin (PRIVATE)
- (NSDictionary *)getDictionaryFromKeychainForKey:(NSString *)key;
- (void)configureSignals;
@end

/*
 * Maps GaimAccount*s to CBGaimAccount*s.
 * This is necessary because the gaim people didn't put the same void *ui_data
 * in here that they put in most of their other structures. Maybe we should
 * ask them for one so we can take this out.
 */
NSMutableDictionary *_accountDict;
static CBGaimServicePlugin  *servicePluginInstance;

@implementation CBGaimServicePlugin

/*
 * Finds a CBGaimAccount* for a GaimAccount*.
 * See _accountDict.
 */
static CBGaimAccount* accountLookup(GaimAccount *acct)
{
    CBGaimAccount *ret = (CBGaimAccount*) [_accountDict objectForKey:[NSValue valueWithPointer:acct]];
    return ret;
}

#pragma mark Debug
// Debug ------------------------------------------------------------------------------------------------------
static void adiumGaimDebugPrint(GaimDebugLevel level, const char *category, const char *format, va_list args)
{
	gchar *arg_s = g_strdup_vprintf(format, args); //NSLog sometimes chokes on the passed args, so we'll use vprintf
	
	//Log error
	if(!category) category = "general"; //Category can be nil
	NSLog(@"(Debug: %s) %s", category, arg_s);
	
	g_free(arg_s);
}

static GaimDebugUiOps adiumGaimDebugOps = {
    adiumGaimDebugPrint
};

#pragma mark Connection
// Connection ------------------------------------------------------------------------------------------------------
static void adiumGaimConnConnectProgress(GaimConnection *gc, const char *text, size_t step, size_t step_count)
{
    if(GAIM_DEBUG) NSLog(@"Connecting: gc=0x%x (%s) %i / %i", gc, text, step, step_count);
	[accountLookup(gc->account) accountConnectionProgressStep:step of:step_count withText:text];
    
}

static void adiumGaimConnConnected(GaimConnection *gc)
{
    if(GAIM_DEBUG) NSLog(@"Connected: gc=%x", gc);
    [accountLookup(gc->account) accountConnectionConnected];
}

static void adiumGaimConnDisconnected(GaimConnection *gc)
{
    if(GAIM_DEBUG) NSLog(@"Disconnected: gc=%x", gc);
    if (_accountDict == nil) // if this has been destroyed, unloadPlugin has already been called
        return;
    [accountLookup(gc->account) accountConnectionDisconnected];
}

static void adiumGaimConnNotice(GaimConnection *gc, const char *text)
{
    if(GAIM_DEBUG) NSLog(@"Connection Notice: gc=%x (%s)", gc, text);
	[accountLookup(gc->account) accountConnectionNotice:text];
}

static void adiumGaimConnReportDisconnect(GaimConnection *gc, const char *text)
{
    if(GAIM_DEBUG) NSLog(@"Connection Disconnected: gc=%x (%s)", gc, text);
    [accountLookup(gc->account) accountConnectionReportDisconnect:text];
}

static GaimConnectionUiOps adiumGaimConnectionOps = {
    adiumGaimConnConnectProgress,
    adiumGaimConnConnected,
    adiumGaimConnDisconnected,
    adiumGaimConnNotice,
    adiumGaimConnReportDisconnect
};

#pragma mark Contact List
// Contact List ------------------------------------------------------------------------------------------------------
static void adiumGaimBlistNewList(GaimBuddyList *list)
{
    //We're allowed to place whatever we want in blist's ui_data.    
}

static void adiumGaimBlistNewNode(GaimBlistNode *node)
{
    NSCAssert(node != nil, @"BlistNewNode on null node");
    if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
        GaimBuddy *buddy = (GaimBuddy*) node;
        [accountLookup(buddy->account) accountNewBuddy:buddy];
    }
}

static void adiumGaimBlistShow(GaimBuddyList *list)
{
	
}

static void adiumGaimBlistUpdate(GaimBuddyList *list, GaimBlistNode *node)
{
    NSCAssert(node != nil, @"BlistUpdate on null node");

    if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
        // ui_data will be NULL if we've connected and disconnected;
        // this purges our handles but not gaim's. So look up the account.
        GaimBuddy *buddy = (GaimBuddy*) node;
        [accountLookup(buddy->account) accountUpdateBuddy:buddy];
    }
}

static void adiumGaimBlistRemove(GaimBuddyList *list, GaimBlistNode *node)
{
    NSCAssert(node != nil, @"BlistRemove on null node");
    if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
        GaimBuddy *buddy = (GaimBuddy*) node;
        [accountLookup(buddy->account) accountRemoveBuddy:buddy];
    }
}

static void adiumGaimBlistDestroy(GaimBuddyList *list)
{
    //Here we're responsible for destroying what we placed in list's ui_data earlier
    NSLog(@"adiumGaimBlistDestroy");
}

static void adiumGaimBlistSetVisible(GaimBuddyList *list, gboolean show)
{
    NSLog(@"adiumGaimBlistSetVisible: %i",show);
}

static void adiumGaimBlistRequestAddBuddy(GaimAccount *account, const char *username, const char *group, const char *alias)
{
    NSLog(@"adiumGaimBlistRequestAddBuddy");
}

static void adiumGaimBlistRequestAddChat(GaimAccount *account, GaimGroup *group, const char *alias)
{
    NSLog(@"adiumGaimBlistRequestAddChat");
}

static void adiumGaimBlistRequestAddGroup(void)
{
    NSLog(@"adiumGaimBlistRequestAddGroup");
}

static GaimBlistUiOps adiumGaimBlistOps = {
    adiumGaimBlistNewList,
    adiumGaimBlistNewNode,
    adiumGaimBlistShow,
    adiumGaimBlistUpdate,
    adiumGaimBlistRemove,
    adiumGaimBlistDestroy,
    adiumGaimBlistSetVisible,
    adiumGaimBlistRequestAddBuddy,
    adiumGaimBlistRequestAddChat,
    adiumGaimBlistRequestAddGroup
};

#pragma mark Signals
// Signals ------------------------------------------------------------------------------------------------------
static void *gaim_adium_get_handle(void)
{
	static int adium_gaim_handle;
	
	return &adium_gaim_handle;
}

static void buddy_event_cb(GaimBuddy *buddy, GaimBuddyEvent event)
{
	if (buddy)
		[accountLookup(buddy->account) accountUpdateBuddy:buddy forEvent:event];
}

- (void)configureSignals
{
	void *blist_handle = gaim_blist_get_handle();
	void *handle       = gaim_adium_get_handle();
	
	//Idle
	gaim_signal_connect(blist_handle, "buddy-idle",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_IDLE));
	gaim_signal_connect(blist_handle, "buddy-unidle",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_IDLE_RETURN));
	
	//Status
	gaim_signal_connect(blist_handle, "buddy-away",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_AWAY));
	gaim_signal_connect(blist_handle, "buddy-back",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_AWAY_RETURN));
	gaim_signal_connect(blist_handle, "buddy-status-message",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_STATUS_MESSAGE));
	
	//Info updated
	gaim_signal_connect(blist_handle, "buddy-info",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_INFO_UPDATED));
	
	//Icon
	gaim_signal_connect(blist_handle, "buddy-icon",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_ICON));
	
	//Evil
	gaim_signal_connect(blist_handle, "buddy-evil",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_EVIL));
	
	
	//Miscellaneous
	gaim_signal_connect(blist_handle, "buddy-miscellaneous",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_MISCELLANEOUS));
	
	
	gaim_signal_connect(blist_handle, "buddy-signed-on",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNON));
	gaim_signal_connect(blist_handle, "buddy-signon",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNON_TIME));
	gaim_signal_connect(blist_handle, "buddy-signed-off",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNOFF));
}

#pragma mark Conversation
// Conversation ------------------------------------------------------------------------------------------------------
static void adiumGaimConvDestroy(GaimConversation *conv)
{
    [accountLookup(conv->account) accountConvDestroy:conv];
}

static void adiumGaimConvWriteChat(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	[accountLookup(conv->account) accountConvReceivedChatMessage:message inConversation:conv from:who withFlags:flags atTime:mtime];
}

static void adiumGaimConvWriteIm(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
    [accountLookup(conv->account) accountConvReceivedIM:message inConversation:conv withFlags:flags atTime:mtime];
}

//Never actually called as of gaim 0.75
static void adiumGaimConvWriteConv(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	NSLog(@"adiumGaimConvWriteConv: %s: %s", who, message);
}

static void adiumGaimConvChatAddUser(GaimConversation *conv, const char *user)
{
	[accountLookup(conv->account) accountConvAddedUser:user inConversation:conv];
}

static void adiumGaimConvChatAddUsers(GaimConversation *conv, GList *users)
{
	[accountLookup(conv->account) accountConvAddedUsers:users inConversation:conv];
}

static void adiumGaimConvChatRenameUser(GaimConversation *conv, const char *oldName, const char *newName)
{
	if (GAIM_DEBUG) NSLog(@"adiumGaimConvChatRenameUser");
}

static void adiumGaimConvChatRemoveUser(GaimConversation *conv, const char *user)
{
	[accountLookup(conv->account) accountConvRemovedUser:user inConversation:conv];
}

static void adiumGaimConvChatRemoveUsers(GaimConversation *conv, GList *users)
{
	[accountLookup(conv->account) accountConvRemovedUsers:users inConversation:conv];
}

static void adiumGaimConvSetTitle(GaimConversation *conv, const char *title)
{
    if (GAIM_DEBUG) NSLog(@"adiumGaimConvSetTitle");
}

static void adiumGaimConvUpdateProgress(GaimConversation *conv, float percent)
{
    NSLog(@"adiumGaimConvUpdateProgress %f",percent);
}

static void adiumGaimConvUpdated(GaimConversation *conv, GaimConvUpdateType type)
{
    [accountLookup(conv->account) accountConvUpdated:conv type:type];
}

static GaimConversationUiOps adiumGaimConversationOps = {
    adiumGaimConvDestroy,
    adiumGaimConvWriteChat,
    adiumGaimConvWriteIm,
    adiumGaimConvWriteConv,
    adiumGaimConvChatAddUser,
    adiumGaimConvChatAddUsers,
    adiumGaimConvChatRenameUser,
    adiumGaimConvChatRemoveUser,
    adiumGaimConvChatRemoveUsers,
    adiumGaimConvUpdateProgress,
    adiumGaimConvUpdated
};

#pragma mark Conversation Window
// Conversation Window ---------------------------------------------------------------------------------------------
static GaimConversationUiOps *adiumGaimConvWindowGetConvUiOps()
{
    return(&adiumGaimConversationOps);
}

static void adiumGaimConvWindowNew(GaimConvWindow *win)
{
    //We can put anything we want in win's ui_data
}

static void adiumGaimConvWindowDestroy(GaimConvWindow *win)
{
    //Clean up what we placed in win's ui_data earlier
}

static void adiumGaimConvWindowShow(GaimConvWindow *win)
{
        if (GAIM_DEBUG) NSLog(@"adiumGaimConvWindowShow");
}

static void adiumGaimConvWindowHide(GaimConvWindow *win)
{
    if (GAIM_DEBUG) NSLog(@"adiumGaimConvWindowHide");
}

static void adiumGaimConvWindowRaise(GaimConvWindow *win)
{
	    if (GAIM_DEBUG) NSLog(@"adiumGaimConvWindowRaise");
}

static void adiumGaimConvWindowFlash(GaimConvWindow *win)
{
}

static void adiumGaimConvWindowSwitchConv(GaimConvWindow *win, unsigned int index)
{
    if (GAIM_DEBUG) NSLog(@"adiumGaimConvWindowSwitchConv");
}

static void adiumGaimConvWindowAddConv(GaimConvWindow *win, GaimConversation *conv)
{
	    if (GAIM_DEBUG) NSLog(@"adiumGaimConvWindowAddConv");
	//Pass chats along to the account
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){
		[accountLookup(conv->account) addChatConversation:conv];
	}
}

static void adiumGaimConvWindowRemoveConv(GaimConvWindow *win, GaimConversation *conv)
{
}

static void adiumGaimConvWindowMoveConv(GaimConvWindow *win, GaimConversation *conv, unsigned int newIndex)
{
    if (GAIM_DEBUG) NSLog(@"adiumGaimConvWindowMoveConv");
}

static int adiumGaimConvWindowGetActiveIndex(const GaimConvWindow *win)
{
    if (GAIM_DEBUG) NSLog(@"adiumGaimConvWindowGetActiveIndex");
    return(0);
}

static GaimConvWindowUiOps adiumGaimWindowOps = {
    adiumGaimConvWindowGetConvUiOps,
    adiumGaimConvWindowNew,
    adiumGaimConvWindowDestroy,
    adiumGaimConvWindowShow,
    adiumGaimConvWindowHide,
    adiumGaimConvWindowRaise,
    adiumGaimConvWindowFlash,
    adiumGaimConvWindowSwitchConv,
    adiumGaimConvWindowAddConv,
    adiumGaimConvWindowRemoveConv,
    adiumGaimConvWindowMoveConv,
    adiumGaimConvWindowGetActiveIndex
};

#pragma mark Roomlist
// Roomlist ----------------------------------------------------------------------------------------------------------
static void adiumGaimRoomlistDialogShowWithAccount(GaimAccount *account)
{
}
static void adiumGaimRoomlistNew(GaimRoomlist *list)
{
 if (GAIM_DEBUG)	NSLog(@"adiumGaimRoomlistNew");
}
static void adiumGaimRoomlistSetFields(GaimRoomlist *list, GList *fields)
{
}
static void adiumGaimRoomlistAddRoom(GaimRoomlist *list, GaimRoomlistRoom *room)
{
	 if (GAIM_DEBUG)	NSLog(@"adiumGaimRoomlistAddRoom");
}
static void adiumGaimRoomlistInProgress(GaimRoomlist *list, gboolean flag)
{
}
static void adiumGaimRoomlistDestroy(GaimRoomlist *list)
{
}

static GaimRoomlistUiOps adiumGaimRoomlistOps = {
	adiumGaimRoomlistDialogShowWithAccount,
	adiumGaimRoomlistNew,
	adiumGaimRoomlistSetFields,
	adiumGaimRoomlistAddRoom,
	adiumGaimRoomlistInProgress,
	adiumGaimRoomlistDestroy
};

#pragma mark Notify
// Notify ----------------------------------------------------------------------------------------------------------
static void *adiumGaimNotifyMessage(GaimNotifyMsgType type, const char *title, const char *primary, const char *secondary, GCallback cb, void *userData)
{
    //Values passed can be null
    NSLog(@"adiumGaimNotifyMessage: %s: %s, %s", title, primary, secondary);
	[servicePluginInstance handleNotifyMessageOfType:type withTitle:title primary:primary secondary:secondary];

    return(nil);
}

static void *adiumGaimNotifyEmail(const char *subject, const char *from, const char *to, const char *url, GCallback cb, void *userData)
{
    //Values passed can be null
    NSLog(@"adiumGaimNotifyEmail");
    return(nil);
}

static void *adiumGaimNotifyEmails(size_t count, gboolean detailed, const char **subjects, const char **froms, const char **tos, const char **urls, GCallback cb, void *userData)
{
    //Values passed can be null
    NSLog(@"adiumGaimNotifyEmails");
    return(nil);
}

static void *adiumGaimNotifyFormatted(const char *title, const char *primary, const char *secondary, const char *text, GCallback cb, void *userData)
{
	NSLog(@"adiumGaimNotifyFormatted");
    return(nil);
}

static void *adiumGaimNotifyUri(const char *uri)
{
    NSLog(@"adiumGaimNotifyUri");
    return(nil);
}

static void adiumGaimNotifyClose(GaimNotifyType type, void *uiHandle)
{
    if (GAIM_DEBUG) NSLog(@"adiumGaimNotifyClose");
}

static GaimNotifyUiOps adiumGaimNotifyOps = {
    adiumGaimNotifyMessage,
    adiumGaimNotifyEmail,
    adiumGaimNotifyEmails,
    adiumGaimNotifyFormatted,
    adiumGaimNotifyUri,
    adiumGaimNotifyClose
};

- (void)handleNotifyMessageOfType:(GaimNotifyType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;
{
    NSString *primaryString = [NSString stringWithUTF8String:primary];
	NSString *secondaryString = [NSString stringWithUTF8String:secondary];
	NSString *titleString;
	if (title){
		titleString = [NSString stringWithFormat:@"Adium Notice: %@",[NSString stringWithUTF8String:title]];
	}else{
		titleString = AILocalizedString(@"Adium : Notice", nil);
	}
	
	NSString *errorMessage = nil;
	NSString *description = nil;
			
	if ([secondaryString rangeOfString:@"Could not add the buddy 1 for an unknown reason"].location != NSNotFound){
		return;
	}
	
    if ([primaryString rangeOfString: @"Yahoo! message did not get sent."].location != NSNotFound){
		//Yahoo send error
		errorMessage = AILocalizedString(@"Your Yahoo! message did not get sent.", nil);
		
	}else if ([primaryString rangeOfString: @"did not get sent"].location != NSNotFound){
		//Oscar send error
		NSString *targetUserName = [[[[primaryString componentsSeparatedByString:@" message to "] objectAtIndex:1] componentsSeparatedByString:@" did not get "] objectAtIndex:0];
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"Your message to %@ did not get sent",nil),targetUserName];
		
		if ([secondaryString rangeOfString:@"Rate"].location != NSNotFound){
			description = AILocalizedString(@"You are sending messages too quickly; wait a moment and try again.",nil);
		}else if ([secondaryString isEqualToString:@"Service unavailable"] || [secondaryString isEqualToString:@"Not logged in"]){
			description = AILocalizedString(@"Connection error.",nil);
		}else if ([secondaryString isEqualToString:@"Refused by client"]){
			description = AILocalizedString(@"Your message was refused by the other user.",nil);
		}else if ([secondaryString isEqualToString:@"Reply too big"]){
			description = AILocalizedString(@"Your message was too big.",nil);
		}else if ([secondaryString isEqualToString:@"In local permit/deny"]){
			description = AILocalizedString(@"The other user is in your deny list.",nil);
		}else if ([secondaryString rangeOfString:@"Too evil"].location != NSNotFound){
			description = AILocalizedString(@"Warning level is too high.",nil);
		}else if ([secondaryString isEqualToString:@"User temporarily unavailable"]){
			description = AILocalizedString(@"The other user is temporarily unavailable.",nil);
		}else{
			description = AILocalizedString(@"No reason was given.",nil);
		}
		
    }else if ([primaryString rangeOfString: @"Authorization Denied"].location != NSNotFound){
		//Authorization denied; grab the user name and reason
		NSArray		*parts = [[[secondaryString componentsSeparatedByString:@" user "] objectAtIndex:1] componentsSeparatedByString:@" has denied your request to add them to your buddy list for the following reason:\n"];
		NSString	*targetUserName =  [parts objectAtIndex:0];
		NSString	*reason = ([parts count] > 1 ? [parts objectAtIndex:1] : AILocalizedString(@"(No reason given)",nil));
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ denied authorization:",nil),targetUserName];
		description = reason;

    }else if ([primaryString rangeOfString: @"Authorization Granted"].location != NSNotFound){
		//ICQ Authorization granted
		NSString *targetUserName = [[[[secondaryString componentsSeparatedByString:@" user "] objectAtIndex:1] componentsSeparatedByString:@" has "] objectAtIndex:0];
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ granted authorization.",nil),targetUserName];
	}	
		
	//If we didn't grab a translated version using AILocalizedString, at least display the English version Gaim supplied
	[[adium interfaceController] handleMessage:([errorMessage length] ? errorMessage : primaryString)
							  withDescription:([description length] ? description : ([secondaryString length] ? secondaryString : @"") )
							  withWindowTitle:titleString];
}

#pragma mark Request
// Request ------------------------------------------------------------------------------------------------------
static void *adiumGaimRequestInput(const char *title, const char *primary, const char *secondary, const char *defaultValue, gboolean multiline, gboolean masked, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb, void *userData)
{
	/*
	 Multiline should be a paragraph-sized box; otherwise, a single line will suffice.
	 Masked means we want to use an NSSecureTextField sort of thing.
	 We may receive any combination of primary and secondary text (either, both, or neither).
	 */
	
	NSString	*okButtonText = [NSString stringWithUTF8String:okText];
	NSString	*cancelButtonText = [NSString stringWithUTF8String:cancelText];

	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:okButtonText,@"OK Text",
											cancelButtonText,@"Cancel Text",
											[NSValue valueWithPointer:okCb],@"OK Callback",
											[NSValue valueWithPointer:cancelCb],@"Cancel Callback",
											[NSValue valueWithPointer:userData],@"userData",nil];
	if (title){
		[infoDict setObject:[NSString stringWithUTF8String:title] forKey:@"Title"];	
	}
	if (defaultValue){
		[infoDict setObject:[NSString stringWithUTF8String:defaultValue] forKey:@"Default Value"];
	}
	if (primary){
		[infoDict setObject:[NSString stringWithUTF8String:primary] forKey:@"Primary Text"];
	}
	if (secondary){
		[infoDict setObject:[NSString stringWithUTF8String:secondary] forKey:@"Secondary Text"];
	}
	
	[ESGaimRequestWindowController showInputWindowWithDict:infoDict multiline:multiline masked:masked];

    return(nil);
}

static void *adiumGaimRequestChoice(const char *title, const char *primary, const char *secondary, unsigned int defaultValue, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb, void *userData, size_t choiceCount, va_list choices)
{
    NSLog(@"adiumGaimRequestChoice");
    return(nil);
}

//Gaim requests the user take an action such as accept or deny a buddy's attempt to add us to her list 
static void *adiumGaimRequestAction(const char *title, const char *primary, const char *secondary, unsigned int default_action, void *userData, size_t actionCount, va_list actions)
{
	if (GAIM_DEBUG) NSLog(@"adiumGaimRequestAction");
    int		    alertReturn, i;
    //XXX evands: we can't use AILocalizedString here because there is no self (nor is there a spoon).
    /*AILocalizedString(@"Request","Title: General request from gaim")*/
    NSString	    *titleString = (title ? [NSString stringWithUTF8String:title] : @"Request");
    NSString	    *msg = [NSString stringWithFormat:@"%s%s%s",
		(primary ? primary : ""),
		((primary && secondary) ? "\n\n" : ""),
		(secondary ? secondary : "")];
    
    NSMutableArray  *buttonNamesArray = [NSMutableArray arrayWithCapacity:actionCount];
    GCallback 	    *callBacks = g_new0(GCallback, actionCount);
    
    //Generate the actions names and callbacks into useable forms
    for (i = 0; i < actionCount; i += 1) {
		//Get the name - XXX evands:need to localize!
		[buttonNamesArray addObject:[NSString stringWithUTF8String:(va_arg(actions, char *))]];
		
		//Get the callback for that name
		callBacks[i] = va_arg(actions, GCallback);
    }
    
    //Make default_action the last one
    if (default_action != -1){
		NSCAssert(default_action < actionCount, @"default_action is too big");
		int actualCount = [buttonNamesArray count];
		NSCAssert((actionCount == actualCount), @"actionCount != actualCount");
			
		GCallback tempCallBack = callBacks[actionCount-1];
		callBacks[actionCount-1] = callBacks[default_action];
		callBacks[default_action] = tempCallBack;
		
		[buttonNamesArray exchangeObjectAtIndex:default_action withObjectAtIndex:(actionCount-1)];
    }
    
    switch (actionCount)
    { 
		case 1:
			alertReturn = NSRunInformationalAlertPanel(titleString,msg,
													   [buttonNamesArray objectAtIndex:0],nil,nil);
			break;
		case 2:
			alertReturn = NSRunInformationalAlertPanel(titleString,msg,
													   [buttonNamesArray objectAtIndex:1],
													   [buttonNamesArray objectAtIndex:0],nil);
			break;
		case 3:
			alertReturn = NSRunInformationalAlertPanel(titleString,msg,
													   [buttonNamesArray objectAtIndex:2],
													   [buttonNamesArray objectAtIndex:1],
													   [buttonNamesArray objectAtIndex:0]);
			break;		    
    }
    
    //Convert the return value to an array index
    alertReturn = (alertReturn + (actionCount - 2));
	
    if (callBacks[alertReturn] != NULL){
		((GaimRequestActionCb)callBacks[alertReturn])(userData, alertReturn);
	}
    
    return(nil);
}

static void *adiumGaimRequestFields(const char *title, const char *primary, const char *secondary, GaimRequestFields *fields, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb, void *userData)
{
    NSLog(@"adiumGaimRequestFields");
    return(nil);
}

static void adiumGaimRequestClose(GaimRequestType type, void *uiHandle)
{

}

static GaimRequestUiOps adiumGaimRequestOps = {
    adiumGaimRequestInput,
    adiumGaimRequestChoice,
    adiumGaimRequestAction,
    adiumGaimRequestFields,
    adiumGaimRequestClose
};

#pragma mark File Transfer
// File Transfer ------------------------------------------------------------------------------------------------------

static void adiumGaimNewXfer(GaimXfer *xfer)
{
	NSLog(@"adiumGaimNewXfer");
}

static void adiumGaimDestroy(GaimXfer *xfer)
{
	[accountLookup(xfer->account) accountXferDestroy:xfer];
}

static void adiumGaimRequestFile(GaimXfer *xfer)
{
    GaimXferType xferType = gaim_xfer_get_type(xfer);
    if (xferType == GAIM_XFER_RECEIVE) {
        NSLog(@"File request: %s from %s on IP %s",xfer->filename,xfer->who,gaim_xfer_get_remote_ip(xfer));
        [accountLookup(xfer->account) accountXferRequestFileReceiveWithXfer:xfer];
    } else if (xferType == GAIM_XFER_SEND) {
		NSCAssert(xfer->local_filename != nil, @"adiumGaimRequestFile: Attempted to send nil file...");
		gaim_xfer_request_accepted(xfer, xfer->local_filename);
	}
}

static void adiumGaimAskCancel(GaimXfer *xfer)
{
	NSLog(@"adiumGaimAskCancel");
}

static void adiumGaimAddXfer(GaimXfer *xfer)
{
	NSLog(@"adiumGaimAddXfer");
}

static void adiumGaimUpdateProgress(GaimXfer *xfer, double percent)
{
	//   NSLog(@"transfer update: %s is now %f%% done",xfer->filename,(percent*100));
    [accountLookup(xfer->account) accountXferUpdateProgress:xfer percent:percent];
}

static void adiumGaimCancelLocal(GaimXfer *xfer)
{
	NSLog(@"adiumGaimCancelLocal");
}

static void adiumGaimCancelRemote(GaimXfer *xfer)
{
	NSLog(@"adiumGaimCancelRemote");
    [accountLookup(xfer->account) accountXferCanceledRemotely:xfer];
}

static GaimXferUiOps adiumGaimFileTrasnferOps = {
    adiumGaimNewXfer,
    adiumGaimDestroy,
    adiumGaimRequestFile,
    adiumGaimAskCancel,
    adiumGaimAddXfer,
    adiumGaimUpdateProgress,
    adiumGaimCancelLocal,
    adiumGaimCancelRemote
};

#pragma mark Privacy
// Privacy ------------------------------------------------------------------------------------------------------

static void adiumGaimPermitAdded(GaimAccount *account, const char *name)
{
	[accountLookup(account) accountPrivacyList:PRIVACY_PERMIT added:name];
}
static void adiumGaimPermitRemoved(GaimAccount *account, const char *name)
{
	[accountLookup(account) accountPrivacyList:PRIVACY_PERMIT removed:name];
}
static void adiumGaimDenyAdded(GaimAccount *account, const char *name)
{
	[accountLookup(account) accountPrivacyList:PRIVACY_DENY added:name];
}
static void adiumGaimDenyRemoved(GaimAccount *account, const char *name)
{
	[accountLookup(account) accountPrivacyList:PRIVACY_DENY removed:name];
}

static GaimPrivacyUiOps adiumGaimPrivacyOps = {
    adiumGaimPermitAdded,
    adiumGaimPermitRemoved,
    adiumGaimDenyAdded,
    adiumGaimDenyRemoved
};

#pragma mark Core
// Core ------------------------------------------------------------------------------------------------------
static void adiumGaimPrefsInit(void)
{
    gaim_prefs_add_none("/gaim");
    gaim_prefs_add_none("/gaim/adium");
    gaim_prefs_add_none("/gaim/adium/blist");
    gaim_prefs_add_bool("/gaim/adium/blist/show_offline_buddies", TRUE);
    gaim_prefs_add_bool("/gaim/adium/blist/show_empty_groups", TRUE);
}

static void adiumGaimCoreDebugInit(void)
{
#if (GAIM_DEBUG)
    gaim_debug_set_ui_ops(&adiumGaimDebugOps);
#endif
}

static void adiumGaimCoreUiInit(void)
{
    gaim_blist_set_ui_ops(&adiumGaimBlistOps);
    gaim_connections_set_ui_ops(&adiumGaimConnectionOps);
    gaim_conversations_set_win_ui_ops(&adiumGaimWindowOps);
    gaim_notify_set_ui_ops(&adiumGaimNotifyOps);
    gaim_request_set_ui_ops(&adiumGaimRequestOps);
    gaim_xfers_set_ui_ops(&adiumGaimFileTrasnferOps);
    gaim_privacy_set_ui_ops (&adiumGaimPrivacyOps);
	gaim_roomlist_set_ui_ops (&adiumGaimRoomlistOps);
}

static void adiumGaimCoreQuit(void)
{
    NSLog(@"Core quit");
    exit(0);
}

static GaimCoreUiOps adiumGaimCoreOps = {
    adiumGaimPrefsInit,
    adiumGaimCoreDebugInit,
    adiumGaimCoreUiInit,
    adiumGaimCoreQuit
};

#pragma mark Gaim Initialization
//  Gaim Initialization ------------------------------------------------------------------------------------------------

#define GAIM_DEFAULTS   @"GaimServiceDefaults"

- (void)installPlugin
{
//	char *plugin_search_paths[2];
	servicePluginInstance = self;

	//Register our defaults
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:GAIM_DEFAULTS forClass:[self class]]
										  forGroup:GROUP_ACCOUNT_STATUS];

    //Register ourself as libgaim's UI handler
    gaim_core_set_ui_ops(&adiumGaimCoreOps);
    if(!gaim_core_init("Adium")) {
        NSLog(@"Failed to initialize gaim core");
    }
    
	//Handle libgaim events with the Cocoa event loop
	eventLoopAdapter = [[SLGaimCocoaAdapter alloc] init];
    //Tell libgaim to load its plugins
//    NSString *bundlePath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByExpandingTildeInPath];
//    plugin_search_paths[0] = (char *)[[bundlePath stringByAppendingPathComponent:@"/Contents/Frameworks/Protocols/"] UTF8String];
//    plugin_search_paths[1] = (char *)[[bundlePath stringByAppendingPathComponent:@"/Contents/Frameworks/Plugins/"] UTF8String];
//    gaim_plugins_set_search_paths(sizeof(plugin_search_paths) / sizeof(*plugin_search_paths), plugin_search_paths);
//    gaim_plugins_probe(NULL);
	
	//Plugins
    if(!gaim_init_gg_plugin()) NSLog(@"Error: No Gadu Gadu Support");
//    if(!gaim_init_irc_plugin()) NSLog(@"Error: No IRC Support");
    if(!gaim_init_jabber_plugin()) NSLog(@"Error: No Jabber Support");
    if(!gaim_init_napster_plugin()) NSLog(@"Error: No Napster Support");
    if(!gaim_init_oscar_plugin()) NSLog(@"Error: No Oscar Support");
//    if(!gaim_init_rendezvous_plugin()) NSLog(@"Error: No Rendezvous Support");
//    if(!gaim_init_toc_plugin()) NSLog(@"Error: No TOC Support");
    if(!gaim_init_trepia_plugin()) NSLog(@"Error: No Trepia Support");
    if(!gaim_init_yahoo_plugin()) NSLog(@"Error: No Yahoo Support");
	if(!gaim_init_novell_plugin()) NSLog(@"Error: No Novell Support");

	if(/*!gaim_init_ssl_plugin() || */!gaim_init_ssl_gnutls_plugin() || !gaim_init_msn_plugin()){
		NSLog(@"Error: No MSN/SSL Support");
	}
	
    //Setup the buddy list
    gaim_set_blist(gaim_blist_new());
            
    //Setup libgaim core preferences
    
    //Disable gaim away handling - we do it ourselves
    gaim_prefs_set_bool("/core/conversations/away_back_on_send", FALSE);
    gaim_prefs_set_bool("/core/away/auto_response/enabled", FALSE);
    
    //Disable gaim conversation logging
    gaim_prefs_set_bool("/gaim/gtk/logging/log_chats", FALSE);
    gaim_prefs_set_bool("/gaim/gtk/logging/log_ims", FALSE);
    
    //Typing preference
    gaim_prefs_set_bool("/core/conversations/im/send_typing", TRUE);

	//Configure signals for receiving gaim events
	[self configureSignals];

	_accountDict = [[NSMutableDictionary alloc] init];

    //Install the services
    OscarService	= [[[CBOscarService alloc] initWithService:self] retain];
    GaduGaduService = [[[ESGaduGaduService alloc] initWithService:self] retain];
    MSNService		= [[[ESMSNService alloc] initWithService:self] retain];
    NapsterService  = [[[ESNapsterService alloc] initWithService:self] retain];
	NovellService   = [[[ESNovellService alloc] initWithService:self] retain];
	JabberService   = [[[ESJabberService alloc] initWithService:self] retain];
	TrepiaService   = [[[ESTrepiaService alloc] initWithService:self] retain];
    YahooService	= [[[ESYahooService alloc] initWithService:self] retain];
}

- (void)uninstallPlugin
{
	gaim_signals_disconnect_by_handle(gaim_adium_get_handle());
	
    [_accountDict release]; _accountDict = nil;
    
    //Services
    [OscarService release]; OscarService = nil;
    [GaduGaduService release]; GaduGaduService = nil;
	[JabberService release]; JabberService = nil;
    [NapsterService release]; NapsterService = nil;
    [MSNService release]; MSNService = nil;
	[TrepiaService release]; TrepiaService = nil;
    [YahooService release]; YahooService = nil;
	[NovellService release]; NovellService = nil;
	
	[eventLoopAdapter release]; eventLoopAdapter = nil;
}

#pragma mark AccountDict Methods
// AccountDict ---------------------------------------------------------------------------------------------------------
- (void)addAccount:(id)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct 
{
    [_accountDict setObject:anAccount forKey:[NSValue valueWithPointer:gaimAcct]];
}

- (void)removeAccount:(GaimAccount *)gaimAcct
{
    [_accountDict removeObjectForKey:[NSValue valueWithPointer:gaimAcct]];
}

- (void)removeAccountWithPointerValue:(NSValue *)inPointer
{
    [_accountDict removeObjectForKey:inPointer];	
}

#pragma mark Systemwide Proxy Settings
// Proxy ---------------------------------------------------------------------------------------------------------------

- (NSDictionary *)systemSOCKSSettingsDictionary
{
	NSMutableDictionary *systemSOCKSSettingsDictionary = nil;
	
    Boolean             result;
    CFDictionaryRef     proxyDict = nil;
    CFNumberRef         enableNum = nil;
    int                 enable;
    CFStringRef         hostStr = nil;
    CFNumberRef         portNum = nil;
    int                 portInt;
    
    char    host[300];
    size_t  hostSize;
		
    proxyDict = SCDynamicStoreCopyProxies(NULL);
    result = (proxyDict != NULL);
     
    // Get the enable flag.  This isn't a CFBoolean, but a CFNumber.
    // Check if SOCKS is enabled
    if (result) {
        enableNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                       kSCPropNetProxiesSOCKSEnable);
        
        result = (enableNum != NULL)
            && (CFGetTypeID(enableNum) == CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(enableNum, kCFNumberIntType,
                                  &enable) && (enable != 0);
    }
    
    // Get the proxy host.  DNS names must be in ASCII.  If you 
    // put a non-ASCII character  in the "Secure Web Proxy"
    // field in the Network preferences panel, the CFStringGetCString
    // function will fail and this function will return false.
    if (result) {
		if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: SOCKS is enabled; looking up kSCPropNetProxiesSOCKSProxy");
        hostStr = (CFStringRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesSOCKSProxy);
        
        result = (hostStr != NULL)
            && (CFGetTypeID(hostStr) == CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize, [NSString defaultCStringEncoding]);
		if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: got a host of %s",host);
    }
    
    //Get the proxy port
    if (result) {
        portNum = (CFNumberRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesSOCKSPort);
        
        result = (portNum != NULL)
            && (CFGetTypeID(portNum) == CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(portNum, kCFNumberIntType, &portInt);
		if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: got a port of %i",portInt);
    }
    if (result) {
        //set what we've got so far
        if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: setting socks5 settings: %s:%i",host,portInt);
		
		NSString *hostString = [NSString stringWithCString:host];
				
		systemSOCKSSettingsDictionary = [[NSMutableDictionary alloc] init];
		
		[systemSOCKSSettingsDictionary setObject:hostString forKey:@"Host"];
		[systemSOCKSSettingsDictionary setObject:[NSNumber numberWithInt:portInt] forKey:@"Port"];
        
        NSDictionary* auth = [self getDictionaryFromKeychainForKey:hostString];
        
        if(auth) {
            if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: proxy username='%@' password=(in the keychain)",[auth objectForKey:@"username"]);
            
			[systemSOCKSSettingsDictionary setObject:[auth objectForKey:@"username"] forKey:@"Username"];
			[systemSOCKSSettingsDictionary setObject:[auth objectForKey:@"password"] forKey:@"Password"];
            
        } else {
            //No username/password.  I think this doesn't need to be an error or anythign since it should have been set in the system prefs
            if (GAIM_DEBUG) NSLog(@"configureGaimProxySettings: No username/password found");
        }
    }    
    
    // Clean up.
    if (proxyDict != NULL) {
        CFRelease(proxyDict);
    }
	
    return [systemSOCKSSettingsDictionary autorelease];
}    

//Next two functions are from the http-mail project.
static NSData *OWKCGetItemAttribute(KCItemRef item, KCItemAttr attrTag)
{
    SecKeychainAttribute    attr;
    OSStatus                keychainStatus;
    UInt32                  actualLength;
    void                    *freeMe = NULL;
    
    attr.tag = attrTag;
    actualLength = 256;
    attr.length = actualLength; 
    attr.data = alloca(actualLength);
    
    keychainStatus = KCGetAttribute(item, &attr, &actualLength);
    if (keychainStatus == errKCBufferTooSmall) {
        /* the attribute length will have been placed into actualLength */
        freeMe = NSZoneMalloc(NULL, actualLength);
        attr.length = actualLength;
        attr.data = freeMe;
        keychainStatus = KCGetAttribute(item, &attr, &actualLength);
    }
    if (keychainStatus == noErr) {
        NSData *retval = [NSData dataWithBytes:attr.data length:actualLength];
        if (freeMe != NULL)
            NSZoneFree(NULL, freeMe);
        return retval;
    }
    
    if (freeMe != NULL)
        NSZoneFree(NULL, freeMe);
    
    if (keychainStatus == errKCNoSuchAttr) {
        /* An expected error. Return nil for nonexistent attributes. */
        return nil;
    }
    
    /* We shouldn't make it here */
    [NSException raise:@"Error Reading Keychain" format:@"Error number %d.", keychainStatus];
    
    return nil;  // appease the dread compiler warning gods
}

- (NSDictionary *)getDictionaryFromKeychainForKey:(NSString *)key
{
    NSData              *data;
    KCSearchRef         grepstate; 
    KCItemRef           item;
    UInt32              length;
    void                *itemData;
    NSMutableDictionary *result = nil;
    
    SecKeychainRef      keychain;
    SecKeychainCopyDefault(&keychain);
    
        if(KCFindFirstItem(keychain, NULL, &grepstate, &item)==noErr) {  
            do {
                NSString    *server = nil;
                
                data = OWKCGetItemAttribute(item, kSecLabelItemAttr);
                if(data) {
                    server = [NSString stringWithCString: [data bytes] length: [data length]];
                }
                
                if([key isEqualToString:server]) {
                    NSString    *username;
                    NSString    *password;
                    
                    data = OWKCGetItemAttribute(item, kSecAccountItemAttr);
                    if(data) {
                        username = [NSString stringWithCString: [data bytes] length: [data length]];
                    } else {
                        username = @"";
                    }
                    
                    if(SecKeychainItemCopyContent(item, NULL, NULL, &length, &itemData) == noErr) {
                        password = [NSString stringWithCString:itemData length:length];
                        SecKeychainItemFreeContent(NULL, itemData);
                    } else {
                        password = @"";
                    } 
                    
                    result = [NSDictionary dictionaryWithObjectsAndKeys:username,@"username",password,@"password",nil];
                    
                    KCReleaseItem(&item);
                    
                    break;
                }
                
                KCReleaseItem(&item);
            } while( KCFindNextItem(grepstate, &item)==noErr);
            
            KCReleaseSearch(&grepstate);
        }
    
        CFRelease(keychain);
    return result;   
}
@end