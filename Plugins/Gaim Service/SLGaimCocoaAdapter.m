//
//  SLGaimCocoaAdapter.m
//  Adium
//  Adapts gaim to the Cocoa event loop.
//  Requires Mac OS X 10.2.
//
//  Event loop code by Scott Lamb on Sun Nov 2 2003.
//

#import  <Foundation/Foundation.h>
#include <Libgaim/libgaim.h>
#include <stdlib.h>
#include <glib.h>

#import "SLGaimCocoaAdapter.h"
#import <CoreFoundation/CFSocket.h>
#import <CoreFoundation/CFRunLoop.h>

#import "GaimCommon.h"
#import "CBGaimServicePlugin.h"
#import "CBGaimAccount.h"

#import "ESGaimRequestWindowController.h"
#import "ESGaimRequestActionWindowController.h"
#import "ESGaimNotifyEmailWindowController.h"

#import "CBGaimOscarAccount.h"

//For MSN user icons
//#include <libgaim/session.h>
//#include <libgaim/userlist.h>
//#include <libgaim/user.h>

//Jabber registration
#include <libgaim/jabber.h>

//Gaim slash command interface
#include <libgaim/cmds.h>

//Webcam
#include <libgaim/webcam.h>

#define ACCOUNT_IMAGE_CACHE_PATH		@"~/Library/Caches/Adium"
#define MESSAGE_IMAGE_CACHE_NAME		@"Image_%@_%i"

#define	ENABLE_WEBCAM	TRUE

@interface SLGaimCocoaAdapter (PRIVATE)
- (void)callTimerFunc:(NSTimer*)timer;
- (void)initLibGaim;
- (NSString *)_messageImageCachePathForID:(int)imageID forAdiumAccount:(NSObject<AdiumGaimDO> *)adiumAccount;
- (BOOL)attemptGaimCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat;
@end

/*
 * A pointer to the single instance of this class active in the application.
 * The gaim callbacks need to be C functions with specific prototypes, so they
 * can't be ObjC methods. The ObjC callbacks do need to be ObjC methods. This
 * allows the C ones to call the ObjC ones.
 **/
static SLGaimCocoaAdapter   *myself;

//Dictionaries to track gaim<->adium interactions
NSMutableDictionary *accountDict = nil;
//NSMutableDictionary *contactDict = nil;
NSMutableDictionary *chatDict = nil;

//Event loop static variables
static guint					sourceId = nil;		//The next source key; continuously incrementing
static NSMutableDictionary		*sourceInfoDict = nil;
static NDRunLoopMessenger	*gaimThreadMessenger = nil;
static NDRunLoopMessenger	*mainThreadMesesnger = nil;
static BOOL					isOnTigerOrBetter = NO;

void gaim_xfer_choose_file_ok_cb(void *user_data, const char *filename);
void gaim_xfer_choose_file_cancel_cb(void *user_data, const char *filename);
int gaim_xfer_choose_file(GaimXfer *xfer);

static GaimAccount* accountLookupFromAdiumAccount(id adiumAccount);

//The autorelease pool presently in use; it will be periodically released and recreated
static NSAutoreleasePool *currentAutoreleasePool = nil;
#define	AUTORELEASE_POOL_REFRESH	1.0

@implementation SLGaimCocoaAdapter

#pragma mark Init

+ (void)createThreadedGaimCocoaAdapter
{
	SLGaimCocoaAdapter  *gaimCocoaAdapter;

	//Will not return until the program terminates
    gaimCocoaAdapter = [[self alloc] init];
	
	[gaimCocoaAdapter release];
	
    return;
}

+ (SLGaimCocoaAdapter *)sharedInstance
{
	return myself;
}


- (void)setMainThreadMessenger:(NDRunLoopMessenger *)inMainThreadMessenger
{
	mainThreadMesesnger = [inMainThreadMessenger retain];
}

- (void)addAdiumAccount:(NSObject<AdiumGaimDO> *)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	account->ui_data = [adiumAccount retain];
	
	[gaimThreadMessenger target:self 
				performSelector:@selector(gaimThreadAddAdiumAccount:)
					 withObject:adiumAccount];
}

//Register the account gaimside in the gaim thread to avoid a conflict on the g_hash_table containing accounts
- (void)gaimThreadAddAdiumAccount:(NSObject<AdiumGaimDO> *)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);

    gaim_accounts_add(account);	
}

#pragma mark Init
- (id)init
{
	NSTimer	*autoreleaseTimer;

	currentAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	[super init];
	
	isOnTigerOrBetter = [NSApp isOnTigerOrBetter];
	
	sourceId = 0;
    sourceInfoDict = [[NSMutableDictionary alloc] init];
    accountDict = [[NSMutableDictionary alloc] init];
	chatDict = [[NSMutableDictionary alloc] init];
		
	myself = self;
	
	[self initLibGaim];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(gotNewAccount:) 
												 name:@"AddAccount"
											   object:nil];
	
	gaimThreadMessenger = [[NDRunLoopMessenger runLoopMessengerForCurrentRunLoop] retain];

	autoreleaseTimer = [[NSTimer scheduledTimerWithTimeInterval:AUTORELEASE_POOL_REFRESH
														 target:self
													   selector:@selector(refreshAutoreleasePool:)
													   userInfo:nil
														repeats:YES] retain];

	CFRunLoopRun();

	[autoreleaseTimer invalidate]; [autoreleaseTimer release];
	[gaimThreadMessenger release]; gaimThreadMessenger = nil;
    [currentAutoreleasePool release];
	
    return self;
}

//Our autoreleased objects will only be released when the outermost autorelease pool is released.
//This is handled automatically in the main thread, but we need to do it manually here.
//Release the current pool, then create a new one.
- (void)refreshAutoreleasePool:(NSTimer *)inTimer
{
	[currentAutoreleasePool release];
	currentAutoreleasePool = [[NSAutoreleasePool alloc] init];
}

#pragma mark Gaim wrapper

/*
 * Finds an NSObject<AdiumGaimDO>* for a GaimAccount*.
 */

static NSObject<AdiumGaimDO> *accountLookup(GaimAccount *acct)
{
	NSObject<AdiumGaimDO> *adiumGaimAccount = (acct ? (NSObject<AdiumGaimDO> *)acct->ui_data : nil);

    return adiumGaimAccount;
}

static GaimAccount* accountLookupFromAdiumAccount(id adiumAccount)
{
	return [(CBGaimAccount *)adiumAccount gaimAccount];
}

static AIListContact* contactLookupFromBuddy(GaimBuddy *buddy)
{
	//Get the node's ui_data
	AIListContact *theContact = (buddy ? (AIListContact *)buddy->node.ui_data : nil);

	//If the node does not have ui_data yet, we need to create a contact and associate it
	if (!theContact && buddy){
		NSString	*name;
		GaimAccount	*account;
		const char	*normalized;
		
		account = buddy->account;
		normalized = gaim_normalize(account, buddy->name);
//		GaimDebug(@"contactLookupfromBuddy: Normalized %s to %s",buddy->name,normalized);
		name  = [NSString stringWithUTF8String:normalized];

		theContact = [accountLookup(buddy->account) mainThreadContactWithUID:name];
		
		//Associate the handle with ui_data and the buddy with our statusDictionary
		buddy->node.ui_data = [theContact retain];
	}
	
	return theContact;
}

static AIListContact* contactLookupFromIMConv(GaimConversation *conv)
{
	
}

static AIChat* chatLookupFromConv(GaimConversation *conv)
{
	AIChat *chat;
	
	chat = (AIChat *)conv->ui_data;
	if (!chat){
		NSString *name = [NSString stringWithUTF8String:conv->name];
		
		chat = [accountLookup(conv->account) mainThreadChatWithName:name];

		[chatDict setObject:[NSValue valueWithPointer:conv] forKey:[chat uniqueChatID]];
		conv->ui_data = [chat retain];
	}

	return chat;
}


static AIChat* existingChatLookupFromConv(GaimConversation *conv)
{
	return((conv ? conv->ui_data : nil));
}

static AIChat* imChatLookupFromConv(GaimConversation *conv)
{
	AIChat			*chat;
	
	chat = (AIChat *)conv->ui_data;

	if (!chat){
		//No chat is associated with the IM conversation
		AIListContact   *sourceContact;
		GaimBuddy		*buddy;
		GaimGroup		*group;
		GaimAccount		*account;
		char			*name;
		
		account = conv->account;
//		GaimDebug (@"%x conv->name %s; normalizes to %s",account,conv->name,gaim_normalize(account,conv->name));
		name = g_strdup(gaim_normalize(account, conv->name));
		
		//First, find the GaimBuddy with whom we are conversing
		buddy = gaim_find_buddy(account, name);
		if (!buddy) {
			GaimDebug (@"imChatLookupFromConv: Creating %s %s",account->username,name);
			//No gaim_buddy corresponding to the conv->name is on our list, so create one
			buddy = gaim_buddy_new(account, name, NULL);	//create a GaimBuddy
			group = gaim_find_group(_(GAIM_ORPHANS_GROUP_NAME));		//get the GaimGroup
			if (!group) {												//if the group doesn't exist yet
				group = gaim_group_new(_(GAIM_ORPHANS_GROUP_NAME));		//create the GaimGroup
				gaim_blist_add_group(group, NULL);						//add it gaimside
			}
			gaim_blist_add_buddy(buddy, NULL, group, NULL);     //add the buddy to the gaimside list
			
//#warning Must add to serverside list to get status updates.  Need to remove when the chat closes or the account disconnects. Possibly want to use some sort of hidden Adium group for this.
//			serv_add_buddy(account->gc, buddy);				//add it to the serverside list
		}
		
		NSCAssert(buddy != nil, @"buddy was nil");
		
		sourceContact = contactLookupFromBuddy(buddy);

		// Need to start a new chat, associating with the GaimConversation
		chat = [accountLookup(account) mainThreadChatWithContact:sourceContact];
		
		//Associate the GaimConversation with the AIChat
		[chatDict setObject:[NSValue valueWithPointer:conv] forKey:[chat uniqueChatID]];
		conv->ui_data = [chat retain];
		
		g_free(name);
	}

	return chat;	
}

