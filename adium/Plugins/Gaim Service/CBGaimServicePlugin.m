//
//  CBGaimServicePlugin.m
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//

#import <Security/Security.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "CBGaimServicePlugin.h"
#import "CBGaimAIMAccount.h"

#import "GaimServices.h"


#define GAIM_EVENTLOOP_INTERVAL     0.02         //Interval at which to run libgaim's main event loop

@interface CBGaimServicePlugin (PRIVATE)
- (NSDictionary *)getDictionaryFromKeychainForKey:(NSString *)key;
@end

/*
 * Maps GaimAccount*s to CBGaimAccount*s.
 * This is necessary because the gaim people didn't put the same void *ui_data
 * in here that they put in most of their other structures. Maybe we should
 * ask them for one so we can take this out.
 */
NSMutableDictionary *_accountDict;

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
    if (GAIM_DEBUG) {
	gchar *arg_s = g_strdup_vprintf(format, args); //NSLog sometimes chokes on the passed args, so we'll use vprintf
	
	//Log error
	if(!category) category = "general"; //Category can be nil
	NSLog(@"(Debug: %s) %s", category, arg_s);
	
	g_free(arg_s);
    }
}

static GaimDebugUiOps adiumGaimDebugOps = {
    adiumGaimDebugPrint
};

#pragma mark Connection
// Connection ------------------------------------------------------------------------------------------------------
static void adiumGaimConnConnectProgress(GaimConnection *gc, const char *text, size_t step, size_t step_count)
{
    NSLog(@"Connecting: gc=0x%x (%s) %i / %i", gc, text, step, step_count);
    
}

static void adiumGaimConnConnected(GaimConnection *gc)
{
    NSLog(@"Connected: gc=%x", gc);
    [accountLookup(gc->account) accountConnectionConnected];
}

static void adiumGaimConnDisconnected(GaimConnection *gc)
{
    NSLog(@"Disconnected: gc=%x", gc);
    if (_accountDict == nil) // if this has been destroyed, unloadPlugin has already been called
        return;
    [accountLookup(gc->account) accountConnectionDisconnected];
}

static void adiumGaimConnNotice(GaimConnection *gc, const char *text)
{
    NSLog(@"Connection Notice: gc=%x (%s)", gc, text);
}

