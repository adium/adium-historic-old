//
//  CBGaimServicePlugin.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CBGaimServicePlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "CBGaimAccount.h"

#define GAIM_EVENTLOOP_INTERVAL     0.02         //Interval at which to run libgaim's main event loop

@interface CBGaimServicePlugin(Internal)
- (NSMutableDictionary *)_accountDictionary;
@end

@implementation CBGaimServicePlugin

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


// Connection ------------------------------------------------------------------------------------------------------
static void adiumGaimConnConnectProgress(GaimConnection *gc, const char *text, size_t step, size_t step_count)
{
    NSLog(@"Connecting: %i (%s) %i / %i", gc, text, step, step_count);
}

static void adiumGaimConnConnected(GaimConnection *gc)
{
    NSLog(@"Connected: %i", gc);
}

static void adiumGaimConnDisconnected(GaimConnection *gc)
{
    NSLog(@"Disconnected: %i", gc);
}

static void adiumGaimConnNotice(GaimConnection *gc, const char *text)
{
    NSLog(@"Connection Notice: %i (%s)", gc, text);
}

static void adiumGaimConnReportDisconnect(GaimConnection *gc, const char *text)
{
    NSLog(@"Connection Disconnected: %i (%s)", gc, text);
}

static GaimConnectionUiOps adiumGaimConnectionOps = {
    adiumGaimConnConnectProgress,
    adiumGaimConnConnected,
    adiumGaimConnDisconnected,
    adiumGaimConnNotice,
    adiumGaimConnReportDisconnect
};


// Contact List ------------------------------------------------------------------------------------------------------
static void adiumGaimBlistNewList(GaimBuddyList *list)
{
    //We're allowed to place whatever we want in blist's ui_data.    
    NSLog(@"adiumGaimBlistNewList");
}

static void adiumGaimBlistNewNode(GaimBlistNode *node)
{
    //We're allowed to place whatever we want in node's ui_data.    
    NSLog(@"adiumGaimBlistNewNode");
    
    if(node && GAIM_BLIST_NODE_IS_BUDDY(node))
    {
        GaimBuddy *buddy = (GaimBuddy *)node;
        
        NSMutableDictionary *_accountDict = [[[(AIHandle *)node->ui_data account] service] _accountDictionary];
        
        id theAccount = [_accountDict objectForKey:
            [NSString stringWithFormat:@"%s.%s", 
                (char *)gaim_account_get_protocol_id(buddy->account),
                (char *)gaim_account_get_username(buddy->account)]];
        
        if([theAccount respondsToSelector:@selector(accountBlistNewNode:)])
            [theAccount accountBlistNewNode:node];
    }
}

static void adiumGaimBlistShow(GaimBuddyList *list)
{
    NSLog(@"adiumGaimBlistShow");
}

static void adiumGaimBlistUpdate(GaimBuddyList *list, GaimBlistNode *node)
{
    NSLog(@"adiumGaimBlistUpdate");
    
    if(node && GAIM_BLIST_NODE_IS_BUDDY(node))
    {        
        id theAccount = [(AIHandle *)node->ui_data account];
        
        if([theAccount respondsToSelector:@selector(accountBlistNewNode:)])
            [theAccount accountBlistUpdate:list withNode:node];
    }
}