static GaimConversation* convLookupFromChat(AIChat *chat, id adiumAccount)
{
	GaimConversation	*conv = [[chatDict objectForKey:[chat uniqueChatID]] pointerValue];
	GaimAccount			*account = accountLookupFromAdiumAccount(adiumAccount);
	
	if (!conv && adiumAccount){
		AIListObject *listObject = [chat listObject];
		
		//If we have a listObject, we are dealing with a one-on-one chat, so proceed accordingly
		if (listObject){
			char *destination;
			
			destination = g_strdup(gaim_normalize(account, [[listObject UID] UTF8String]));
			
			conv = gaim_conversation_new(GAIM_CONV_IM,account, destination);
			
			//associate the AIChat with the gaim conv
			imChatLookupFromConv(conv);
			
			g_free(destination);
			
		}else{
			//Otherwise, we have a multiuser chat.
			
			//All multiuser chats should have a non-nil name.
			NSString	*chatName = [chat name];
			if (chatName){
				const char *name = [chatName UTF8String];
				
				/*
				 Look for an existing gaimChat.  If we find one, our job is complete.
				 
				 We will never find one if we are joining a chat on our own (via the Join Chat dialogue).
				 
				 We should never get to this point if we were invited to a chat, as chatLookupFromConv(),
				 which was called when we accepted the invitation and got the chat information from Gaim,
				 will have associated the GaimConversation with the chat and we would have stopped after
				 [[chatDict objectForKey:[chat uniqueChatID]] pointerValue] above.
				 
				 However, there's no reason not to check just in case.
				 */
				GaimChat *gaimChat = gaim_blist_find_chat (account, name);
				if (!gaimChat){
					
					/*
					 If we don't have a GaimChat with this name on this account, we need to create one.
					 Our chat, which should have been created via the Adium Join Chat API, should have
					 a ChatCreationInfo status object with the information we need to ask Gaim to
					 perform the join.
					 */
					NSDictionary	*chatCreationInfo = [chat statusObjectForKey:@"ChatCreationInfo"];
					
					GaimDebug (@"Creating a chat.");
#warning Not all prpls support the below method for chat creation.  Need prpl-specific possibilites.
					GHashTable				*components;
					
					//Prpl Info
					GaimConnection			*gc = gaim_account_get_connection(account);
					GList					*list, *tmp;
					struct proto_chat_entry *pce;
					
					//Create a hash table	
					components = g_hash_table_new_full(g_str_hash, g_str_equal,
													   g_free, g_free);
					
					/*
					 Get the chat_info for our desired account.  This will be a GList of proto_chat_entry
					 objects, each of which has a label and identifier.  Each may also have is_int, with a minimum
					 and a maximum integer value.
					 */
					list = (GAIM_PLUGIN_PROTOCOL_INFO(gc->prpl))->chat_info(gc);
					
					// DEBUG: If this is false, we don't even try to join.
					BOOL shouldTryToJoin = YES;
					
					//Look at each proto_chat_entry in the list and put it in the hash table
					//The hash table should contain char* objects created via a g_strdup method
					for (tmp = list; tmp; tmp = tmp->next)
					{
						pce = tmp->data;
						char	*identifier = g_strdup(pce->identifier);
						char	*valueUTF8String = nil;
						
						if (!(pce->is_int)){
							NSString	*value = [chatCreationInfo objectForKey:[NSString stringWithUTF8String:identifier]];
							if (value){
								GaimDebug (@"$$$$ not int: added %s:%@ to chat info",identifier,value);
								valueUTF8String = g_strdup([value UTF8String]);
							}else{
								GaimDebug (@"String: Danger, Will Robinson! %s is in the proto_info but can't be found in %@",identifier,chatCreationInfo);
								shouldTryToJoin = NO;
							}
						}else{
							NSNumber	*value = [chatCreationInfo objectForKey:[NSString stringWithUTF8String:identifier]];
							if (value){
								GaimDebug (@"$$$$  is int: added %s:%@ to chat info",identifier,value);
								valueUTF8String = g_strdup_printf("%d",[value intValue]);
							}else{
								GaimDebug (@"Int: Danger, Will Robinson! %s is in the proto_info but can't be found in %@",identifier,chatCreationInfo);
								shouldTryToJoin = NO;
							}							
						}
						
						//Store our chatCreationInfo-supplied value in the compnents hash table
						g_hash_table_replace(components,
											 identifier,
											 valueUTF8String);
					}
					
					/*
					 //Add the GaimChat to our local buddy list?
					gaimChat = gaim_chat_new(account,
											 name,
											 components);
					if ((group = gaim_find_group(group_name)) == NULL) {
						group = gaim_group_new(group_name);
						gaim_blist_add_group(group, NULL);
					}
					
					if (gaimChat != NULL) {
						gaim_blist_add_chat(gaimChat, group, NULL);
					}
					*/
					
					//Associate our chat with the libgaim conversation
					//NSLog(@"associating the gaimconv");
					
					if( shouldTryToJoin ) {
					//Join the chat serverside - the GHsahTable components, couple with the originating GaimConnect,
					//now contains all the information the prpl will need to process our request.
						GaimDebug (@"In the event of an emergency, your GHashTable may be used as a flotation device...");
						serv_join_chat(gc, components);
					} else {
						//NSLog(@"#### Bailing out of group chat");
					}
					//Evan: I think we'll return a nil conv here.. and then Gaim will call us back with a conv...
					//and then we'll associate it with a chat later.  That's quite possibly wrong though...
/*
					GaimConversation 	*conv = gaim_conversation_new(GAIM_CONV_CHAT, account, name);

					chatLookupFromConv(conv);
 */
					//CLear the chat's status object.   This needs to be done in the main thread.
					//Need a number version!
					/*
					[chat mainThreadPerformSelector:@selector(setStatusObject:forKey:notify:)
										 withObject:nil
										 withObject:@"ChatCreationInfo"
										 withObject:notifyNever];
					 */
				}
			}
		}
	}
	
	return conv;
}

static GaimConversation* existingConvLookupFromChat(AIChat *chat)
{
	return (GaimConversation *)[[chatDict objectForKey:[chat uniqueChatID]] pointerValue];
}


#pragma mark Debug
// Debug ------------------------------------------------------------------------------------------------------
#if (GAIM_DEBUG)
static void adiumGaimDebugPrint(GaimDebugLevel level, const char *category, const char *format, va_list args)
{
	gchar *arg_s = g_strdup_vprintf(format, args); //NSLog sometimes chokes on the passed args, so we'll use vprintf
	
/*	AILog(@"%x: (Debug: %s) %s",[NSRunLoop currentRunLoop], category, arg_s); */
	//Log error
	if(!category) category = "general"; //Category can be nil

	AILog(@"(Libgaim: %s) %s",category, arg_s);
	
	g_free(arg_s);
}

static GaimDebugUiOps adiumGaimDebugOps = {
    adiumGaimDebugPrint
};
#endif

#pragma mark Connection
// Connection ------------------------------------------------------------------------------------------------------
static void adiumGaimConnConnectProgress(GaimConnection *gc, const char *text, size_t step, size_t step_count)
{
    GaimDebug (@"Connecting: gc=0x%x (%s) %i / %i", gc, text, step, step_count);
	
	NSNumber	*connectionProgressPrecent = [NSNumber numberWithFloat:((float)step/(float)(step_count-1))];
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionProgressStep:percentDone:)
										 withObject:[NSNumber numberWithInt:step]
										 withObject:connectionProgressPrecent];
}

static void adiumGaimConnConnected(GaimConnection *gc)
{
    GaimDebug (@"Connected: gc=%x", gc);

	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionConnected)];
}

static void adiumGaimConnDisconnected(GaimConnection *gc)
{
    GaimDebug (@"Disconnected: gc=%x", gc);
//    if (_accountDict == nil) // if this has been destroyed, unloadPlugin has already been called
//        return;
    [accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionDisconnected)];
}

static void adiumGaimConnNotice(GaimConnection *gc, const char *text)
{
    GaimDebug (@"Connection Notice: gc=%x (%s)", gc, text);
	
	NSString *connectionNotice = [NSString stringWithUTF8String:text];
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionNotice:)
										 withObject:connectionNotice];
}

static void adiumGaimConnReportDisconnect(GaimConnection *gc, const char *text)
{
    GaimDebug (@"Connection Disconnected: gc=%x (%s)", gc, text);
	
	NSString	*disconnectError = [NSString stringWithUTF8String:text];
    [accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionReportDisconnect:)
										 withObject:disconnectError];
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

}

static void adiumGaimBlistShow(GaimBuddyList *list)
{
	
}

static void adiumGaimBlistUpdate(GaimBuddyList *list, GaimBlistNode *node)
{
	if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
		GaimBuddy *buddy = (GaimBuddy*)node;
		
		AIListContact *theContact = contactLookupFromBuddy(buddy);
		
		//Group changes - gaim buddies start off in no group, so this is an important update for us
		//We also use this opportunity to check the contact's name against its formattedUID
		if(![theContact remoteGroupName]){
			GaimGroup	*g = gaim_find_buddys_group(buddy);
			NSString	*groupName;
			NSString	*contactName;

			groupName = ((g && g->name) ?
						 [NSString stringWithUTF8String:g->name] :
						 nil);
			contactName = [NSString stringWithUTF8String:buddy->name];
				
			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:toGroupName:contactName:)
													withObject:theContact
													withObject:groupName
													withObject:contactName];
		}
		
		const char	*alias = gaim_buddy_get_alias(buddy);
		if (alias){
			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:toAlias:)
													withObject:theContact
													withObject:[NSString stringWithUTF8String:alias]];
		}
	}
}

//A buddy was removed from the list
static void adiumGaimBlistRemove(GaimBuddyList *list, GaimBlistNode *node)
{
    NSCAssert(node != nil, @"BlistRemove on null node");
    if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
		GaimBuddy *buddy = (GaimBuddy*) node;

		[accountLookup(buddy->account) mainPerformSelector:@selector(removeContact:)
												withObject:contactLookupFromBuddy(buddy)];
		
		//Clear the ui_data
		[(id)buddy->node.ui_data release]; buddy->node.ui_data = NULL;
    }
}

static void adiumGaimBlistDestroy(GaimBuddyList *list)
{
    //Here we're responsible for destroying what we placed in list's ui_data earlier
    GaimDebug (@"adiumGaimBlistDestroy");
}

static void adiumGaimBlistSetVisible(GaimBuddyList *list, gboolean show)
{
    GaimDebug (@"adiumGaimBlistSetVisible: %i",show);
}

static void adiumGaimBlistRequestAddBuddy(GaimAccount *account, const char *username, const char *group, const char *alias)
{
	[accountLookup(account) mainPerformSelector:@selector(requestAddContactWithUID:)
									 withObject:[NSString stringWithUTF8String:username]];
}

static void adiumGaimBlistRequestAddChat(GaimAccount *account, GaimGroup *group, const char *alias, const char *name)
{
    GaimDebug (@"adiumGaimBlistRequestAddChat");
}

static void adiumGaimBlistRequestAddGroup(void)
{
    GaimDebug (@"adiumGaimBlistRequestAddGroup");
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
	if (buddy){
		SEL updateSelector = nil;
		id data = nil;
		
		AIListContact   *theContact = contactLookupFromBuddy(buddy);
		
		switch(event){
			case GAIM_BUDDY_SIGNON: {
				updateSelector = @selector(updateSignon:withData:);
				break;
			}
			case GAIM_BUDDY_SIGNOFF: {
				updateSelector = @selector(updateSignoff:withData:);
				break;
			}
			case GAIM_BUDDY_SIGNON_TIME: {
				updateSelector = @selector(updateSignonTime:withData:);
				if (buddy->signon){
					data = [NSDate dateWithTimeIntervalSince1970:buddy->signon];
				}
				break;
			}
			case GAIM_BUDDY_AWAY:{
				updateSelector = @selector(updateWentAway:withData:);
				break;
			}
			case GAIM_BUDDY_AWAY_RETURN: {
				updateSelector = @selector(updateAwayReturn:withData:);
				break;
			}
			case GAIM_BUDDY_IDLE:
			case GAIM_BUDDY_IDLE_RETURN: {
				if (buddy->idle != 0){
					updateSelector = @selector(updateWentIdle:withData:);

					if (buddy->idle != -1){
						data = [NSDate dateWithTimeIntervalSince1970:buddy->idle];
					}
				}else{
					updateSelector = @selector(updateIdleReturn:withData:);	
				}
				break;
			}
			case GAIM_BUDDY_EVIL: {
				updateSelector = @selector(updateEvil:withData:);
				if (buddy->evil){
					data = [NSNumber numberWithInt:buddy->evil];
				}
				break;
			}
			case GAIM_BUDDY_ICON: {
				GaimBuddyIcon *buddyIcon = gaim_buddy_get_icon(buddy);
				updateSelector = @selector(updateIcon:withData:);
				
				if (buddyIcon){
					const char  *iconData;
					size_t		len;
					
					iconData = gaim_buddy_icon_get_data(buddyIcon, &len);
					
					if (iconData && len){
						data = [NSData dataWithBytes:iconData
											  length:len];
					}
				}
				break;
			}
			default: {
				data = [NSNumber numberWithInt:event];
			}
		}
		
		if (updateSelector){
			[accountLookup(buddy->account) mainPerformSelector:updateSelector
													withObject:theContact
													withObject:data];
		}else{
			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:forEvent:)
													withObject:theContact
													withObject:data];
		}
	}
}

- (void)configureSignals
{
//	void *accounts_handle = gaim_accounts_get_handle();
	void *blist_handle = gaim_blist_get_handle();
	void *handle       = gaim_adium_get_handle();
	
	//Idle
	gaim_signal_connect(blist_handle, "buddy-idle",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_IDLE));
	gaim_signal_connect(blist_handle, "buddy-idle-updated",
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
	
	//Signon / Signoff
	gaim_signal_connect(blist_handle, "buddy-signed-on",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNON));
	gaim_signal_connect(blist_handle, "buddy-signon",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNON_TIME));
	gaim_signal_connect(blist_handle, "buddy-signed-off",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_SIGNOFF));
	
	//DirectIM
	gaim_signal_connect(blist_handle, "buddy-direct-im-connected",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_DIRECTIM_CONNECTED));
	//DirectIM
	gaim_signal_connect(blist_handle, "buddy-direct-im-disconnected",
						handle, GAIM_CALLBACK(buddy_event_cb),
						GINT_TO_POINTER(GAIM_BUDDY_DIRECTIM_DISCONNECTED));
}

#pragma mark Conversation
// Conversation ------------------------------------------------------------------------------------------------------
static void adiumGaimConvDestroy(GaimConversation *conv)
{
	//Gaim is telling us a conv was destroyed.  We've probably already cleaned up, but be sure in case gaim calls this
	//when we don't ask it to (for example if we are summarily kicked from a chat room and gaim closes the 'window').
	AIChat *chat;
	
	chat = (AIChat *)conv->ui_data;

	//Chat will be nil if we've already cleaned up, at which point no further action is needed.
	if (chat){
		//The chat's uniqueChatID may have changed before we got here.  Make sure we are talking about the proper conv
		//before removing its NSValue from the chatDict
		if (conv == [[chatDict objectForKey:[chat uniqueChatID]] pointerValue]){
			[chatDict removeObjectForKey:[chat uniqueChatID]];
		}			

		[chat release];
		conv->ui_data = nil;
	}
}