static void adiumGaimConnReportDisconnect(GaimConnection *gc, const char *text)
{
    NSLog(@"Connection Disconnected: gc=%x (%s)", gc, text);
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

#pragma mark Conversation
// Conversation ------------------------------------------------------------------------------------------------------
static void adiumGaimConvDestroy(GaimConversation *conv)
{
    [accountLookup(conv->account) accountConvDestroy:conv];
}

static void adiumGaimConvWriteChat(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
    NSLog(@"adiumGaimConvWriteChat: %s: %s", who, message);
}

static void adiumGaimConvWriteIm(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
//    NSLog(@"adiumGaimConvWriteIm: name=%s, who=%s: %s",conv->name, who, message);
    [accountLookup(conv->account) accountConvReceivedIM: message inConversation: conv withFlags: flags atTime: mtime];
}

static void adiumGaimConvWriteConv(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
    NSLog(@"adiumGaimConvWriteConv: %s: %s", who, message);
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
    adiumGaimConvSetTitle,
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
    //Cleanup what we placed in win's ui_data earlier
}

static void adiumGaimConvWindowShow(GaimConvWindow *win)
{
    
}

static void adiumGaimConvWindowHide(GaimConvWindow *win)
{
    NSLog(@"adiumGaimConvWindowHide");
}

static void adiumGaimConvWindowRaise(GaimConvWindow *win)
{
}

static void adiumGaimConvWindowFlash(GaimConvWindow *win)
{
}

static void adiumGaimConvWindowSwitchConv(GaimConvWindow *win, unsigned int index)
{
    NSLog(@"adiumGaimConvWindowSwitchConv");
}

static void adiumGaimConvWindowAddConv(GaimConvWindow *win, GaimConversation *conv)
{
}

static void adiumGaimConvWindowRemoveConv(GaimConvWindow *win, GaimConversation *conv)
{
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

#pragma mark Notify
// Notify ----------------------------------------------------------------------------------------------------------
static void *adiumGaimNotifyMessage(GaimNotifyMsgType type, const char *title, const char *primary, const char *secondary, GCallback cb, void *userData)
{
    //Values passed can be null
    NSLog(@"adiumGaimNotifyMessage: %s: %s, %s", title, primary, secondary);
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

#pragma mark Request
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
    //Called when someone attempts to add you to:
        //their MSN buddy list
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

#pragma mark File Transfer
// File Transfer ------------------------------------------------------------------------------------------------------

static void adiumGaimNewXfer(GaimXfer *xfer)
{
        NSLog(@"adiumGaimNewXfer");
}

static void adiumGaimDestroy(GaimXfer *xfer)
{
        NSLog(@"adiumGaimDestroy");
}

static void adiumGaimRequestFile(GaimXfer *xfer)
{
    GaimXferType xferType = gaim_xfer_get_type(xfer);
    NSLog(@"adiumGainRequestFile");
    if ( xferType == GAIM_XFER_RECEIVE ) {
        NSLog(@"File request: %s from %s on IP %s",xfer->filename,xfer->who,gaim_xfer_get_remote_ip(xfer));
        [accountLookup(xfer->account) accountXferRequestFileReceiveWithXfer:xfer];
    } else if ( xferType == GAIM_XFER_SEND ) {
        [accountLookup(xfer->account) accountXferBeginFileSendWithXfer:xfer];   
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
    NSLog(@"transfer update: %s is now %f%% done",xfer->filename,(percent*100));
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
    
}
static void adiumGaimPermitRemoved(GaimAccount *account, const char *name)
{
    
}
static void adiumGaimDenyAdded(GaimAccount *account, const char *name)
{
    
}
static void adiumGaimDenyRemoved(GaimAccount *account, const char *name)
{
    
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
    gaim_debug_set_ui_ops(&adiumGaimDebugOps);
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

#pragma mark Beef
// Beef ------------------------------------------------------------------------------------------------------

- (void)installPlugin
{
    _accountDict = [[NSMutableDictionary alloc] init];

    char *plugin_search_paths[2];

    //Register ourself as libgaim's UI handler
    gaim_core_set_ui_ops(&adiumGaimCoreOps);
    if(!gaim_core_init("Adium")) {
        NSLog(@"Failed to initialize gaim core");
    }
    
    //Tell libgaim to load its plugins
    NSString *bundlePath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByExpandingTildeInPath];
    plugin_search_paths[0] = (char *)[[bundlePath stringByAppendingPathComponent:@"/Contents/Frameworks/Protocols/"] UTF8String];
    plugin_search_paths[1] = (char *)[[bundlePath stringByAppendingPathComponent:@"/Contents/Frameworks/Plugins/"] UTF8String];
    gaim_plugins_set_search_paths(sizeof(plugin_search_paths) / sizeof(*plugin_search_paths), plugin_search_paths);
    gaim_plugins_probe(NULL);
    
    //Setup the buddy list
    gaim_set_blist(gaim_blist_new());
            
    //**Setup libgaim core preferences**
    
    //Disable gaim away handling - we do it ourselves
    gaim_prefs_set_bool("/core/conversations/away_back_on_send", FALSE);
    gaim_prefs_set_bool("/core/away/auto_response/enabled", FALSE);
    
    //Disable gaim conversation logging
    gaim_prefs_set_bool("/gaim/gtk/logging/log_chats", FALSE);
    gaim_prefs_set_bool("/gaim/gtk/logging/log_ims", FALSE);
    
    //Typing preference!
    gaim_prefs_set_bool("/core/conversations/im/send_typing", TRUE);
        
    //Install the libgaim event loop timer
    [NSTimer scheduledTimerWithTimeInterval:GAIM_EVENTLOOP_INTERVAL 
                                     target:self
                                   selector:@selector(gaimEventLoopTimer:)
                                   userInfo:nil
                                    repeats:YES];
    //Install the services
    AIMService = [[[CBAIMService alloc] initWithService:self] retain];
    MSNService = [[[ESMSNService alloc] initWithService:self] retain];
    YahooService = [[[ESYahooService alloc] initWithService:self] retain]; 
    GaduGaduService = [[[ESGaduGaduService alloc] initWithService:self] retain];
    NapsterService = [[[ESNapsterService alloc] initWithService:self] retain];
    JabberService = [[[ESJabberService alloc] initWithService:self] retain];
    
}

- (void)uninstallPlugin
{
    [_accountDict release];
    _accountDict = nil;
    
    //Services
    [AIMService release];
    [MSNService release];
    [YahooService release];
    [GaduGaduService release];
    [NapsterService release];
    [JabberService release];
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

- (void)addAccount:(id)anAccount forGaimAccountPointer:(GaimAccount *)gaimAcct 
{
    [_accountDict setObject:anAccount forKey:[NSValue valueWithPointer:gaimAcct]];
}

- (void)removeAccount:(GaimAccount *)gaimAcct
{
    [_accountDict removeObjectForKey:[NSValue valueWithPointer:gaimAcct]];
}


#pragma mark Proxy
// Proxy ------------------------------------------------------------------------------------------------------

/*
 "/core/proxy/type",
 _("No proxy"), "none",
 "SOCKS 4", "socks4",
 "SOCKS 5", "socks5",
 "HTTP", "http",
 */
- (BOOL)configureGaimProxySettings
{
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
    //check if SOCKS is enabled
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
        hostStr = (CFStringRef) CFDictionaryGetValue(proxyDict,
                                                     kSCPropNetProxiesSOCKSProxy);
        
        result = (hostStr != NULL)
            && (CFGetTypeID(hostStr) == CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize, [NSString defaultCStringEncoding]);
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
    }
    if (result) {
        //set what we've got so far
        NSLog(@"setting socks5 settings: %s:%i",host,portInt);
        gaim_prefs_set_string("/core/proxy/type", "socks5");
        gaim_prefs_set_string("/core/proxy/host",host);
        gaim_prefs_set_int("/core/proxy/port",portInt);
        
        NSString *key = [NSString stringWithCString:host];
        NSDictionary* auth = [self getDictionaryFromKeychainForKey:key];
        
        if(auth) {
            NSLog(@"proxy username='%@' password=(in the keychain)",[auth objectForKey:@"username"]);
            
            gaim_prefs_set_string("/core/proxy/username",  [[auth objectForKey:@"username"] UTF8String]);
            gaim_prefs_set_string("/core/proxy/password", [[auth objectForKey:@"password"] UTF8String]);
            
        } else {
            //No username/password.  I think this doesn't need to be an error or anythign since it should have been set in the system prefs
            NSLog(@"No username/password found");
        }
    }    
    
    // Clean up.
    if (proxyDict != NULL) {
        CFRelease(proxyDict);
    }
    return result;
}    

//Next two functions are from the http-mail project.  We'll write our own if their license doesn't allow this... but it'll be okay for now.
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