static void adiumGaimBlistRemove(GaimBuddyList *list, GaimBlistNode *node)
{
    //Here we're responsible for destroying what we placed in the node's ui_data earlier
    NSLog(@"adiumGaimBlistRemove");

    if(node && GAIM_BLIST_NODE_IS_BUDDY(node))
    {
        id theAccount = [(AIHandle *)node->ui_data account];
        
        if([theAccount respondsToSelector:@selector(accountBlistNewNode:)])
            [theAccount accountBlistRemove:list withNode:node];
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

static void adiumGaimBlistRequestAddChat(GaimAccount *account, GaimGroup *group)
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


// Conversation ------------------------------------------------------------------------------------------------------
static void adiumGaimConvDestroy(GaimConversation *conv)
{
    //Place anything we want in ui_ops
    NSLog(@"adiumGaimConvDestroy");
}

static void adiumGaimConvWriteChat(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
    NSLog(@"adiumGaimConvWriteChat");
}

static void adiumGaimConvWriteIm(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
    NSLog(@"adiumGaimConvWriteIm");
}

static void adiumGaimConvWriteConv(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
    NSLog(@"adiumGaimConvWriteConv");
}

static void adiumGaimConvChatAddUser(GaimConversation *conv, const char *user)
{
    NSLog(@"adiumGaimConvChatAddUser");
}

static void adiumGaimConvChatAddUsers(GaimConversation *conv, GList *users)
{
    NSLog(@"adiumGaimConvChatAddUsers");
}

static void adiumGaimConvChatRenameUser(GaimConversation *conv, const char *oldName, const char *newName)
{
    NSLog(@"adiumGaimConvChatRenameUser");
}

static void adiumGaimConvChatRemoveUser(GaimConversation *conv, const char *user)
{
    NSLog(@"adiumGaimConvChatRemoveUser");
}

static void adiumGaimConvChatRemoveUsers(GaimConversation *conv, GList *users)
{
    NSLog(@"adiumGaimConvChatRemoveUsers");
}

static void adiumGaimConvSetTitle(GaimConversation *conv, const char *title)
{
    NSLog(@"adiumGaimConvSetTitle");
}

static void adiumGaimConvUpdateProgress(GaimConversation *conv, float percent)
{
    NSLog(@"adiumGaimConvUpdateProgress");
}

static void adiumGaimConvUpdated(GaimConversation *conv, GaimConvUpdateType type)
{
    NSLog(@"adiumGaimConvUpdated");
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
    adiumGaimConvSetTitle,
    adiumGaimConvUpdateProgress,
    adiumGaimConvUpdated
};


// Conversation Window ---------------------------------------------------------------------------------------------
static GaimConversationUiOps *adiumGaimConvWindowGetConvUiOps()
{
    return(&adiumGaimConversationOps);
}

static void adiumGaimConvWindowNew(GaimConvWindow *win)
{
    //Once again, we can put anything we want in win's ui_data
    NSLog(@"adiumGaimConvWindowNew");
}

static void adiumGaimConvWindowDestroy(GaimConvWindow *win)
{
    //Cleanup what we placed in win's ui_data earlier
    NSLog(@"adiumGaimConvWindowDestroy");
}

static void adiumGaimConvWindowShow(GaimConvWindow *win)
{
    NSLog(@"adiumGaimConvWindowShow");
}

static void adiumGaimConvWindowHide(GaimConvWindow *win)
{
    NSLog(@"adiumGaimConvWindowHide");
}

static void adiumGaimConvWindowRaise(GaimConvWindow *win)
{
    NSLog(@"adiumGaimConvWindowRaise");
}

static void adiumGaimConvWindowFlash(GaimConvWindow *win)
{
    NSLog(@"adiumGaimConvWindowFlash");
}

static void adiumGaimConvWindowSwitchConv(GaimConvWindow *win, unsigned int index)
{
    NSLog(@"adiumGaimConvWindowSwitchConv");
}

static void adiumGaimConvWindowAddConv(GaimConvWindow *win, GaimConversation *conv)
{
    NSLog(@"adiumGaimConvWindowAddConv");
}

static void adiumGaimConvWindowRemoveConv(GaimConvWindow *win, GaimConversation *conv)
{
    NSLog(@"adiumGaimConvWindowRemoveConv");
}

static void adiumGaimConvWindowMoveConv(GaimConvWindow *win, GaimConversation *conv, unsigned int newIndex)
{
    NSLog(@"adiumGaimConvWindowMoveConv");
}

static int adiumGaimConvWindowGetActiveIndex(const GaimConvWindow *win)
{
    NSLog(@"adiumGaimConvWindowGetActiveIndex");
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


// Notify ----------------------------------------------------------------------------------------------------------
static void *adiumGaimNotifyMessage(GaimNotifyMsgType type, const char *title, const char *primary, const char *secondary, GCallback cb, void *userData)
{
    //Values passed can be null
    NSLog(@"adiumGaimNotifyMessage");
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
    //Values passed can be null
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
    NSLog(@"adiumGaimNotifyClose");
}

static GaimNotifyUiOps adiumGaimNotifyOps = {
    adiumGaimNotifyMessage,
    adiumGaimNotifyEmail,
    adiumGaimNotifyEmails,
    adiumGaimNotifyFormatted,
    adiumGaimNotifyUri,
    adiumGaimNotifyClose
};


// Request ------------------------------------------------------------------------------------------------------
static void *adiumGaimRequestInput(const char *title, const char *primary, const char *secondary, const char *defaultValue, gboolean multiline, gboolean masked, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb, void *userData)
{
    NSLog(@"adiumGaimRequestInput");
    return(nil);
}

static void *adiumGaimRequestChoice(const char *title, const char *primary, const char *secondary, unsigned int defaultValue, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb, void *userData, size_t choiceCount, va_list choices)
{
    NSLog(@"adiumGaimRequestChoice");
    return(nil);
}

static void *adiumGaimRequestAction(const char *title, const char *primary, const char *secondary, unsigned int default_action, void *userData, size_t actionCount, va_list actions)
{
    NSLog(@"adiumGaimRequestAction");
    return(nil);
}

static void *adiumGaimRequestFields(const char *title, const char *primary, const char *secondary, GaimRequestFields *fields, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb, void *userData)
{
    NSLog(@"adiumGaimRequestFields");
    return(nil);
}

static void adiumGaimRequestClose(GaimRequestType type, void *uiHandle)
{
    NSLog(@"adiumGaimRequestClose");
}

static GaimRequestUiOps adiumGaimRequestOps = {
    adiumGaimRequestInput,
    adiumGaimRequestChoice,
    adiumGaimRequestAction,
    adiumGaimRequestFields,
    adiumGaimRequestClose
};


// Core ------------------------------------------------------------------------------------------------------
static void adiumGaimPrefsInit(void)
{
    gaim_prefs_add_none("/gaim");
    gaim_prefs_add_none("/gaim/adium");
    gaim_prefs_add_none("/gaim/adium/blist");
    gaim_prefs_add_bool("/gaim/adium/blist/show_offline_buddies", false);
    gaim_prefs_add_bool("/gaim/adium/blist/show_empty_groups", false);
}

static void adiumGaimCoreDebugInit(void)
{
    gaim_debug_set_ui_ops(&adiumGaimDebugOps);
}

static void adiumGaimCoreUiInit(void)
{
    gaim_blist_set_ui_ops(&adiumGaimBlistOps);
    gaim_connections_set_ui_ops(&adiumGaimConnectionOps);
    gaim_conversations_set_win_ui_ops(&adiumGaimWindowOps);
    gaim_notify_set_ui_ops(&adiumGaimNotifyOps);
    gaim_request_set_ui_ops(&adiumGaimRequestOps);
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

// Beef ------------------------------------------------------------------------------------------------------

- (void)installPlugin
{
    accountDict = [[NSMutableDictionary alloc] init];

    char *plugin_search_paths[1];

    //Register ourself as libgaim's UI handler
    gaim_core_set_ui_ops(&adiumGaimCoreOps);
    if(!gaim_core_init("Adium")) {
        NSLog(@"Failed to initialize gaim core");
    }
    
    //Tell libgaim to load it's plugins
    plugin_search_paths[0] = (char *)[[[[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"/Contents/Frameworks/Protocols/"] stringByExpandingTildeInPath] UTF8String];
    gaim_plugins_set_search_paths(sizeof(plugin_search_paths) / sizeof(*plugin_search_paths), plugin_search_paths);
    gaim_plugins_probe(NULL);

    //Tell libgaim to load it's other pieces
    gaim_prefs_load();
    gaim_accounts_load();
    gaim_pounces_load();
    
    //Setup the buddy list
    gaim_set_blist(gaim_blist_new());
    gaim_blist_load();

    //Install the libgaim event loop timer
    [NSTimer scheduledTimerWithTimeInterval:GAIM_EVENTLOOP_INTERVAL target:self selector:@selector(gaimEventLoopTimer:) userInfo:nil repeats:YES];

    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"GAIM"
                                                      description:@"LIBGAIM (Do not use)"
                                                            image:nil
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."]] retain];

    //Register this service
    [[owner accountController] registerService:self];
}

- (void)uninstallPlugin
{
    [accountDict release];
}

//Periodic timer to run libgaim's event loop
- (void)gaimEventLoopTimer:(NSTimer *)inTimer
{
    //If there are event pending, iterate through one event
    if(gaim_core_mainloop_events_pending()){
        gaim_core_mainloop_iteration();

        //We also have this method, which will iterate through all events.
        //gaim_core_mainloop_finish_events()
    }
}

- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner
{
    CBGaimAccount *anAccount = [[[CBGaimAccount alloc] initWithProperties:inProperties service:self owner:inOwner] autorelease];
    
    [accountDict setObject:anAccount forKey:[anAccount UIDAndServiceID]];
    
    return anAccount;
}

- (NSString *)identifier
{
    return(@"LIBGAIM");
}
- (NSString *)description
{
    return(@"LIBGAIM (Do not use)");
}

- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}
@end


@implementation CBGaimServicePlugin(Internal)
- (NSMutableDictionary *)_accountDictionary
{
    return accountDict;
}
@end