static void adiumGaimConvWriteChat(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	//We only care about this if it does not have the GAIM_MESSAGE_SEND flag, which is set if Gaim is sending a sent message back to us
	if((flags & GAIM_MESSAGE_SEND) == 0){
		NSDictionary	*messageDict;
		NSString		*messageString;
		
		messageString = [NSString stringWithUTF8String:message];
		
		messageDict = [NSDictionary dictionaryWithObjectsAndKeys:[AIHTMLDecoder decodeHTML:messageString],@"AttributedMessage",
			[NSString stringWithUTF8String:who],@"Source",
			[NSNumber numberWithInt:flags],@"GaimMessageFlags",
			[NSDate dateWithTimeIntervalSince1970:mtime],@"Date",nil];
		
		[accountLookup(conv->account) mainPerformSelector:@selector(receivedMultiChatMessage:inChat:)
											   withObject:messageDict
											   withObject:chatLookupFromConv(conv)];
	}
}

static void adiumGaimConvWriteIm(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	//We only care about this if it does not have the GAIM_MESSAGE_SEND flag, which is set if Gaim is sending a sent message back to us
	if((flags & GAIM_MESSAGE_SEND) == 0){
		NSDictionary			*messageDict;
		NSObject<AdiumGaimDO>	*adiumAccount = accountLookup(conv->account);
		NSString				*messageString;
		AIChat					*chat;
		
		messageString = [NSString stringWithUTF8String:message];
		chat = imChatLookupFromConv(conv);
		
		GaimDebug (@"adiumGaimConvWriteIm: Received %@ from %@",messageString,[[chat listObject] UID]);
		
		//Process any gaim imgstore references into real HTML tags pointing to real images
		if ([messageString rangeOfString:@"<IMG ID=\"" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			messageString = [myself _processGaimImagesInString:messageString forAdiumAccount:adiumAccount];
		}
		
		messageDict = [NSDictionary dictionaryWithObjectsAndKeys:[AIHTMLDecoder decodeHTML:messageString],@"AttributedMessage",
			[NSNumber numberWithInt:flags],@"GaimMessageFlags",
			[NSDate dateWithTimeIntervalSince1970:mtime],@"Date",nil];
		
		[adiumAccount mainPerformSelector:@selector(receivedIMChatMessage:inChat:)
							   withObject:messageDict
							   withObject:chat];
	}
}

static void adiumGaimConvWriteConv(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	AIChat	*chat = nil;
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){
		chat = existingChatLookupFromConv(conv);
	}else if (gaim_conversation_get_type(conv) == GAIM_CONV_IM){
		chat = imChatLookupFromConv(conv);
	}
	
	if (chat){
		if (flags & GAIM_MESSAGE_SYSTEM){
			NSString			*messageString = [NSString stringWithUTF8String:message];
			if (messageString){
				AIChatUpdateType	updateType = -1;
				
				if([messageString rangeOfString:@"timed out"].location != NSNotFound){
					updateType = AIChatTimedOut;
				}else if([messageString rangeOfString:@"closed the conversation"].location != NSNotFound){
					updateType = AIChatClosedWindow;
				}
				
				if (updateType != -1){
					[accountLookup(conv->account) mainPerformSelector:@selector(updateForChat:type:)
															withObject:chat
															withObject:[NSNumber numberWithInt:updateType]];
				}
			}
		}else if (flags & GAIM_MESSAGE_ERROR){
			NSString			*messageString = [NSString stringWithUTF8String:message];
			if (messageString){
				AIChatErrorType	errorType = -1;
				
				if([messageString rangeOfString:@"Unable to send message"].location != NSNotFound){
					if(([messageString rangeOfString:@"Not logged in"].location != NSNotFound) ||
					   ([messageString rangeOfString:@"is not online"].location != NSNotFound)){
						errorType = AIChatUserNotAvailable;

					}else if(([messageString rangeOfString:@"Refused by client"].location != NSNotFound) ||
							 ([messageString rangeOfString:@"message is too large"].location != NSNotFound)){
						//XXX - there may be other conditions, but this seems the most common so that's how we'll classify it
						errorType = AIChatMessageSendingTooLarge;
					}

				}else if([messageString rangeOfString:@"You missed"].location != NSNotFound){
					if (([messageString rangeOfString:@"because they were too large"].location != NSNotFound) ||
						([messageString rangeOfString:@"because it was too large"].location != NSNotFound)){
						//The actual message when on AIM via libgaim is "You missed 2 messages" but this is a lie.
						errorType = AIChatMessageReceivingMissedTooLarge;
						
					}else if(([messageString rangeOfString:@"because it was invalid"].location != NSNotFound) ||
							  ([messageString rangeOfString:@"because they were invalid"].location != NSNotFound)){
						errorType = AIChatMessageReceivingMissedInvalid;
						
					}else if([messageString rangeOfString:@"because the rate limit has been exceeded"].location != NSNotFound){
						errorType = AIChatMessageReceivingMissedRateLimitExceeded;
						
					}else if([messageString rangeOfString:@"because he/she was too evil"].location != NSNotFound){
						errorType = AIChatMessageReceivingMissedRemoteIsTooEvil;
						
					}else if([messageString rangeOfString:@"because you are too evil"].location != NSNotFound){
						errorType = AIChatMessageReceivingMissedLocalIsTooEvil;
						
					}
					
				}else if([messageString isEqualToString:@"Command failed"]){
					errorType = AIChatCommandFailed;
					
				}else if([messageString isEqualToString:@"Wrong number of arguments"]){
					errorType = AIChatInvalidNumberOfArguments;
					
				}else if([messageString rangeOfString:@"transfer"].location != NSNotFound){
					//Ignore the transfer errors; we will handle them locally
					errorType = -2;
					
				}else if ([messageString rangeOfString:@"User information not available"].location != NSNotFound){
					//Ignore user information errors; they are irrelevent
					errorType = -2;
				}

				if (errorType == -1){
					errorType = AIChatUnknownError;
				}
				
				if (errorType != -2) {
					[accountLookup(conv->account) mainPerformSelector:@selector(errorForChat:type:)
														   withObject:chat
														   withObject:[NSNumber numberWithInt:errorType]];
				}
				
				GaimDebug (@"*** Conversation error (%@): %@",
						   ([chat listObject] ? [[chat listObject] UID] : [chat name]),messageString);
			}
		}
	}
}

static void adiumGaimConvChatAddUser(GaimConversation *conv, const char *user, gboolean new_arrival)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){
		GaimDebug (@"adiumGaimConvChatAddUser: CHAT: add %s",user);
		//We pass the name as given, not normalized, so we can use its formatting as a formattedUID.
		//The account is responsible for normalization if needed.
		[accountLookup(conv->account) mainPerformSelector:@selector(addUser:toChat:)
											   withObject:[NSString stringWithUTF8String:user]
											   withObject:existingChatLookupFromConv(conv)];
	}else{
		GaimDebug (@"adiumGaimConvChatAddUser: IM: add %s",user);
	}

}

static void adiumGaimConvChatAddUsers(GaimConversation *conv, GList *users)
{
//	[accountLookup(conv->account) accountConvAddedUsers:users inConversation:conv];
}

static void adiumGaimConvChatRenameUser(GaimConversation *conv, const char *oldName, const char *newName)
{
	GaimDebug (@"adiumGaimConvChatRenameUser");
}

static void adiumGaimConvChatRemoveUser(GaimConversation *conv, const char *user)
{
 	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){
		GaimDebug (@"adiumGaimConvChatRemoveUser: CHAT: remove %s",user);

		[accountLookup(conv->account) mainPerformSelector:@selector(removeUser:fromChat:)
											   withObject:[NSString stringWithUTF8String:gaim_normalize(conv->account, user)]
											   withObject:existingChatLookupFromConv(conv)];
	}else{
		GaimDebug (@"adiumGaimConvChatRemoveUser: IM: remove %s",user);
	}
	
}

static void adiumGaimConvChatRemoveUsers(GaimConversation *conv, GList *users)
{
//	[accountLookup(conv->account) accountConvRemovedUsers:users inConversation:conv];
}

static void adiumGaimConvSetTitle(GaimConversation *conv, const char *title)
{
    GaimDebug (@"adiumGaimConvSetTitle");
}

static void adiumGaimConvUpdateUser(GaimConversation *conv, const char *user)
{
	GaimDebug (@"adiumGaimConvUpdateUser: %s",user);
}

static void adiumGaimConvUpdateProgress(GaimConversation *conv, float percent)
{
    GaimDebug (@"adiumGaimConvUpdateProgress %f",percent);
}

//This isn't a function we want Gaim doing anything with, I don't think
static gboolean adiumGaimConvHasFocus(GaimConversation *conv)
{
	return NO;
}

static void adiumGaimConvUpdated(GaimConversation *conv, GaimConvUpdateType type)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){
		[accountLookup(conv->account) mainPerformSelector:@selector(convUpdateForChat:type:)
											withObject:existingChatLookupFromConv(conv)
											   withObject:[NSNumber numberWithInt:type]];
		
	}else if (gaim_conversation_get_type(conv) == GAIM_CONV_IM){
		GaimConvIm  *im = gaim_conversation_get_im_data(conv);
		switch (type) {
			case GAIM_CONV_UPDATE_TYPING: {
				
				AITypingState typingState;
				
				switch (gaim_conv_im_get_typing_state(im)){
					case GAIM_TYPING:
						typingState = AITyping;
						break;
					case GAIM_NOT_TYPING:
						typingState = AINotTyping;
						break;
					case GAIM_TYPED:
						typingState = AIEnteredText;
						break;
				}
				
				NSNumber	*typingStateNumber = [NSNumber numberWithInt:typingState];
				
				[accountLookup(conv->account) mainPerformSelector:@selector(typingUpdateForIMChat:typing:)
													   withObject:imChatLookupFromConv(conv)
													   withObject:typingStateNumber];
				break;
			}
			case GAIM_CONV_UPDATE_AWAY: {
				//If the conversation update is UPDATE_AWAY, it seems to suppress the typing state being updated
				//Reset gaim's typing tracking, then update to receive a GAIM_CONV_UPDATE_TYPING message
				gaim_conv_im_set_typing_state(im, GAIM_NOT_TYPING);
				gaim_conv_im_update_typing(im);
				break;
			}
			default:
				break;
		}
	}
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
	adiumGaimConvUpdateUser,
    adiumGaimConvUpdateProgress,
	adiumGaimConvHasFocus,
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
        GaimDebug (@"adiumGaimConvWindowShow");
}

static void adiumGaimConvWindowHide(GaimConvWindow *win)
{
    GaimDebug (@"adiumGaimConvWindowHide");
}

static void adiumGaimConvWindowRaise(GaimConvWindow *win)
{
	    GaimDebug (@"adiumGaimConvWindowRaise");
}

static void adiumGaimConvWindowFlash(GaimConvWindow *win)
{
}

static void adiumGaimConvWindowSwitchConv(GaimConvWindow *win, unsigned int index)
{
    GaimDebug (@"adiumGaimConvWindowSwitchConv");
}

static void adiumGaimConvWindowAddConv(GaimConvWindow *win, GaimConversation *conv)
{
	GaimDebug (@"adiumGaimConvWindowAddConv");
	
	//Pass chats along to the account
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){

		AIChat *chat = chatLookupFromConv(conv);
			
		[accountLookup(conv->account) mainPerformSelector:@selector(addChat:)
											   withObject:chat];
	}
}

static void adiumGaimConvWindowRemoveConv(GaimConvWindow *win, GaimConversation *conv)
{
	GaimDebug (@"adiumGaimConvWindowRemoveConv");
}

static void adiumGaimConvWindowMoveConv(GaimConvWindow *win, GaimConversation *conv, unsigned int newIndex)
{
    GaimDebug (@"adiumGaimConvWindowMoveConv");
}

static int adiumGaimConvWindowGetActiveIndex(const GaimConvWindow *win)
{
    GaimDebug (@"adiumGaimConvWindowGetActiveIndex");
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
	GaimDebug (@"adiumGaimRoomlistNew");
}
static void adiumGaimRoomlistSetFields(GaimRoomlist *list, GList *fields)
{
}
static void adiumGaimRoomlistAddRoom(GaimRoomlist *list, GaimRoomlistRoom *room)
{
	GaimDebug (@"adiumGaimRoomlistAddRoom");
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


// Webcam ----------------------------------------------------------------------------------------------------------
#pragma mark Webcam
#if ENABLE_WEBCAM
static void adiumGaimWebcamNew(GaimWebcam *gwc)
{
	NSLog(@"adiumGaimWebcamNew");
//	GaimGtkWebcam *c;
//	char *tmp;
//	
//	c = g_new0(GaimGtkWebcam, 1);
//	
//	gwc->ui_data = c;
//	c->gwc = gwc;
//	
//	c->button = gaim_pixbuf_button_from_stock(_("Close"), GTK_STOCK_CLOSE, GAIM_BUTTON_HORIZONTAL);
//	c->vbox = gtk_vbox_new(FALSE, 0);
//	gtk_box_pack_end_defaults(GTK_BOX(c->vbox), GTK_WIDGET(c->button));
//	
//	c->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
//	tmp = g_strdup_printf(_("%s's Webcam"), gwc->name);
//	gtk_window_set_title(GTK_WINDOW(c->window), tmp);
//	g_free(tmp);
//	
//	gtk_container_add(GTK_CONTAINER(c->window), c->vbox);
//	
//	g_signal_connect(G_OBJECT(c->button), "clicked",
//					 G_CALLBACK(gaim_gtk_webcam_close_clicked), c);
//	
//	g_signal_connect(G_OBJECT(c->window), "destroy",
//					 G_CALLBACK(gaim_gtk_webcam_destroy), c);
//	
//	c->image = gtk_image_new_from_stock(GAIM_STOCK_LOGO, gtk_icon_size_from_name(GAIM_ICON_SIZE_LOGO));
//	gtk_box_pack_start_defaults(GTK_BOX(c->vbox), c->image);
//	gtk_widget_show(GTK_WIDGET(c->image));
//	
//	gtk_widget_show(GTK_WIDGET(c->button));
//	gtk_widget_show(GTK_WIDGET(c->vbox));
//	gtk_widget_show(GTK_WIDGET(c->window));
}

static NSMutableData	*frameData = nil;

static void adiumGaimWebcamUpdate(GaimWebcam *gwc,
								   const unsigned char *image, unsigned int size,
								   unsigned int timestamp, unsigned int id)
{
	NSLog(@"adiumGaimWebcamUpdate (Frame %i , %i bytes)", id, size);
	
	if(!frameData){
		frameData = [[NSMutableData alloc] init];		
	}
	
	[frameData appendBytes:image length:size];
	
//	GaimGtkWebcam *cam;
//	WCFrame *f;
//	GError *e = NULL;
//	
//	gaim_debug_misc("gtkwebcam", "Got %d bytes of frame %d.\n", size, id);
//	
//	cam = gwc->ui_data;
//	if (!cam)
//		return;
//	
//	f = wcframe_find_by_no(cam->frames, id);
//	if (!f) {
//		f = wcframe_new(cam, id);
//		cam->frames = g_list_append(cam->frames, f);
//	}
//	
//	if (!gdk_pixbuf_loader_write(f->loader, image, size, &e)) {
//		gaim_debug(GAIM_DEBUG_MISC, "gtkwebcam", "gdk_pixbuf_loader_write failed:%s\n", e->message);
//		g_error_free(e);
//	}
}

static void adiumGaimWebcamFrameFinished(GaimWebcam *wc, unsigned int id)
{
	NSLog(@"adiumGaimWebcamFrameFinished");
	
	NSBitmapImageRep *rep;
	rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:[frameData bytes]
												  pixelsWide:320
												  pixelsHigh:240
											   bitsPerSample:8
											 samplesPerPixel:3
													hasAlpha:NO
													isPlanar:NO
											  colorSpaceName:NSCalibratedRGBColorSpace
												 bytesPerRow:0
												bitsPerPixel:0]; 
	
	NSLog(@"rep = %@",rep);
#warning we are in a gthread because of my idle hack in the codec, so we cant do anything in here...
//	[[AIObject sharedAdiumInstance] performSelectorOnMainThread:@selector(showImage:) withObject:rep waitUntilDone:NO];

//	NSImage *tmp = [[NSImage alloc] init];
//	[tmp addRepresentation:rep];
	

	
	
	
	
//	[rep release];
	[frameData release]; frameData = nil;
	
	
	
	
	
//	NSLog(@"Bitmap?: %@",[NSImage initWithData:frameData]);
	
//	GaimGtkWebcam *cam;
//	WCFrame *f;
//	
//	cam = wc->ui_data;
//	if (!cam)
//		return;
//	f = wcframe_find_by_no(cam->frames, id);
//	if (!f)
//		return;
//	
//	gdk_pixbuf_loader_close(f->loader, NULL);
//	f->loader = NULL;
}

static void adiumGaimWebcamClose(GaimWebcam *gwc)
{
	NSLog(@"adiumGaimWebcamClose");
//	GaimGtkWebcam *cam;
//	
//	cam = gwc->ui_data;
//	if (!cam)
//		return;
//	
//	cam->gwc = NULL;
//	gwc->ui_data = NULL;
}

static void adiumGaimWebcamGotInvite(GaimConnection *gc, const gchar *who)
{
	NSLog(@"adiumGaimWebcamGotInvite");
	
	gaim_webcam_invite_accept(gc, who);

	
//	gchar *str = g_strdup_printf(_("%s has invited you (%s) to view their Webcam."), who,
//								 gaim_connection_get_display_name(gc));
//	struct _ggwc_gcaw *g = g_new0(struct _ggwc_gcaw, 1);
//	
//	g->gc = gc;
//	g->who = g_strdup(who);
//	
//	gaim_request_action(gc, _("Webcam Invite"), str, _("Will you accept this invitation?"), 0,
//						g, 2, _("Accept"), G_CALLBACK(_invite_accept), _("Decline"),
//						G_CALLBACK(_invite_decline));
//	
//	g_free(str);
}

static struct gaim_webcam_ui_ops adiumGaimWebcamOps =
{
	adiumGaimWebcamNew,
	adiumGaimWebcamUpdate,
	adiumGaimWebcamFrameFinished,
	adiumGaimWebcamClose,
	adiumGaimWebcamGotInvite
};
#endif

#pragma mark Notify
// Notify ----------------------------------------------------------------------------------------------------------
static void *adiumGaimNotifyMessage(GaimNotifyMsgType type, const char *title, const char *primary, const char *secondary, GCallback cb,void *userData)
{
    //Values passed can be null
    GaimDebug (@"adiumGaimNotifyMessage: %@: %s: %s, %s", myself, title, primary, secondary);
	return ([myself handleNotifyMessageOfType:type withTitle:title primary:primary secondary:secondary]);
}

static void *adiumGaimNotifyEmails(size_t count, gboolean detailed, const char **subjects, const char **froms, const char **tos, const char **urls, GCallback cb,void *userData)
{
    //Values passed can be null
    return([myself handleNotifyEmails:count detailed:detailed subjects:subjects froms:froms tos:tos urls:urls]);
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
    return(gaim_adium_get_handle());
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
	
    return(gaim_adium_get_handle());
}

static void *adiumGaimNotifyUri(const char *uri)
{
	if (uri){
		NSURL   *notifyURI = [NSURL URLWithString:[NSString stringWithUTF8String:uri]];
		[[NSWorkspace sharedWorkspace] openURL:notifyURI];
	}

	return(gaim_adium_get_handle());
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

- (void *)handleNotifyMessageOfType:(GaimNotifyType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;
{
    NSString *primaryString = [NSString stringWithUTF8String:primary];
	NSString *secondaryString = secondary ? [NSString stringWithUTF8String:secondary] : nil;
	
	NSString *titleString;
	if (title){
		titleString = [NSString stringWithFormat:@"Adium Notice: %@",[NSString stringWithUTF8String:title]];
	}else{
		titleString = AILocalizedString(@"Adium : Notice", nil);
	}
	
	NSString *errorMessage = nil;
	NSString *description = nil;
	
	if (primaryString && ([primaryString rangeOfString:@"Already there"].location != NSNotFound)){
		return;
	}
	
	//Suppress notification warnings we have no interest in seeing
	if (secondaryString){
		if (([secondaryString rangeOfString:@"Could not add the buddy 1 for an unknown reason"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Your screen name is currently formatted as follows"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Error reading from Switchboard server"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"0x001a: Unknown error"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Not supported by host"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Not logged in"].location != NSNotFound)){
			return;
		}
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
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ denied authorization:","User deined authorization; the next line has an explanation."),targetUserName];
		description = reason;

    }else if ([primaryString rangeOfString: @"Authorization Granted"].location != NSNotFound){
		//ICQ Authorization granted
		NSString *targetUserName = [[[[secondaryString componentsSeparatedByString:@" user "] objectAtIndex:1] componentsSeparatedByString:@" has "] objectAtIndex:0];
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ granted authorization.",nil),targetUserName];
	}
	
	GaimDebug (@"sending %@ %@ %@ %@",[adium interfaceController],([errorMessage length] ? errorMessage : primaryString),([description length] ? description : ([secondaryString length] ? secondaryString : @"") ),titleString);
	//If we didn't grab a translated version using AILocalizedString, at least display the English version Gaim supplied
	[[adium interfaceController] mainPerformSelector:@selector(handleMessage:withDescription:withWindowTitle:)
										  withObject:([errorMessage length] ? errorMessage : primaryString)
										  withObject:([description length] ? description : ([secondaryString length] ? secondaryString : @"") )
										  withObject:titleString];
	
	return(gaim_adium_get_handle());
}

- (void *)handleNotifyEmails:(size_t)count detailed:(BOOL)detailed subjects:(const char **)subjects froms:(const char **)froms tos:(const char **)tos urls:(const char **)urls
{
	NSFontManager				*fontManager = [NSFontManager sharedFontManager];
	NSFont						*messageFont = [NSFont messageFontOfSize:11];
	NSMutableParagraphStyle		*centeredParagraphStyle;
	NSMutableAttributedString   *message;
	
	centeredParagraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	[centeredParagraphStyle setAlignment:NSCenterTextAlignment];
	message = [[NSMutableAttributedString alloc] init];
	
	//Title
	NSString		*title;
	NSFont			*titleFont;
	NSDictionary	*titleAttributes;
	
	title = AILocalizedString(@"You have mail!\n",nil);
	titleFont = [fontManager convertFont:[NSFont messageFontOfSize:12]
							 toHaveTrait:NSBoldFontMask];
	titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:titleFont,NSFontAttributeName,
		centeredParagraphStyle,NSParagraphStyleAttributeName,nil];
	
	[message appendAttributedString:[[[NSAttributedString alloc] initWithString:title
																	 attributes:titleAttributes] autorelease]];
	
	//Message
	NSString		*numberMessage;
	NSDictionary	*numberMessageAttributes;
	
	numberMessage = ((count == 1) ? 
					 [NSString stringWithFormat:AILocalizedString(@"%s has 1 new message.",nil), *tos] :
					 [NSString stringWithFormat:AILocalizedString(@"%s has %i new messages.",nil), *tos,count]);
	numberMessageAttributes = [NSDictionary dictionaryWithObjectsAndKeys:messageFont,NSFontAttributeName,
		centeredParagraphStyle,NSParagraphStyleAttributeName,nil];
	
	[message appendAttributedString:[[[NSAttributedString alloc] initWithString:numberMessage
																	 attributes:numberMessageAttributes] autorelease]];
	
	if (count == 1){
		BOOL	haveFroms = (froms != NULL);
		BOOL	haveSubjects = (subjects != NULL);
		
		if (haveFroms || haveSubjects){
			NSFont			*fieldFont;
			NSDictionary	*fieldAttributed, *infoAttributed;
			
			fieldFont =  [fontManager convertFont:messageFont
									  toHaveTrait:NSBoldFontMask];
			fieldAttributed = [NSDictionary dictionaryWithObjectsAndKeys:fieldFont,NSFontAttributeName,nil];
			infoAttributed = [NSDictionary dictionaryWithObjectsAndKeys:messageFont,NSFontAttributeName,nil];
			
			//Skip a line
			[[message mutableString] appendString:@"\n\n"];
			
			if (haveFroms){
				[message appendAttributedString:[[[NSAttributedString alloc] initWithString:AILocalizedString(@"From: ",nil)
																				 attributes:fieldAttributed] autorelease]];
				[message appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(*froms)]
																				 attributes:infoAttributed] autorelease]];
			}
			if (haveFroms && haveSubjects){
				[[message mutableString] appendString:@"\n"];
			}
			if (haveSubjects){
				[message appendAttributedString:[[[NSAttributedString alloc] initWithString:AILocalizedString(@"Subject: ",nil)
																				 attributes:fieldAttributed] autorelease]];
				[message appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(*subjects)]
																				 attributes:infoAttributed] autorelease]];				
			}
		}
	}
	
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:title,@"Title",
		message,@"Message",nil];
	
	if (urls != NULL){
		[infoDict setObject:[NSString stringWithUTF8String:urls[0]] forKey:@"URL"];
	}
	
	[ESGaimNotifyEmailWindowController mainPerformSelector:@selector(showNotifyEmailWindowWithMessage:URL:)
														withObject:message
													   withObject:(urls ? [NSString stringWithUTF8String:urls[0]] : nil)];
	[centeredParagraphStyle release];
	[message release];

	return(gaim_adium_get_handle());
}

#pragma mark Request
// Request ------------------------------------------------------------------------------------------------------
static void *adiumGaimRequestInput(const char *title, const char *primary, const char *secondary, const char *defaultValue, gboolean multiline, gboolean masked, gchar *hint,const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData)
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
	
	[infoDict setObject:[NSNumber numberWithBool:multiline] forKey:@"Multiline"];
	[infoDict setObject:[NSNumber numberWithBool:masked] forKey:@"Masked"];
	
	[ESGaimRequestWindowController performSelectorOnMainThread:@selector(showInputWindowWithDict:)
													withObject:infoDict
												 waitUntilDone:YES];

    return(gaim_adium_get_handle());
}

static void *adiumGaimRequestChoice(const char *title, const char *primary, const char *secondary, unsigned int defaultValue, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData, size_t choiceCount, va_list choices)
{
    GaimDebug (@"adiumGaimRequestChoice");
    return(gaim_adium_get_handle());
}

//Gaim requests the user take an action such as accept or deny a buddy's attempt to add us to her list 
static void *adiumGaimRequestAction(const char *title, const char *primary, const char *secondary, unsigned int default_action,void *userData, size_t actionCount, va_list actions)
{
    int		    i;
	
    NSString	    *titleString = (title ? [NSString stringWithUTF8String:title] : @"");
	NSString		*primaryString = (primary ?  [NSString stringWithUTF8String:primary] : nil);

	if (primaryString && ([primaryString rangeOfString: @"wants to send you"].location != NSNotFound)){
		//Redirect a "wants to send you" action request to our file choosing method so we handle it as a normal file transfer
		gaim_xfer_choose_file((GaimXfer *)userData);
		
    }else{
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
		if (default_action != -1 && (default_action < actionCount)){
			GCallback tempCallBack = callBacks[actionCount-1];
			callBacks[actionCount-1] = callBacks[default_action];
			callBacks[default_action] = tempCallBack;
			
			[buttonNamesArray exchangeObjectAtIndex:default_action withObjectAtIndex:(actionCount-1)];
		}
		
		NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:actionCount],@"Count",
			buttonNamesArray,@"Button Names",
			[NSValue valueWithPointer:callBacks],@"callBacks",
			[NSValue valueWithPointer:userData],@"userData",
			titleString,@"Title String",
			msg,@"Message",nil];
		
		[ESGaimRequestActionWindowController performSelectorOnMainThread:@selector(showActionWindowWithDict:)
															  withObject:infoDict
														   waitUntilDone:YES];
	}
    return(gaim_adium_get_handle());
}

static void *adiumGaimRequestFields(const char *title, const char *primary, const char *secondary, GaimRequestFields *fields, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData)
{
	NSString *titleString = (title ?  [[NSString stringWithUTF8String:title] lowercaseString] : nil);
	
    if ([titleString rangeOfString: @"new jabber"].location != NSNotFound) {
		/* Jabber registration request. Instead of displaying a request dialogue, we fill in the information automatically. */
		GList					*gl, *fl, *field_list;
		GaimRequestField		*field;
		GaimRequestFieldGroup	*group;
		JabberStream			*js = (JabberStream *)userData;
		GaimAccount				*account = js->gc->account;

		//Look through each group, processing each field, searching for username and password fields
		for (gl = gaim_request_fields_get_groups(fields);
			 gl != NULL;
			 gl = gl->next) {
			
			group = gl->data;
			field_list = gaim_request_field_group_get_fields(group);
			
			for (fl = field_list; fl != NULL; fl = fl->next) {
				GaimRequestFieldType type;
				
				field = (GaimRequestField *)fl->data;
				type = gaim_request_field_get_type(field);
				if (type == GAIM_REQUEST_FIELD_STRING) {
					if (strcasecmp("username", gaim_request_field_get_label(field)) == 0){
						gaim_request_field_string_set_value(field, gaim_account_get_username(account));
					}else if (strcasecmp("password", gaim_request_field_get_label(field)) == 0){
						gaim_request_field_string_set_value(field, gaim_account_get_password(account));
					}
				}
			}
			
		}
		((GaimRequestFieldsCb)okCb)(userData, fields);
	}
    
	return(gaim_adium_get_handle());
}

static void *adiumGaimRequestFile(const char *title, const char *filename, gboolean savedialog, GCallback ok_cb, GCallback cancel_cb,void *user_data)
{
	GaimXfer *xfer = (GaimXfer *)user_data;
	GaimXferType xferType = gaim_xfer_get_type(xfer);
	if (xfer) {
	    if (xferType == GAIM_XFER_RECEIVE) {
			GaimDebug (@"File request: %s from %s on IP %s",xfer->filename,xfer->who,gaim_xfer_get_remote_ip(xfer));
			
			ESFileTransfer  *fileTransfer;
			NSString		*destinationUID = [NSString stringWithUTF8String:gaim_normalize(xfer->account,xfer->who)];
			
			//Ask the account for an ESFileTransfer* object
			fileTransfer = [accountLookup(xfer->account) newFileTransferObjectWith:destinationUID
																			  size:gaim_xfer_get_size(xfer)
																	remoteFilename:[NSString stringWithUTF8String:(xfer->filename)]];
			
			//Configure the new object for the transfer
			[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
			
			xfer->ui_data = [fileTransfer retain];
			
			//Tell the account that we are ready to request the reception
			[accountLookup(xfer->account) mainPerformSelector:@selector(requestReceiveOfFileTransfer:)
												   withObject:fileTransfer];

	    } else if (xferType == GAIM_XFER_SEND) {
			if (xfer->local_filename != NULL && xfer->filename != NULL){
				gaim_xfer_choose_file_ok_cb(xfer, xfer->local_filename);
			}else{
				gaim_xfer_choose_file_cancel_cb(xfer, xfer->local_filename);
				[myself displayFileSendError];
			}
	    }
		
	}
    
	return(gaim_adium_get_handle());
}

static void adiumGaimRequestClose(GaimRequestType type,void *uiHandle)
{

}

static GaimRequestUiOps adiumGaimRequestOps = {
    adiumGaimRequestInput,
    adiumGaimRequestChoice,
    adiumGaimRequestAction,
    adiumGaimRequestFields,
	adiumGaimRequestFile,
    adiumGaimRequestClose
};

#pragma mark File Transfer
// File Transfer ------------------------------------------------------------------------------------------------------

static void adiumGaimNewXfer(GaimXfer *xfer)
{

}

static void adiumGaimDestroy(GaimXfer *xfer)
{
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	[accountLookup(xfer->account) mainPerformSelector:@selector(destroyFileTransfer:)
										   withObject:fileTransfer];
	
	xfer->ui_data = nil;
}

- (void)displayFileSendError
{
	[[adium interfaceController] mainPerformSelector:@selector(handleMessage:withDescription:withWindowTitle:)
										  withObject:AILocalizedString(@"File Send Error",nil)
										  withObject:AILocalizedString(@"An error was encoutered sending the file.  Please note that sending of folders is not currently supported; this includes Application bundles.",nil)
										  withObject:AILocalizedString(@"File Send Error",nil)];
}

static void adiumGaimAddXfer(GaimXfer *xfer)
{

}

static void adiumGaimUpdateProgress(GaimXfer *xfer, double percent)
{
//	GaimDebug (@"Transfer update: %s is now %f%% done",(xfer->filename ? xfer->filename : ""),(percent*100));
	
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	
	if (fileTransfer){
		[accountLookup(xfer->account) mainPerformSelector:@selector(updateProgressForFileTransfer:percent:bytesSent:)
											   withObject:fileTransfer
											   withObject:[NSNumber numberWithFloat:percent]
											   withObject:[NSNumber numberWithUnsignedLong:xfer->bytes_sent]];
	}
}

static void adiumGaimCancelLocal(GaimXfer *xfer)
{
	GaimDebug (@"adiumGaimCancelLocal");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) mainPerformSelector:@selector(fileTransferCanceledLocally:)
										   withObject:fileTransfer];	
}

static void adiumGaimCancelRemote(GaimXfer *xfer)
{
	GaimDebug (@"adiumGaimCancelRemote");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) mainPerformSelector:@selector(fileTransferCanceledRemotely:)
										   withObject:fileTransfer];
}

static GaimXferUiOps adiumGaimFileTransferOps = {
    adiumGaimNewXfer,
    adiumGaimDestroy,
    adiumGaimAddXfer,
    adiumGaimUpdateProgress,
    adiumGaimCancelLocal,
    adiumGaimCancelRemote
};

#pragma mark Privacy
// Privacy ------------------------------------------------------------------------------------------------------

static void adiumGaimPermitAdded(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyPermitListAdded:)
									 withObject:[NSString stringWithUTF8String:gaim_normalize(account, name)]];
}
static void adiumGaimPermitRemoved(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyPermitListRemoved:)
									 withObject:[NSString stringWithUTF8String:gaim_normalize(account, name)]];
}
static void adiumGaimDenyAdded(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyDenyListAdded:)
									 withObject:[NSString stringWithUTF8String:gaim_normalize(account, name)]];
}
static void adiumGaimDenyRemoved(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyDenyListRemoved:)
									 withObject:[NSString stringWithUTF8String:gaim_normalize(account, name)]];
}

static GaimPrivacyUiOps adiumGaimPrivacyOps = {
    adiumGaimPermitAdded,
    adiumGaimPermitRemoved,
    adiumGaimDenyAdded,
    adiumGaimDenyRemoved
};

#pragma mark Event loop
static void socketCallback(CFSocketRef s,
                           CFSocketCallBackType callbackType,
                           CFDataRef address,
                           const void *data,
                           void *infoVoid);
/*
 * The sources, keyed by integer key id (wrapped in an NSValue), holding
 * struct sourceInfo* values (wrapped in an NSValue).
 */

static guint adium_timeout_add(guint, GSourceFunc, gpointer);
static guint adium_timeout_remove(guint);
static guint adium_input_add(int, GaimInputCondition, GaimInputFunction, gpointer);
static guint adium_source_remove(guint);

static GaimEventLoopUiOps adiumEventLoopUiOps = {
    adium_timeout_add,
    adium_timeout_remove,
    adium_input_add,
    adium_source_remove
};

// The structure of values of sourceInfoDict
struct SourceInfo {
    guint tag;
    CFRunLoopTimerRef timer;
    CFSocketRef socket;
    CFRunLoopSourceRef rls;
    union {
        GSourceFunc sourceFunction;
        GaimInputFunction ioFunction;
    };
    int fd;
    gpointer user_data;
};

#pragma mark Add

void callTimerFunc(CFRunLoopTimerRef timer, void *info)
{
	struct SourceInfo *sourceInfo = info;
	
//	GaimDebug (@"%x: Fired %f-ms timer (tag %u)",[NSRunLoop currentRunLoop],CFRunLoopTimerGetInterval(timer)*1000,sourceInfo->tag);
	if (! sourceInfo->sourceFunction(sourceInfo->user_data)) {
        adium_source_remove(sourceInfo->tag);
	}
}

guint adium_timeout_add(guint interval, GSourceFunc function, gpointer data)
{
//    GaimDebug (@"%x: New %u-ms timer (tag %u)",[NSRunLoop currentRunLoop], interval, sourceId);
	
    struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));
	
	sourceId++;
	NSTimeInterval intervalInSec = (NSTimeInterval)interval/1000;
	CFRunLoopTimerContext runLoopTimerContext = { 0, info, NULL, NULL, NULL };
	CFRunLoopTimerRef runLoopTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, /* default allocator */
		(CFAbsoluteTimeGetCurrent() + intervalInSec), /* The time at which the timer should first fire */
		intervalInSec, /* firing interval */
		0, /* flags, currently ignored */
		0, /* order, currently ignored */
		callTimerFunc, /* CFRunLoopTimerCallBack callout */
		&runLoopTimerContext /* context */);

	info->sourceFunction = function;
	info->timer = runLoopTimer;
	info->socket = NULL;
	info->rls = NULL;
	info->user_data = data;

	CFRunLoopAddTimer(CFRunLoopGetCurrent(), runLoopTimer, kCFRunLoopCommonModes);

	NSNumber	*key = [NSNumber numberWithUnsignedInt:sourceId];
	//Make sure we end up with a valid source id
	while ([sourceInfoDict objectForKey:key]){
		sourceId++;
		key = [NSNumber numberWithUnsignedInt:sourceId];
	}
	info->tag = sourceId;

	[sourceInfoDict setObject:[NSValue valueWithPointer:info]
					   forKey:key];

	return sourceId;
}

guint adium_input_add(int fd, GaimInputCondition condition,
					  GaimInputFunction func, gpointer user_data)
{
    struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));
	
    // Build the CFSocket-style callback flags to use from the gaim ones
    CFOptionFlags callBackTypes = 0;
    if ((condition & GAIM_INPUT_READ ) != 0) callBackTypes |= kCFSocketReadCallBack;
    if ((condition & GAIM_INPUT_WRITE) != 0){
		if (isOnTigerOrBetter){
			callBackTypes |= kCFSocketWriteCallBack | kCFSocketConnectCallBack;
		}else{
			callBackTypes |= kCFSocketWriteCallBack;
		}
	}
	
//	if ((condition & GAIM_INPUT_CONNECT) != 0) callBackTypes |= kCFSocketConnectCallBack;
	
    // And likewise the entire CFSocket
    CFSocketContext context = { 0, info, NULL, NULL, NULL };
    CFSocketRef socket = CFSocketCreateWithNative(NULL, fd, callBackTypes, socketCallback, &context);
    NSCAssert(socket != NULL, @"CFSocket creation failed");
    info->socket = socket;
	
    // Re-enable callbacks automatically and _don't_ close the socket on
    // invalidate
	CFSocketSetSocketFlags(socket, kCFSocketAutomaticallyReenableReadCallBack | 
									kCFSocketAutomaticallyReenableDataCallBack |
									kCFSocketAutomaticallyReenableWriteCallBack);
	
    // Add it to our run loop
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(NULL, socket, 0);
	
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopCommonModes);
	
	sourceId++;

//	GaimDebug (@"Adding for %i",sourceId);

	info->rls = rls;
	info->timer = NULL;
    info->tag = sourceId;
    info->ioFunction = func;
    info->user_data = user_data;
    info->fd = fd;
    NSCAssert1([sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:sourceId]] == nil, @"Key %u in use", sourceId);
    [sourceInfoDict setObject:[NSValue valueWithPointer:info]
					   forKey:[NSNumber numberWithUnsignedInt:sourceId]];
	
    return sourceId;
}

#pragma mark Remove

//Like g_source_remove, return TRUE if successful, FALSE if not
guint adium_timeout_remove(guint tag) {
    return (adium_source_remove(tag));
}

guint adium_source_remove(guint tag) {
    struct SourceInfo *sourceInfo = (struct SourceInfo*)
	[[sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:tag]] pointerValue];
	
//	GaimDebug (@"***SOURCE REMOVE : %i",tag);
    if (sourceInfo){
		if (sourceInfo->timer != NULL) { 
			//Got a timer; invalidate and release
			CFRunLoopTimerInvalidate(sourceInfo->timer);
			CFRelease(sourceInfo->timer);
			
		}else{
			//Got a file handle; invalidate and release the source and the socket
			CFRunLoopSourceInvalidate(sourceInfo->rls);
			CFRelease(sourceInfo->rls);
			CFSocketInvalidate(sourceInfo->socket);
			CFRelease(sourceInfo->socket);
		}
		
		[sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:tag]];
		free(sourceInfo);
		
		return TRUE;
	}
	
	return FALSE;
}

#pragma mark Socket Callback
static void socketCallback(CFSocketRef s,
					CFSocketCallBackType callbackType,
					CFDataRef address,
					const void *data,
					void *infoVoid)
{
    struct SourceInfo *sourceInfo = (struct SourceInfo*) infoVoid;
	
    GaimInputCondition c = 0;
    if ((callbackType & kCFSocketReadCallBack) != 0)  c |= GAIM_INPUT_READ;
    if ((callbackType & kCFSocketWriteCallBack) != 0) c |= GAIM_INPUT_WRITE;
//	if ((callbackType & kCFSocketConnectCallBack) != 0) c |= GAIM_INPUT_CONNECT;

//	GaimDebug (@"***SOCKETCALLBACK : %i (%i)",info->fd,c);
	
	if ((callbackType & kCFSocketConnectCallBack) != 0) {
		//Got a file handle; invalidate and release the source and the socket
		CFRunLoopSourceInvalidate(sourceInfo->rls);
		CFRelease(sourceInfo->rls);
		CFSocketInvalidate(sourceInfo->socket);
		CFRelease(sourceInfo->socket);
		
		[sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:sourceInfo->tag]];
		sourceInfo->ioFunction(sourceInfo->user_data, sourceInfo->fd, c);
		free(sourceInfo);
		
	}else{
//		GaimDebug (@"%x: Socket callback: %i",[NSRunLoop currentRunLoop],sourceInfo->tag);
		sourceInfo->ioFunction(sourceInfo->user_data, sourceInfo->fd, c);
	}
	
}

#pragma mark Libgaim Initialization & Core
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
	GaimDebug (@"%x: Registering debug functions",[NSRunLoop currentRunLoop]);
    gaim_debug_set_ui_ops(&adiumGaimDebugOps);
#endif
}

static void adiumGaimCoreUiInit(void)
{
	GaimDebug (@"%x: Registering core functions",[NSRunLoop currentRunLoop]);
	
	gaim_eventloop_set_ui_ops(&adiumEventLoopUiOps);
    gaim_blist_set_ui_ops(&adiumGaimBlistOps);
    gaim_connections_set_ui_ops(&adiumGaimConnectionOps);
    gaim_conversations_set_win_ui_ops(&adiumGaimWindowOps);
    gaim_notify_set_ui_ops(&adiumGaimNotifyOps);
    gaim_request_set_ui_ops(&adiumGaimRequestOps);
    gaim_xfers_set_ui_ops(&adiumGaimFileTransferOps);
    gaim_privacy_set_ui_ops (&adiumGaimPrivacyOps);
	gaim_roomlist_set_ui_ops (&adiumGaimRoomlistOps);	
#if	ENABLE_WEBCAM
	gaim_webcam_set_ui_ops(&adiumGaimWebcamOps);
#endif
}

static void adiumGaimCoreQuit(void)
{
    GaimDebug (@"Core quit");
    exit(0);
}

static GaimCoreUiOps adiumGaimCoreOps = {
    adiumGaimPrefsInit,
    adiumGaimCoreDebugInit,
    adiumGaimCoreUiInit,
    adiumGaimCoreQuit
};

- (void)initLibGaim
{	
	//Register ourself as libgaim's UI handler
	gaim_core_set_ui_ops(&adiumGaimCoreOps);
	if(!gaim_core_init("Adium")) {
		NSLog(@"*** FATAL ***: Failed to initialize gaim core");
		GaimDebug (@"*** FATAL ***: Failed to initialize gaim core");
	}
	
	//Setup the buddy list
    gaim_set_blist(gaim_blist_new());
	
	//Load gaim plugins
#if ENABLE_WEBCAM
	gaim_init_j2k_plugin();
#endif
	
    //Setup libgaim core preferences
    
    //Disable gaim away handling - we do it ourselves
    gaim_prefs_set_bool("/core/conversations/away_back_on_send", FALSE);
    gaim_prefs_set_bool("/core/away/auto_response/enabled", FALSE);
    gaim_prefs_set_string("/core/away/auto_reply","never");

    //Disable gaim conversation logging
    gaim_prefs_set_bool("/gaim/gtk/logging/log_chats", FALSE);
    gaim_prefs_set_bool("/gaim/gtk/logging/log_ims", FALSE);
    
    //Typing preference
    gaim_prefs_set_bool("/core/conversations/im/send_typing", TRUE);
	
	//Use server alias where possible
	gaim_prefs_set_bool("/core/buddies/use_server_alias", TRUE);

	//MSN preferences
	gaim_prefs_set_bool("/plugins/prpl/msn/conv_close_notice", TRUE);
	gaim_prefs_set_bool("/plugins/prpl/msn/conv_timeout_notice", TRUE);
		
	//Configure signals for receiving gaim events
	[self configureSignals];
}

#pragma mark Thread accessors

- (void)connectAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self 
			 performSelector:@selector(gaimThreadConnectAccount:) 
				  withObject:adiumAccount];
}
- (void)gaimThreadConnectAccount:(id)adiumAccount
{
	gaim_account_connect(accountLookupFromAdiumAccount(adiumAccount));
}

- (void)disconnectAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self 
			 performSelector:@selector(gaimThreadDisconnectAccount:) 
				  withObject:adiumAccount];
}
- (void)gaimThreadDisconnectAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	
	if(gaim_account_is_connected(account)){
		gaim_account_disconnect(account);
	}
}

- (void)registerAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self 
			 performSelector:@selector(gaimThreadRegisterAccount:) 
				  withObject:adiumAccount];
}
- (void)gaimThreadRegisterAccount:(id)adiumAccount
{
	gaim_account_register(accountLookupFromAdiumAccount(adiumAccount));
}

//Returns YES if the message was sent (and should therefore be displayed).  Returns NO if it was not sent or was otherwise used.
- (BOOL)sendEncodedMessage:(NSString *)encodedMessage
				  originalMessage:(NSString *)originalMessage 
					  fromAccount:(id)sourceAccount
						   inChat:(AIChat *)chat
						withFlags:(int)flags
{
	BOOL sendMessage = YES;
	
	if ([originalMessage hasPrefix:@"/"]){
		/* If a content object makes it this far and still has a "/", Adium hasn't treated it as a command or
		substitution.  Send it to Gaim for it to try to handle it.
		XXX - do we want to not-eat non-commands, checking to see if Gaim handled the command and, if not,
		sending it anyways? */
		
		sendMessage = [self attemptGaimCommandOnMessage:originalMessage
											fromAccount:sourceAccount
												 inChat:chat];
	}

	if(sendMessage){
		AILog(@"Sending %@ from %@ to %@",encodedMessage,sourceAccount,chat);
		[gaimThreadMessenger target:self 
				 performSelector:@selector(gaimThreadSendEncodedMessage:originalMessage:fromAccount:inChat:withFlags:) 
					  withObject:encodedMessage
					  withObject:originalMessage
					  withObject:sourceAccount
					  withObject:chat
					  withObject:[NSNumber numberWithInt:flags]];
	}

	return(sendMessage);
}

//Called with a potential gaimCommand as originalMessage.  Uses gaim_cmd_check_command() [added to libgaim] to determine
//if the cmd is potentially a valid gaim command.  Returns YES if the message should be sent (it was not a command) or
//NO if the message should not be sent (it was a command and already executed as such on the proper thread).
- (BOOL)attemptGaimCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat
{
	GaimConversation	*conv = convLookupFromChat(chat, sourceAccount);
	GaimCmdStatus		status;
	char				*markup, *error;
	const char			*cmd;
	BOOL				sendMessage = YES;
	
	cmd = [originalMessage UTF8String];
	
	//cmd+1 will be the cmd without the leading character, which should be "/"
	markup = gaim_escape_html(cmd+1);
	status = gaim_cmd_check_command(conv, cmd+1, markup, &error);
	AILog(@"Command status is %i",status);
	g_free(markup);
	
	switch (status) {
		case GAIM_CMD_STATUS_OK:
			sendMessage = NO;
			//We're good to go (the arguments may be wrong, or it may fail, but it is an account-appropriate command);
			//perform the command on the gaim thread.
			[gaimThreadMessenger target:self 
					 performSelector:@selector(gaimThreadDoCommand:fromAccount:inChat:) 
						  withObject:originalMessage
						  withObject:sourceAccount
						  withObject:chat];
			
			break;
		case GAIM_CMD_STATUS_WRONG_ARGS:			
		{
			sendMessage = NO;
			
			gaim_conv_present_error(conv->name, conv->account, "Wrong number of arguments");
			
			break;
		}
		case GAIM_CMD_STATUS_WRONG_TYPE:
		{
			//XXX Do we want to error on this or pretend there was no command?
			sendMessage = NO;
			if(gaim_conversation_get_type(conv) == GAIM_CONV_IM){
				gaim_notify_error(gaim_account_get_connection(conv->account),"Attempted to use Chat command in IM",cmd,NULL);
			}else{
				gaim_notify_error(gaim_account_get_connection(conv->account),"Attempted to use IM command in Chat",cmd,NULL);
			}
		}
		case GAIM_CMD_STATUS_FAILED:
			/* We will never receive this from gaim_cmd_check_command() */
			break;
		case GAIM_CMD_STATUS_NOT_FOUND:
		case GAIM_CMD_STATUS_WRONG_PRPL:
			/* Ignore this command and let the message send; the user probably doesn't even know what they typed is a command */
			break;
	}		
	
	return(sendMessage);
}

//Called on the gaim thread, actually performs the specified command (it should have already been tested by 
//attemptGaimCommandOnMessage:... above.
- (oneway void)gaimThreadDoCommand:(NSString *)originalMessage
					   fromAccount:(id)sourceAccount
							inChat:(AIChat *)chat
{
	GaimConversation	*conv = convLookupFromChat(chat, sourceAccount);
	GaimCmdStatus		status;
	char				*markup, *error;
	const char			*cmd;
	
	cmd = [originalMessage UTF8String];
	
	//cmd+1 will be the cmd without the leading character, which should be "/"
	markup = gaim_escape_html(cmd+1);
	status = gaim_cmd_do_command(conv, cmd+1, markup, &error);
	
	//The only error status which is possible now is either 
	switch (status) {
		case GAIM_CMD_STATUS_FAILED:
		{
			gaim_conv_present_error(conv->name, conv->account, "Command failed");

			break;
		}	
		case GAIM_CMD_STATUS_WRONG_ARGS:
		{
			gaim_conv_present_error(conv->name, conv->account, "Wrong number of arguments");
			
			break;
		}
		case GAIM_CMD_STATUS_OK:
		/* All these statuses are taken care of by gaim_cmd_check_command */
		case GAIM_CMD_STATUS_NOT_FOUND:
		case GAIM_CMD_STATUS_WRONG_TYPE:
		case GAIM_CMD_STATUS_WRONG_PRPL:
			break;
	}
}
	

- (oneway void)gaimThreadSendEncodedMessage:(NSString *)encodedMessage
							originalMessage:(NSString *)originalMessage
								fromAccount:(id)sourceAccount
									 inChat:(AIChat *)chat
								  withFlags:(NSNumber *)flags
{	
	const char *encodedMessageUTF8String;
	
	if(encodedMessageUTF8String = [encodedMessage UTF8String]){
		GaimConversation	*conv = convLookupFromChat(chat,sourceAccount);
		
		switch (gaim_conversation_get_type(conv)) {				
			case GAIM_CONV_IM: {
				GaimConvIm			*im = gaim_conversation_get_im_data(conv);
				gaim_conv_im_send_with_flags(im,encodedMessageUTF8String,[flags intValue]);
				break;
			}
				
			case GAIM_CONV_CHAT: {
				GaimConvChat	*gaimChat = gaim_conversation_get_chat_data(conv);
				gaim_conv_chat_send(gaimChat,encodedMessageUTF8String);
				break;
			}
		}
	}else{
		GaimDebug (@"*** Error encoding %@ to UTF8",encodedMessage);
	}
}

- (oneway void)sendTyping:(AITypingState)typingState inChat:(AIChat *)chat
{
	[gaimThreadMessenger target:self 
			 performSelector:@selector(gaimThreadSendTyping:inChat:)
				  withObject:[NSNumber numberWithInt:typingState]
				  withObject:chat];
}
- (oneway void)gaimThreadSendTyping:(NSNumber *)typingState inChat:(AIChat *)chat
{
	GaimConversation *conv = convLookupFromChat(chat,nil);
	if (conv){
		//		BOOL isTyping = (([typingState intValue] == AINotTyping) ? FALSE : TRUE);

		GaimTypingState gaimTypingState;
		
		switch ([typingState intValue]){
			case AINotTyping:
				gaimTypingState = GAIM_NOT_TYPING;
				break;
			case AITyping:
				gaimTypingState = GAIM_TYPING;
				break;
			case AIEnteredText:
				gaimTypingState = GAIM_TYPED;
				break;
		}
	
		serv_send_typing(gaim_conversation_get_gc(conv),
						 gaim_conversation_get_name(conv),
						 gaimTypingState);
	}	
}

- (oneway void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	[gaimThreadMessenger target:self 
			 performSelector:@selector(gaimThreadAddUID:onAccount:toGroup:)
				  withObject:objectUID
				  withObject:adiumAccount
				  withObject:groupName];
}

- (oneway void)gaimThreadAddUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	char		*buddyUTF8String;
	const char	*groupUTF8String;
	BOOL		performAdd = NO;
	GaimGroup	*group;
	GaimBuddy	*buddy;
	
	buddyUTF8String = g_strdup(gaim_normalize(account,[objectUID UTF8String]));
	groupUTF8String = (groupName ? [groupName UTF8String] : "");
	
	//Get the group (Create if necessary)
	if(!(group = gaim_find_group(groupUTF8String))){
		group = gaim_group_new(groupUTF8String);
		gaim_blist_add_group(group, NULL);
	}
	
	//Verify the buddy does not already exist and create it
	if(buddy = gaim_find_buddy(account,buddyUTF8String)){
		GaimGroup *oldGroup;
		
		oldGroup = gaim_find_buddys_group(buddy);
		//If the buddy was in our strangers group before, remove from gaim's internal list
		if ((oldGroup != nil) && (strcmp(GAIM_ORPHANS_GROUP_NAME,oldGroup->name) == 0)){
			gaim_blist_remove_buddy(buddy);
			buddy = nil;
			performAdd = YES;
		}
	}else{
		performAdd = YES;	
	}
	
	if (performAdd){
		//Add the buddy locally to libgaim and then to the serverside list
		if(!buddy){
			GaimDebug (@"gaimThreadAddUID: Creating new buddy %s on %s",buddyUTF8String,account->username);

			buddy = gaim_buddy_new(account, buddyUTF8String, NULL);
		}
		gaim_blist_add_buddy(buddy, NULL, group, NULL);
		serv_add_buddy(gaim_account_get_connection(account), buddy);
	}
	
	g_free(buddyUTF8String);
}

- (oneway void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName
{
	[gaimThreadMessenger target:self performSelector:@selector(gaimThreadRemoveUID:onAccount:fromGroup:)
				  withObject:objectUID
				  withObject:adiumAccount
				  withObject:groupName];
}
- (oneway void)gaimThreadRemoveUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	char		*buddyUTF8String;
	const char	*groupUTF8String;
	
	buddyUTF8String =  g_strdup(gaim_normalize(account, [objectUID UTF8String]));
	groupUTF8String = (groupName ? [groupName UTF8String] : "");
	
	GaimBuddy 	*buddy = gaim_find_buddy(account, buddyUTF8String);
	if (buddy){
		GaimGroup *group = gaim_find_group(groupUTF8String);
		if (group){
			//Remove this contact from the server-side and gaim-side lists
			serv_remove_buddy(gaim_account_get_connection(account), buddy, group);
			gaim_blist_remove_buddy(buddy);
		}
	}
	
	g_free(buddyUTF8String);
}

- (oneway void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	[gaimThreadMessenger target:self performSelector:@selector(gaimThreadMoveUID:onAccount:toGroup:)
				  withObject:objectUID
				  withObject:adiumAccount
				  withObject:groupName];
}
- (oneway void)gaimThreadMoveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	GaimAccount *account;
	GaimGroup 	*oldGroup, *destGroup;
	GaimBuddy	*buddy;
	char		*buddyUTF8String;
	const char	*groupUTF8String;
	BOOL		didMove = NO;
	
	account = accountLookupFromAdiumAccount(adiumAccount);
	buddyUTF8String = g_strdup(gaim_normalize(account, [objectUID UTF8String]));
	
	//Get the destination group (creating if necessary)
	groupUTF8String = (groupName ? [groupName UTF8String] : "");

	destGroup = gaim_find_group(groupUTF8String);
	if(!destGroup) destGroup = gaim_group_new(groupUTF8String);
	
	//Get the gaim buddy and group for this move
	if((buddy = gaim_find_buddy(account,buddyUTF8String)) &&
	   (oldGroup = gaim_find_buddys_group(buddy))){
			//Procede to move the buddy gaim-side and locally
			serv_move_buddy(buddy, oldGroup, destGroup);
			didMove = YES;
	}
		
	if (!didMove){
		GaimDebug (@"^^^ movingUID %s toGroup %s but it was not found; adding instead",buddyUTF8String,groupUTF8String);

		//No GaimBuddy was found, so despite all appearances this 'move' is really an add.
		[self gaimThreadAddUID:objectUID onAccount:adiumAccount toGroup:groupName];
	}
	
	g_free(buddyUTF8String);
}

- (oneway void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName
{	
	[gaimThreadMessenger target:self performSelector:@selector(gaimThreadRenameGroup:onAccount:to:)
				  withObject:oldGroupName
				  withObject:adiumAccount
				  withObject:newGroupName];
}
- (oneway void)gaimThreadRenameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName
{
    GaimGroup *group = gaim_find_group([oldGroupName UTF8String]);
	
	//If we don't have a group with this name, just ignore the rename request
    if(group){
		//Rename gaimside, which will rename serverside as well
		gaim_blist_rename_group(group, [newGroupName UTF8String]);
	}
}

- (oneway void)deleteGroup:(NSString *)groupName onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadDeleteGroup:onAccount:)
				  withObject:groupName
				  withObject:adiumAccount];
}

- (oneway void)gaimThreadDeleteGroup:(NSString *)groupName onAccount:(id)adiumAccount
{
	GaimGroup *group = gaim_find_group([groupName UTF8String]);
	
	if (group){
		gaim_blist_remove_group(group);
	}
}

#pragma mark Alias
- (oneway void)setAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadSetAlias:forUID:onAccount:)
				  withObject:alias
				  withObject:UID
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadSetAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (gaim_account_is_connected(account)){
		const char  *uidUTF8String = [UID UTF8String];
		GaimBuddy   *buddy = gaim_find_buddy(account, uidUTF8String);
		const char  *aliasUTF8String = [alias UTF8String];
		const char	*oldAlias = (buddy ? gaim_buddy_get_alias(buddy) : nil);
	
		if (buddy && ((aliasUTF8String && !oldAlias) ||
					  (!aliasUTF8String && oldAlias) ||
					  ((oldAlias && aliasUTF8String && (strcmp(oldAlias,aliasUTF8String) != 0))))){

			gaim_blist_alias_buddy(buddy,aliasUTF8String);
			serv_alias_buddy(buddy);
			
			//If we had an alias before but no longer have, adiumGaimBlistUpdate() is not going to send the update
			//(Because normally it's wasteful to send a nil alias to the account).  We need to manually invoke the update.
			if (oldAlias && !alias){
				AIListContact *theContact = contactLookupFromBuddy(buddy);
				
				[adiumAccount mainPerformSelector:@selector(updateContact:toAlias:)
									   withObject:theContact
									   withObject:nil];
			}
		}
	}
}

#pragma mark Chats
- (oneway void)openChat:(AIChat *)chat onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadOpenChat:onAccount:)
				  withObject:chat
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadOpenChat:(AIChat *)chat onAccount:(id)adiumAccount
{
	//Looking up the conv from the chat will create the GaimConversation gaimside, joining the chat, opening the server
	//connection, or whatever else is done when a chat is opened.
	convLookupFromChat(chat,adiumAccount);
}

- (oneway void)closeChat:(AIChat *)chat
{
	//We look up the conv and the chat's uniqueChatID now since threading may make them change before
	//the gaimThread actually utilizes them
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadCloseGaimConversation:withChatID:)
				  withObject:[NSValue valueWithPointer:existingConvLookupFromChat(chat)]
				  withObject:[chat uniqueChatID]];
}
- (oneway void)gaimThreadCloseGaimConversation:(NSValue *)convValue withChatID:(NSString *)chatUniqueID
{
	GaimConversation *conv = [convValue pointerValue];

	if(conv){
		//We use chatDict's objectfor the passed chatUniqueID because we can no longer trust any other
		//values due to threading potentially letting them have changed on us.
		[chatDict removeObjectForKey:chatUniqueID];
			
		//We retained the chat when setting it as the ui_data; we are releasing here, so be sure to set conv->ui_data
		//to nil so we don't try to do it again.
		[(AIChat *)conv->ui_data release];
		conv->ui_data = nil;
		
		//Tell gaim to destroy the conversation.
		gaim_conversation_destroy(conv);
	}	
}

- (oneway void)inviteContact:(AIListContact *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadInviteContact:toChat:withMessage:)
				  withObject:contact
				  withObject:chat
				  withObject:inviteMessage];
}

- (oneway void)gaimThreadInviteContact:(AIListContact *)listContact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage
{
	GaimConversation	*conv;
	GaimAccount			*account;
	GaimConvChat		*gaimChat;

	GaimDebug (@"#### gaimThreadInviteContact:%@ toChat:%@",[listContact UID],[chat name]);
	// dchoby98
	if((conv = convLookupFromChat(chat,[chat account])) &&
	   (account = accountLookupFromAdiumAccount([chat account])) &&
	   (gaimChat = gaim_conversation_get_chat_data(conv))){

		//GaimBuddy		*buddy = gaim_find_buddy(account, [[listObject UID] UTF8String]);
		GaimDebug (@"#### gaimThreadAddChatUser chat: %@ (%@) buddy: %@",[chat name], chat,[listContact UID]);
		serv_chat_invite(gaim_conversation_get_gc(conv),
						 gaim_conv_chat_get_id(gaimChat),
						 (inviteMessage ? [inviteMessage UTF8String] : ""),
						 [[listContact UID] UTF8String]);
		
	}
}

- (void)createNewGroupChat:(AIChat *)chat withListObject:(AIListObject *)contact
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadCreateNewChat:withListObject:)
				  withObject:chat
				  withObject:contact];
}

- (oneway void)gaimThreadCreateNewChat:(AIChat *)chat withListObject:(AIListContact *)contact
{
	//Create the chat
	convLookupFromChat(chat, [chat account]);
	
	//Invite the contact, with no message
	[self gaimThreadInviteContact:contact toChat:chat withMessage:nil];
}


#pragma mark Account Status
- (oneway void)setAway:(NSString *)awayHTML onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadSetAway:onAccount:)
				  withObject:awayHTML
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadSetAway:(NSString *)awayHTML onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (gaim_account_is_connected(account)){
		
		//Status Changes: We could use "Invisible" instead of GAIM_AWAY_CUSTOM for invisibility...
		serv_set_away(account->gc, GAIM_AWAY_CUSTOM, [awayHTML UTF8String]);
	}
}
- (oneway void)setInfo:(NSString *)profileHTML onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadSetInfo:onAccount:)
				  withObject:profileHTML
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadSetInfo:(NSString *)profileHTML onAccount:(id)adiumAccount
{
	GaimAccount 	*account = accountLookupFromAdiumAccount(adiumAccount);

	gaim_account_set_user_info(account, [profileHTML UTF8String]);

	if(account->gc != NULL && gaim_account_is_connected(account)){
		serv_set_info(account->gc, [profileHTML UTF8String]);
	}
}

- (oneway void)setBuddyIcon:(NSString *)buddyImageFilename onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadSetBuddyIcon:onAccount:)
				  withObject:buddyImageFilename
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadSetBuddyIcon:(NSString *)buddyImageFilename onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if(account){
		gaim_account_set_buddy_icon(account, [buddyImageFilename UTF8String]);
	}
}

- (oneway void)setIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadSetIdleSinceTo:onAccount:)
				  withObject:idleSince
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadSetIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (gaim_account_is_connected(account)){
		NSTimeInterval idle = (idleSince != nil ? -[idleSince timeIntervalSinceNow] : nil);
		
		if(idle) {
			//Go to a 0 idle on the server first to ensure other clients see our change (to support arbitrary Set Custom Idle time changes)
			serv_set_idle(account->gc, 0);
			serv_set_idle(account->gc, idle);
			account->gc->is_idle = TRUE;
		} else {
			serv_touch_idle(account->gc);	
		}
	}
}

#pragma mark Get Info
- (oneway void)getInfoFor:(NSString *)inUID onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadGetInfoFor:onAccount:)
				  withObject:inUID
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadGetInfoFor:(NSString *)inUID onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (gaim_account_is_connected(account)){
		
		serv_get_info(account->gc, [inUID UTF8String]);
	}
}

#pragma mark Xfer
- (oneway void)xferRequest:(GaimXfer *)xfer
{
	[gaimThreadMessenger target:self performSelector:@selector(gaimThreadXferRequest:)
				  withObject:[NSValue valueWithPointer:xfer]];
}
- (oneway void)gaimThreadXferRequest:(NSValue *)xferValue
{
	GaimXfer	*xfer = [xferValue pointerValue];
	gaim_xfer_request(xfer);
}

- (oneway void)xferRequestAccepted:(GaimXfer *)xfer withFileName:(NSString *)xferFileName
{
	[gaimThreadMessenger target:self performSelector:@selector(gaimThreadXferRequestAccepted:withFileName:)
				  withObject:[NSValue valueWithPointer:xfer]
				  withObject:xferFileName];	
}
- (oneway void)gaimThreadXferRequestAccepted:(NSValue *)xferValue withFileName:(NSString *)xferFileName
{
	GaimXfer	*xfer = [xferValue pointerValue];
	gaim_xfer_choose_file_ok_cb(xfer, [xferFileName UTF8String]);
}
- (oneway void)xferRequestRejected:(GaimXfer *)xfer
{
	[gaimThreadMessenger target:self performSelector:@selector(gaimThreadXferRequestRejected:)
				  withObject:[NSValue valueWithPointer:xfer]];
}
- (oneway void)gaimThreadXferRequestRejected:(NSValue *)xferValue
{
	GaimXfer	*xfer = [xferValue pointerValue];
	gaim_xfer_request_denied(xfer);
}
- (oneway void)xferCancel:(GaimXfer *)xfer
{
	[gaimThreadMessenger target:self performSelector:@selector(gaimThreadXferCancel:)
				  withObject:[NSValue valueWithPointer:xfer]];	
}
- (oneway void)gaimThreadXferCancel:(NSValue *)xferValue
{
	GaimXfer	*xfer = [xferValue pointerValue];
	gaim_xfer_cancel_local(xfer);	
}

#pragma mark Account settings
- (oneway void)setCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadSetCheckMail:forAccount:)
				  withObject:checkMail
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadSetCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	BOOL		shouldCheckMail = [checkMail boolValue];

	gaim_account_set_check_mail(account, shouldCheckMail);
}

#pragma mark Protocol specific accessors
- (oneway void)OSCAREditComment:(NSString *)comment forUID:(NSString *)inUID onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadOSCAREditComment:forUID:onAccount:)
				  withObject:comment
				  withObject:inUID
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadOSCAREditComment:(NSString *)comment forUID:(NSString *)inUID onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (gaim_account_is_connected(account)){
		GaimBuddy   *buddy;
		GaimGroup   *g;
		OscarData   *od;

		const char  *uidUTF8String = [inUID UTF8String];

		if ((buddy = gaim_find_buddy(account, uidUTF8String)) &&
			(g = gaim_find_buddys_group(buddy)) && 
			(od = account->gc->proto_data)){
			aim_ssi_editcomment(od->sess, g->name, uidUTF8String, [comment UTF8String]);	
		}
	}
}

- (oneway void)OSCARSetFormatTo:(NSString *)inFormattedUID onAccount:(id)adiumAccount
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadOSCARSetFormatTo:onAccount:)
				  withObject:inFormattedUID
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadOSCARSetFormatTo:(NSString *)inFormattedUID onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	
	//Because we can get here from a delay, it's possible that we are now disconnected. Sanity checks are good.
	if(account &&
	   gaim_account_is_connected(account) &&
	   [inFormattedUID length]){
		
		oscar_set_format_screenname(account->gc, [inFormattedUID UTF8String]);
	}
}

#pragma mark Request callbacks
- (oneway void)doRequestInputCbValue:(NSValue *)callBackValue
				   withUserDataValue:(NSValue *)userDataValue 
						 inputString:(NSString *)string
{	
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadDoRequestInputCbValue:withUserDataValue:inputString:)
				  withObject:callBackValue
				  withObject:userDataValue
				  withObject:string];
}
- (oneway void)gaimThreadDoRequestInputCbValue:(NSValue *)callBackValue
							 withUserDataValue:(NSValue *)userDataValue 
								   inputString:(NSString *)string
{
	GaimRequestInputCb callBack = [callBackValue pointerValue];
	if (callBack){
		callBack([userDataValue pointerValue],[string UTF8String]);
	}	
}

- (oneway void)doRequestActionCbValue:(NSValue *)callBackValue
					withUserDataValue:(NSValue *)userDataValue
						callBackIndex:(NSNumber *)callBackIndexNumber
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadDoRequestActionCbValue:withUserDataValue:callBackIndex:)
				  withObject:callBackValue
				  withObject:userDataValue
				  withObject:callBackIndexNumber];
}
- (oneway void)gaimThreadDoRequestActionCbValue:(NSValue *)callBackValue
							  withUserDataValue:(NSValue *)userDataValue 
								  callBackIndex:(NSNumber *)callBackIndexNumber
{
	GaimRequestActionCb callBack = [callBackValue pointerValue];
	if (callBack){
		callBack([userDataValue pointerValue],[callBackIndexNumber intValue]);
	}
}


#pragma mark Gaim Images
- (NSString *)_processGaimImagesInString:(NSString *)inString forAdiumAccount:(NSObject<AdiumGaimDO> *)adiumAccount
{
	NSScanner			*scanner;
    NSString			*chunkString = nil;
    NSMutableString		*newString;
	NSString			*targetString = @"<IMG ID=\"";
    int imageID;
	
    //set up
	newString = [[NSMutableString alloc] init];
	
    scanner = [NSScanner scannerWithString:inString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	//A gaim image tag takes the form <IMG ID="12"></IMG> where 12 is the reference for use in GaimStoredImage* gaim_imgstore_get(int)	 
    
	//Parse the incoming HTML
    while(![scanner isAtEnd]){
		
		//Find the beginning of a gaim IMG ID tag
		if ([scanner scanUpToString:targetString intoString:&chunkString]) {
			[newString appendString:chunkString];
		}
		
		if ([scanner scanString:targetString intoString:&chunkString]) {
			
			//Get the image ID from the tag
			[scanner scanInt:&imageID];
			
			//Scan up to ">
			[scanner scanString:@"\">" intoString:nil];
			
			//Get the image, then write it out as a png
			GaimStoredImage		*gaimImage = gaim_imgstore_get(imageID);
			if (gaimImage){
				NSString			*imagePath = [self _messageImageCachePathForID:imageID forAdiumAccount:adiumAccount];
				
				//First make an NSImage, then request a TIFFRepresentation to avoid an obscure bug in the PNG writing routines
				//Exception: PNG writer requires compacted components (bits/component * components/pixel = bits/pixel)
				NSImage				*image = [[NSImage alloc] initWithData:[NSData dataWithBytes:gaim_imgstore_get_data(gaimImage) 
																						  length:gaim_imgstore_get_size(gaimImage)]];
				NSData				*imageTIFFData = [image TIFFRepresentation];
				NSBitmapImageRep	*bitmapRep = [NSBitmapImageRep imageRepWithData:imageTIFFData];
				
				//If writing the PNG file is successful, write an <IMG SRC="filepath"> tag to our string
				if ([[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToFile:imagePath atomically:YES]){
					[newString appendString:[NSString stringWithFormat:@"<IMG SRC=\"%@\">",imagePath]];
				}
				
				[image release];
			}else{
				//If we didn't get a gaimImage, just leave the tag for now.. maybe it was important?
				[newString appendString:chunkString];
			}
		}
	}
	
	return ([newString autorelease]);
}
- (NSString *)_messageImageCachePathForID:(int)imageID forAdiumAccount:(id<AdiumGaimDO>)adiumAccount
{
    NSString    *messageImageCacheFilename = [NSString stringWithFormat:MESSAGE_IMAGE_CACHE_NAME, [adiumAccount internalObjectID], imageID];
    return([[[ACCOUNT_IMAGE_CACHE_PATH stringByAppendingPathComponent:messageImageCacheFilename] stringByAppendingPathExtension:@"png"] stringByExpandingTildeInPath]);	
}

- (oneway void)performContactMenuActionFromDict:(NSDictionary *)dict 
{
	[gaimThreadMessenger target:self
			 performSelector:@selector(gaimThreadPerformContactMenuActionFromDict:)
				  withObject:dict];	
}

- (oneway void)gaimThreadPerformContactMenuActionFromDict:(NSDictionary *)dict
{
	GaimBlistNodeAction *act = [[dict objectForKey:@"GaimBlistNodeAction"] pointerValue];
	GaimBuddy			*buddy = [[dict objectForKey:@"GaimBuddy"] pointerValue];

	//Perform act's callback with the desired buddy and data
	if(act->callback)
		act->callback((GaimBlistNode *)buddy, act->data);
}

- (void)dealloc
{
	gaim_signals_disconnect_by_handle(gaim_adium_get_handle());
	[super dealloc];
}


@end
