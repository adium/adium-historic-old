//
//  SLGaimCocoaAdapter.m
//  Adium
//  Adapts gaim to the Cocoa event loop.
//  Requires Mac OS X 10.2.
//
//  Created by Scott Lamb on Sun Nov 2 2003.
//

#import  <Foundation/Foundation.h>
#include <Libgaim/libgaim.h>
#include <stdlib.h>
#include <glib.h>

#import "SLGaimCocoaAdapter.h"
#import <CoreFoundation/CFSocket.h>
#import <CoreFoundation/CFRunLoop.h>
#import "NDRunLoopMessenger.h"

#import "GaimCommon.h"
#import "CBGaimServicePlugin.h"
#import "CBGaimAccount.h"

#import "ESGaimRequestWindowController.h"
#import "ESGaimRequestActionWindowController.h"
#import "ESGaimNotifyEmailWindowController.h"

@interface SLGaimCocoaAdapter (PRIVATE)
- (void)callTimerFunc:(NSTimer*)timer;
- (void)initLibGaim;
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
static guint				sourceId = nil;		//The next source key; continuously incrementing
static NSMutableDictionary  *sourceInfoDict = nil;
static NDRunLoopMessenger   *runLoopMessenger = nil;

@implementation SLGaimCocoaAdapter

#pragma mark Init

+ (void)createThreadedGaimCocoaAdapter
{
	NSAutoreleasePool   *pool;
	SLGaimCocoaAdapter  *gaimCocoaAdapter;
	pool = [[NSAutoreleasePool alloc] init];

    gaimCocoaAdapter = [[self alloc] init];
	
    [pool release];

    return;
}

+ (SLGaimCocoaAdapter *)sharedInstance
{
	return myself;
}

- (void)addAdiumAccount:(NSObject<AdiumGaimDO> *)adiumAccount
{
	GaimAccount *account = [adiumAccount gaimAccount];
	account->ui_data = adiumAccount;
}

#pragma mark Init
- (id)init
{
	[super init];
	
	sourceId = 0;
    sourceInfoDict = [[NSMutableDictionary alloc] init];
    accountDict = [[NSMutableDictionary alloc] init];
//	contactDict = [[NSMutableDictionary alloc] init];
	chatDict = [[NSMutableDictionary alloc] init];
		
	myself = self;
	
	[self initLibGaim];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotNewAccount:) name:@"AddAccount" object:nil];

	NSConnection *myConnection = [NSConnection defaultConnection];
	
	runLoopMessenger = [NDRunLoopMessenger runLoopMessengerForCurrentRunLoop];

	[[NSRunLoop currentRunLoop] run];

	NSLog(@"DONE!");
    return self;
}

#pragma mark Gaim wrapper

/*
 * Finds an NSObject<AdiumGaimDO>* for a GaimAccount*.
 */

static NSObject<AdiumGaimDO> *accountLookup(GaimAccount *acct)
{
	NSObject<AdiumGaimDO> *adiumGaimAccount = (NSObject<AdiumGaimDO> *)acct->ui_data;

    return adiumGaimAccount;
}

static GaimAccount* accountLookupFromAdiumAccount(id adiumAccount)
{
	return [(CBGaimAccount *)adiumAccount gaimAccount];
}

static AIListContact* contactLookupFromBuddy(GaimBuddy *buddy)
{
	//Get the node's ui_data
	AIListContact *theContact = (AIListContact *)buddy->node.ui_data;
	
	//If the node does not have ui_data yet, we need to create a contact and associate it
	if (!theContact){
		theContact = [accountLookup(buddy->account) mainThreadContactWithUID:[[NSString stringWithUTF8String:buddy->name] compactedString]];
		
		//Associate the handle with ui_data and the buddy with our statusDictionary
//		buddy->node.ui_data = [theContact retain];
		buddy->node.ui_data = theContact;
//		[contactDict setObject:[NSValue valueWithPointer:buddy] forKey:[theContact uniqueObjectID]];
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
		
		chat = [accountLookup(conv->account) chatWithName:name];

		[chatDict setObject:[NSValue valueWithPointer:conv] forKey:[chat uniqueChatID]];
		conv->ui_data = [chat retain];
	}

	return chat;
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
		
		//First, find the GaimBuddy with whom we are conversing
		buddy = gaim_find_buddy(conv->account, conv->name);
		if (!buddy) {
			//No gaim_buddy corresponding to the conv->name is on our list, so create one
			buddy = gaim_buddy_new(conv->account, conv->name, NULL);	//create a GaimBuddy
			group = gaim_find_group(_("Orphans"));						//get the GaimGroup
			if (!group) {												//if the group doesn't exist yet
				group = gaim_group_new(_("Orphans"));					//create the GaimGroup
				gaim_blist_add_group(group, NULL);						//add it gaimside
			}
			gaim_blist_add_buddy(buddy, NULL, group, NULL);     //add the buddy to the gaimside list
			
#warning Must add to serverside list to get status updates.  Need to remove when the chat closes or the account disconnects. Possibly want to use some sort of hidden Adium group for this.
			serv_add_buddy(conv->account->gc, buddy->name, group);				//add it to the serverside list
		}
		
		NSCAssert(buddy != nil, @"buddy was nil");
		
		sourceContact = contactLookupFromBuddy(buddy);
		
		/*
		 ///XXX - Evan: Is this still needed or was it a false failsafe for another bug?
		//If creating a contact from the buddy failed, create a contact using the conversation name
		if (!sourceContact){
			sourceContact = [self contactAssociatedWithConversation:conv withBuddy:buddy];
		}
		 */
		
		// Need to start a new chat, associating with the GaimConversation
		chat = [accountLookup(conv->account) chatWithContact:sourceContact];
		
		//Associate the GaimConversation with the AIChat
		[chatDict setObject:[NSValue valueWithPointer:conv] forKey:[chat uniqueChatID]];
		conv->ui_data = [chat retain];
	}

	return chat;	
}

static GaimConversation* convLookupFromChat(AIChat *chat, id adiumAccount)
{
	GaimConversation	*conv = [[chatDict objectForKey:[chat uniqueChatID]] pointerValue];
	GaimAccount			*account = accountLookupFromAdiumAccount(adiumAccount);
	
	if (!conv && adiumAccount){
		AIListObject *listObject = [chat listObject];
		if (listObject){
			const char			*destination = [[listObject UID] UTF8String];
			conv = gaim_conversation_new(GAIM_CONV_IM,account, destination);
			
			//associate the AIChat with the gaim conv
			imChatLookupFromConv(conv);
		}else{
			
#warning XXX
			const char *name = [[chat name] UTF8String];
			
			//Look for an existing gaimChat (for now, it had better exist already which means trouble if we get here!)
			GaimChat *gaimChat = gaim_blist_find_chat (account, name);
			if (!gaimChat){
				NSLog(@"gotta create a chat");
				GHashTable *components;
				GList *tmp;
				GaimGroup *group;
				const char *group_name = _("Chats");
				
				
				//The below is not even close to right.
				components = g_hash_table_new_full(g_str_hash, g_str_equal,
												   g_free, g_free);
				
				/*
				 g_hash_table_replace(components,
									  g_strdup(g_object_get_data(tmp->data, "identifier")),
									  g_strdup_printf("%d",
													  gtk_spin_button_get_value_as_int(tmp->data)));
				 */
				
				gaimChat = gaim_chat_new(account,
										 name,
										 components);
				
				if ((group = gaim_find_group(group_name)) == NULL)
				{
					group = gaim_group_new(group_name);
					gaim_blist_add_group(group, NULL);
				}
				
				if (gaimChat != NULL)
				{
					gaim_blist_add_chat(gaimChat, group, NULL);
					gaim_blist_save();
				}
				
				//Associate our chat with the libgaim conversation
				NSLog(@"associating the gaimconv");
				GaimConversation 	*conv = gaim_conversation_new(GAIM_CONV_CHAT, account, name);
				
				chatLookupFromConv(conv);
			}
		}
	}
	
	return conv;
}


#pragma mark Debug
// Debug ------------------------------------------------------------------------------------------------------
static void adiumGaimDebugPrint(GaimDebugLevel level, const char *category, const char *format, va_list args)
{
	gchar *arg_s = g_strdup_vprintf(format, args); //NSLog sometimes chokes on the passed args, so we'll use vprintf
	
	//Log error
	if(!category) category = "general"; //Category can be nil
	NSLog(@"%x: (Debug: %s) %s",[NSRunLoop currentRunLoop], category, arg_s);
	
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
	
	NSNumber	*connectionProgressPrecent = [NSNumber numberWithFloat:((float)step/(float)(step_count-1))];
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionProgressStep:percentDone:)
										 withObject:[NSNumber numberWithInt:step]
										 withObject:connectionProgressPrecent];
}

static void adiumGaimConnConnected(GaimConnection *gc)
{
    if(GAIM_DEBUG) NSLog(@"Connected: gc=%x", gc);

	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionConnected)];
}

static void adiumGaimConnDisconnected(GaimConnection *gc)
{
    if(GAIM_DEBUG) NSLog(@"Disconnected: gc=%x", gc);
//    if (_accountDict == nil) // if this has been destroyed, unloadPlugin has already been called
//        return;
    [accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionDisconnected)];
}

static void adiumGaimConnNotice(GaimConnection *gc, const char *text)
{
    if(GAIM_DEBUG) NSLog(@"Connection Notice: gc=%x (%s)", gc, text);
	
	NSString *connectionNotice = [NSString stringWithUTF8String:text];
	[accountLookup(gc->account) mainPerformSelector:@selector(accountConnectionNotice:)
										 withObject:connectionNotice];
}

static void adiumGaimConnReportDisconnect(GaimConnection *gc, const char *text)
{
    if(GAIM_DEBUG) NSLog(@"Connection Disconnected: gc=%x (%s)", gc, text);
	
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
	/*
    if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
		GaimBuddy *buddy = (GaimBuddy*) node;
		
		contactLookupFromBuddy(buddy);
			
		[accountLookup(buddy->account) newContact:(contactLookupFromBuddy(buddy))];
    }
	 */
}

static void adiumGaimBlistShow(GaimBuddyList *list)
{
	
}

static void adiumGaimBlistUpdate(GaimBuddyList *list, GaimBlistNode *node)
{
//    NSCAssert(node != nil, @"BlistUpdate on null node");
//		NSLog(@"Blist update %s",((GaimBuddy*) node)->name);
    if (GAIM_BLIST_NODE_IS_BUDDY(node)) {
		GaimBuddy *buddy = (GaimBuddy*) node;

		AIListContact *theContact = contactLookupFromBuddy(buddy);
		
		//Group changes - gaim buddies start off in no group, so this is an important update for us
		if(![theContact remoteGroupName]){
			GaimGroup *g = gaim_find_buddys_group(buddy);
			if(g && g->name){
				NSString *groupName = [NSString stringWithUTF8String:g->name];
				[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:toGroupName:)
														withObject:theContact
														withObject:groupName];
			}
		}
		
		const char *alias = gaim_get_buddy_alias(buddy);
		if (alias){
			NSString *aliasString = [NSString stringWithUTF8String:alias];
			
			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:toAlias:)
													withObject:theContact
													withObject:aliasString];
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
        buddy->node.ui_data = NULL;
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
	[accountLookup(account) mainPerformSelector:@selector(requestAddContactWithUID:)
									 withObject:[NSString stringWithUTF8String:username]];
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
				updateSelector = @selector(updateIdle:withData:);
				if (buddy->idle){
					data = [NSDate dateWithTimeIntervalSince1970:buddy->idle];
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
				data = [NSData dataWithBytes:gaim_buddy_icon_get_data(buddyIcon, &(buddyIcon->len))
									  length:buddyIcon->len];
				break;
			}
		}
		
		if (updateSelector){
			[accountLookup(buddy->account) mainPerformSelector:updateSelector
													withObject:theContact
													withObject:data];
		}else{
			[accountLookup(buddy->account) mainPerformSelector:@selector(updateContact:forEvent:)
													withObject:theContact
													withObject:[NSNumber numberWithInt:event]];
		}
	}
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
	//Gaim is telling us a conv was destroyed.  This should only happen when we tell it to, and that via closeChat: below
	//so we should not need to do anything here.
}

static void adiumGaimConvWriteChat(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	NSDictionary *messageDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:message],@"Message",
		[NSString stringWithUTF8String:who],@"Source",
		[NSNumber numberWithInt:flags],@"GaimMessageFlags",
		[NSDate dateWithTimeIntervalSince1970:mtime],@"Date",nil];
	
	[accountLookup(conv->account) mainPerformSelector:@selector(receivedMultiChatMessage:inChat:)
										   withObject:messageDict
										   withObject:chatLookupFromConv(conv)];
}

static void adiumGaimConvWriteIm(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	NSDictionary *messageDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:message],@"Message",
		[NSNumber numberWithInt:flags],@"GaimMessageFlags",
		[NSDate dateWithTimeIntervalSince1970:mtime],@"Date",nil];
		
	[accountLookup(conv->account) mainPerformSelector:@selector(receivedIMChatMessage:inChat:)
										   withObject:messageDict
										   withObject:imChatLookupFromConv(conv)];
}

//Never actually called as of gaim 0.75
static void adiumGaimConvWriteConv(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	NSLog(@"adiumGaimConvWriteConv: %s: %s", who, message);
}

static void adiumGaimConvChatAddUser(GaimConversation *conv, const char *user)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){
		[accountLookup(conv->account) mainPerformSelector:@selector(addUser:toChat:)
											   withObject:[NSString stringWithUTF8String:user]
											   withObject:chatLookupFromConv(conv)];
	}
	
}

static void adiumGaimConvChatAddUsers(GaimConversation *conv, GList *users)
{
//	[accountLookup(conv->account) accountConvAddedUsers:users inConversation:conv];
}

static void adiumGaimConvChatRenameUser(GaimConversation *conv, const char *oldName, const char *newName)
{
	if (GAIM_DEBUG) NSLog(@"adiumGaimConvChatRenameUser");
}

static void adiumGaimConvChatRemoveUser(GaimConversation *conv, const char *user)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){
		[accountLookup(conv->account) mainPerformSelector:@selector(removeUser:fromChat:)
											   withObject:[NSString stringWithUTF8String:user]
											   withObject:chatLookupFromConv(conv)];
	}
}

static void adiumGaimConvChatRemoveUsers(GaimConversation *conv, GList *users)
{
//	[accountLookup(conv->account) accountConvRemovedUsers:users inConversation:conv];
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
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT){
		[accountLookup(conv->account) mainPerformSelector:@selector(updateForChat:type:)
											withObject:chatLookupFromConv(conv)
											   withObject:[NSNumber numberWithInt:type]];
		
	}else if (gaim_conversation_get_type(conv) == GAIM_CONV_IM){
		
		GaimConvIm  *im = gaim_conversation_get_im_data(conv);
		switch (type) {
			case GAIM_CONV_UPDATE_TYPING: {
				NSNumber	*isTyping = [NSNumber numberWithBool:(gaim_conv_im_get_typing_state(im) == GAIM_TYPING)];
				
				[accountLookup(conv->account) mainPerformSelector:@selector(typingUpdateForIMChat:typing:)
													   withObject:imChatLookupFromConv(conv)
													   withObject:isTyping];
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

		AIChat *chat = chatLookupFromConv(conv);
			
		[accountLookup(conv->account) mainPerformSelector:@selector(addChat:)
											   withObject:chat];
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
static void *adiumGaimNotifyMessage(GaimNotifyMsgType type, const char *title, const char *primary, const char *secondary, GCallback cb,void *userData)
{
    //Values passed can be null
    NSLog(@"adiumGaimNotifyMessage: %s: %s, %s", title, primary, secondary);
	return ([myself handleNotifyMessageOfType:type withTitle:title primary:primary secondary:secondary]);
}

static void *adiumGaimNotifyEmails(size_t count, gboolean detailed, const char **subjects, const char **froms, const char **tos, const char **urls, GCallback cb,void *userData)
{
    //Values passed can be null
    NSLog(@"adiumGaimNotifyEmails");
	return ([myself handleNotifyEmails:count detailed:detailed subjects:subjects froms:froms tos:tos urls:urls]);
}

static void *adiumGaimNotifyEmail(const char *subject, const char *from, const char *to, const char *url, GCallback cb,void *userData)
{
	return adiumGaimNotifyEmails(1, TRUE,
								 (subject == NULL ? NULL : &subject),
								 (from    == NULL ? NULL : &from),
								 (to      == NULL ? NULL : &to),
								 (url     == NULL ? NULL : &url),
								 cb, userData);
}

static void *adiumGaimNotifyFormatted(const char *title, const char *primary, const char *secondary, const char *text, GCallback cb,void *userData)
{
	NSLog(@"adiumGaimNotifyFormatted");
    return(nil);
}

static void *adiumGaimNotifyUri(const char *uri)
{
	NSLog(@"Notify uri: %s",uri);
	
	NSURL   *notifyURI = [NSURL URLWithString:uri];
	[[NSWorkspace shareworkspace] openURL:notifyURI];

    return(nil);
}

static void adiumGaimNotifyClose(GaimNotifyType type,void *uiHandle)
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
			
	if (secondaryString && [secondaryString rangeOfString:@"Could not add the buddy 1 for an unknown reason"].location != NSNotFound){
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
#warning This generates really ugly output in most cases; the title should not be used as it is
	[[adium interfaceController] mainPerformSelector:@selector(handleMessage:withDescription:withWindowTitle:)
										  withObject:([errorMessage length] ? errorMessage : primaryString)
										  withObject:([description length] ? description : ([secondaryString length] ? secondaryString : @"") )
										  withObject:titleString];
	
	return nil;
}

- (void *)handleNotifyEmails:(size_t)count detailed:(BOOL)detailed subjects:(const char **)subjects froms:(const char **)froms tos:(const char **)tos urls:(const char **)urls
{
	NSFontManager				*fontManager = [NSFontManager sharedFontManager];
	NSFont						*messageFont = [NSFont messageFontOfSize:11];
	NSMutableParagraphStyle		*centeredParagraphStyle;
	NSMutableAttributedString   *message;
	
	centeredParagraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[centeredParagraphStyle setAlignment:NSCenterTextAlignment];
	message = [[[NSMutableAttributedString alloc] init] autorelease];
	
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
	
	return(nil);
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

    return(nil);
}

static void *adiumGaimRequestChoice(const char *title, const char *primary, const char *secondary, unsigned int defaultValue, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData, size_t choiceCount, va_list choices)
{
    NSLog(@"adiumGaimRequestChoice");
    return(nil);
}

//Gaim requests the user take an action such as accept or deny a buddy's attempt to add us to her list 
static void *adiumGaimRequestAction(const char *title, const char *primary, const char *secondary, unsigned int default_action,void *userData, size_t actionCount, va_list actions)
{
    int		    alertReturn, i;
	
    NSString	    *titleString = (title ? [NSString stringWithUTF8String:title] : @"");
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
		int actualCount = [buttonNamesArray count];
			
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
    return(nil);
}

static void *adiumGaimRequestFields(const char *title, const char *primary, const char *secondary, GaimRequestFields *fields, const char *okText, GCallback okCb, const char *cancelText, GCallback cancelCb,void *userData)
{
    NSLog(@"adiumGaimRequestFields");
    return(nil);
}

static void *adiumGaimRequestFile(const char *title, const char *filename, GCallback ok_cb, GCallback cancel_cb,void *user_data)
{
	NSLog(@"adiumGaimRequestFile");
	return(nil);
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
	NSLog(@"adiumGaimNewXfer");
}

static void adiumGaimDestroy(GaimXfer *xfer)
{
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	[accountLookup(xfer->account) mainPerformSelector:@selector(destroyFileTransfer:)
										   withObject:fileTransfer];
	
	xfer->ui_data = nil;
}

static void adiumGaimRequestXfer(GaimXfer *xfer)
{
    GaimXferType xferType = gaim_xfer_get_type(xfer);
    if (xferType == GAIM_XFER_RECEIVE) {
		NSLog(@"File request: %s from %s on IP %s",xfer->filename,xfer->who,gaim_xfer_get_remote_ip(xfer));
        
		ESFileTransfer  *fileTransfer;
		NSString		*destinationUID = [NSString stringWithUTF8String:(xfer->who)];
		
		//Ask the account for an ESFileTransfer* object
		fileTransfer = [accountLookup(xfer->account) newFileTransferObjectWith:destinationUID];
		
		//Configure the new object for the transfer
		[fileTransfer setRemoteFilename:[NSString stringWithUTF8String:(xfer->filename)]];
		[fileTransfer setAccountData:[NSValue valueWithPointer:xfer]];
		xfer->ui_data = [fileTransfer retain];
		
		//Tell the account that we are ready to request the reception
        [accountLookup(xfer->account) mainPerformSelector:@selector(requestReceiveOfFileTransfer:)
											   withObject:fileTransfer];
		
    } else if (xferType == GAIM_XFER_SEND) {
		NSCAssert(xfer->local_filename != nil, @"adiumGaimRequestFile: Attempted to send nil file...");
		NSLog(@"beginning send %s.",xfer->local_filename);
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
	NSLog(@"transfer update: %s is now %f%% done",xfer->filename,(percent*100));
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	
    [accountLookup(xfer->account) mainPerformSelector:@selector(updateProgressForFileTransfer:percent:bytesSent:)
										   withObject:fileTransfer
										   withObject:[NSNumber numberWithFloat:percent]
										   withObject:[NSNumber numberWithFloat:xfer->bytes_sent]];
}

static void adiumGaimCancelLocal(GaimXfer *xfer)
{
	NSLog(@"adiumGaimCancelLocal");
}

static void adiumGaimCancelRemote(GaimXfer *xfer)
{
	NSLog(@"adiumGaimCancelRemote");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) mainPerformSelector:@selector(fileTransferCanceledRemotely:)
										   withObject:fileTransfer];
}

static GaimXferUiOps adiumGaimFileTransferOps = {
    adiumGaimNewXfer,
    adiumGaimDestroy,
    adiumGaimRequestXfer,
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
	[accountLookup(account)	mainPerformSelector:@selector(privacyPermitListAdded:)
									 withObject:[NSString stringWithUTF8String:name]];
}
static void adiumGaimPermitRemoved(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyPermitListRemoved:)
									 withObject:[NSString stringWithUTF8String:name]];
}
static void adiumGaimDenyAdded(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyDenyListAdded:)
									 withObject:[NSString stringWithUTF8String:name]];
}
static void adiumGaimDenyRemoved(GaimAccount *account, const char *name)
{
	[accountLookup(account)	mainPerformSelector:@selector(privacyDenyListRemoved:)
									 withObject:[NSString stringWithUTF8String:name]];
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
    NSTimer *timer;
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

guint adium_timeout_add(guint interval, GSourceFunc function, gpointer data)
{
    //NSLog(@"New %u-ms timer (tag %u)", interval, sourceId);
	
    struct SourceInfo *info = (struct SourceInfo*)malloc(sizeof(struct SourceInfo));
	
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)interval/1000
                                                      target:myself
                                                    selector:@selector(callTimerFunc:)
                                                    userInfo:[NSValue valueWithPointer:info]
                                                     repeats:YES];
	
	sourceId++;
	
    info->tag = sourceId;
    info->sourceFunction = function;
    info->timer = [timer retain];
    info->socket = NULL;
    info->rls = NULL;
    info->user_data = data;
    NSCAssert1([sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:sourceId]] == nil, @"Key %u in use", sourceId);
    [sourceInfoDict setObject:[NSValue valueWithPointer:info]
					   forKey:[NSNumber numberWithUnsignedInt:sourceId]];
    return sourceId;
}

- (void) callTimerFunc:(NSTimer*)timer
{
    struct SourceInfo *info = [[timer userInfo] pointerValue];
    if ([sourceInfoDict objectForKey:[NSNumber numberWithUnsignedInt:info->tag]] == nil) {
		        NSLog(@"Timer %u notification arrived after source removed", info->tag);
        return;
    }
	
    if (! info->sourceFunction(info->user_data)) {
        adium_source_remove(info->tag);
	}
}

guint adium_input_add(int fd, GaimInputCondition condition,
					  GaimInputFunction func, gpointer user_data)
{
    struct SourceInfo *info = g_new(struct SourceInfo, 1);

	if (GAIM_DEBUG) NSLog(@"Adding for %i",fd);
	
    // Build the CFSocket-style callback flags to use from the gaim ones
    CFOptionFlags callBackTypes = 0;
    if ((condition & GAIM_INPUT_READ ) != 0) callBackTypes |= kCFSocketReadCallBack;
    if ((condition & GAIM_INPUT_WRITE) != 0) callBackTypes |= kCFSocketWriteCallBack;
//	if ((condition & GAIM_INPUT_CONNECT) != 0) callBackTypes |= kCFSocketConnectCallBack;
	
    // And likewise the entire CFSocket
    CFSocketContext context = { 0, info, NULL, NULL, NULL };
    CFSocketRef socket = CFSocketCreateWithNative(NULL, fd, callBackTypes, socketCallback, &context);
    NSCAssert(socket != NULL, @"CFSocket creation failed");
    info->socket = socket;
	
    // Re-enable callbacks automatically and _don't_ close the socket on
    // invalidate
    CFSocketSetSocketFlags(socket,   /*kCFSocketAutomaticallyReenableDataCallBack
						   | */kCFSocketAutomaticallyReenableWriteCallBack
						   | kCFSocketAutomaticallyReenableReadCallBack);
	
    // Add it to our run loop
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(NULL, socket, 0);
	
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopCommonModes);
	
	sourceId++;
	
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
	
	if (GAIM_DEBUG) NSLog(@"***SOURCE REMOVE : %i",tag);
    if (sourceInfo){
		if (sourceInfo->timer != NULL) { 
			//Got a timer; invalidate and release
			[sourceInfo->timer invalidate];
			[sourceInfo->timer release];
			
		}else{
			//Got a file handle; invalidate the source and the socket
			CFRunLoopSourceInvalidate(sourceInfo->rls);
			CFSocketInvalidate(sourceInfo->socket);
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
    struct SourceInfo *info = (struct SourceInfo*) infoVoid;
	
    GaimInputCondition c = 0;
    if ((callbackType & kCFSocketReadCallBack) != 0)  c |= GAIM_INPUT_READ;
    if ((callbackType & kCFSocketWriteCallBack) != 0) c |= GAIM_INPUT_WRITE;
//	if ((callbackType & kCFSocketConnectCallBack) != 0) c |= GAIM_INPUT_CONNECT;

	if (GAIM_DEBUG) NSLog(@"***SOCKETCALLBACK : %i (%i)",info->fd,c);
	
	if ((callbackType & kCFSocketConnectCallBack) != 0) {
		//Got a file handle; invalidate the source and the socket
		if (GAIM_DEBUG) NSLog(@"got a connect callback %i",info->fd);
		CFRunLoopSourceInvalidate(info->rls);
		CFSocketInvalidate(info->socket);
		
		[sourceInfoDict removeObjectForKey:[NSNumber numberWithUnsignedInt:info->tag]];
		info->ioFunction(info->user_data, info->fd, c);
		free(info);
		
	}else{
		info->ioFunction(info->user_data, info->fd, c);
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
		NSLog(@"%x: Registering debug functions",[NSRunLoop currentRunLoop]);
    gaim_debug_set_ui_ops(&adiumGaimDebugOps);
#endif
}

static void adiumGaimCoreUiInit(void)
{
if (GAIM_DEBUG)	NSLog(@"%x: Registering core functions",[NSRunLoop currentRunLoop]);
	gaim_eventloop_set_ui_ops(&adiumEventLoopUiOps);
    gaim_blist_set_ui_ops(&adiumGaimBlistOps);
    gaim_connections_set_ui_ops(&adiumGaimConnectionOps);
    gaim_conversations_set_win_ui_ops(&adiumGaimWindowOps);
    gaim_notify_set_ui_ops(&adiumGaimNotifyOps);
    gaim_request_set_ui_ops(&adiumGaimRequestOps);
    gaim_xfers_set_ui_ops(&adiumGaimFileTransferOps);
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

- (void)initLibGaim
{	
	//Register ourself as libgaim's UI handler
	gaim_core_set_ui_ops(&adiumGaimCoreOps);
	if(!gaim_core_init("Adium")) {
		NSLog(@"Failed to initialize gaim core");
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
}

#pragma mark Thread accessors

- (void)connectAccount:(id)adiumAccount
{
	[runLoopMessenger target:self 
			 performSelector:@selector(gaimThreadConnectAccount:) 
				  withObject:adiumAccount];
}
- (void)gaimThreadConnectAccount:(id)adiumAccount
{
	gaim_account_connect(accountLookupFromAdiumAccount(adiumAccount));
}

- (void)disconnectAccount:(id)adiumAccount
{
	[runLoopMessenger target:self 
			 performSelector:@selector(gaimThreadDisconnectAccount:) 
				  withObject:adiumAccount];
}
- (void)gaimThreadDisconnectAccount:(id)adiumAccount
{
	gaim_account_disconnect(accountLookupFromAdiumAccount(adiumAccount));
}

- (oneway void)sendMessage:(NSString *)encodedMessage fromAccount:(id)sourceAccount inChat:(AIChat *)chat withFlags:(int)flags
{
	[runLoopMessenger target:self 
			 performSelector:@selector(gaimThreadSendMessage:fromAccount:inChat:withFlags:) 
				  withObject:encodedMessage
				  withObject:sourceAccount
				  withObject:chat
				  withObject:[NSNumber numberWithInt:flags]];
}
- (oneway void)gaimThreadSendMessage:(NSString *)encodedMessage
						 fromAccount:(id)sourceAccount
							  inChat:(AIChat *)chat
						   withFlags:(NSNumber *)flags
{
	GaimConversation *conv = convLookupFromChat(chat,sourceAccount);
	
	switch (gaim_conversation_get_type(conv)) {				
		case GAIM_CONV_IM: {
			GaimConvIm			*im = gaim_conversation_get_im_data(conv);
			gaim_conv_im_send_with_flags(im,[encodedMessage UTF8String],[flags intValue]);
			break;
		}
			
		case GAIM_CONV_CHAT: {
			GaimConvChat	*gaimChat = gaim_conversation_get_chat_data(conv);
			gaim_conv_chat_send(gaimChat,[encodedMessage UTF8String]);
			break;
		}
	}
}

- (oneway void)sendTyping:(BOOL)typing inChat:(AIChat *)chat
{
	[runLoopMessenger target:self 
			 performSelector:@selector(gaimThreadSendTyping:inChat:)
				  withObject:[NSNumber numberWithBool:typing]
				  withObject:chat];
}
- (oneway void)gaimThreadSendTyping:(NSNumber *)typing inChat:(AIChat *)chat
{
	GaimConversation *conv = convLookupFromChat(chat,nil);
	if (conv){
		serv_send_typing(gaim_conversation_get_gc(conv),
						 gaim_conversation_get_name(conv),
						 ([typing boolValue] ? GAIM_TYPING : GAIM_NOT_TYPING));
	}	
}

- (oneway void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	[runLoopMessenger target:self 
			 performSelector:@selector(gaimThreadAddUID:onAccount:toGroup:)
				  withObject:objectUID
				  withObject:adiumAccount
				  withObject:groupName];
}

- (oneway void)gaimThreadAddUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	const char  *buddyUID = [objectUID UTF8String];
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	const char  *groupUTF8String = (groupName ? [groupName UTF8String] : "");
	
	//Get the group (Create if necessary)
	GaimGroup *group = gaim_find_group(groupUTF8String);
	if(!group){
		group = gaim_group_new(groupUTF8String);
		gaim_blist_add_group(group, NULL);
	}
	
	//Verify the buddy does not already exist and create it
	GaimBuddy *buddy = gaim_find_buddy(account,buddyUID);
	if(!buddy){
		buddy = gaim_buddy_new(account, buddyUID, NULL);
		
		//Add the buddy locally to libgaim and then to the serverside list
		gaim_blist_add_buddy(buddy, NULL, group, NULL);
		serv_add_buddy(account->gc, buddyUID, group);
	}	
}

- (oneway void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName
{
	[runLoopMessenger target:self performSelector:@selector(gaimThreadRemoveUID:onAccount:fromGroup:)
				  withObject:objectUID
				  withObject:adiumAccount
				  withObject:groupName];
}
- (oneway void)gaimThreadRemoveUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	const char  *buddyUID = [objectUID UTF8String];
	const char  *groupUTF8String = (groupName ? [groupName UTF8String] : "");
	
	GaimBuddy 	*buddy = gaim_find_buddy(account, buddyUID);
	
	//Remove this contact from the server-side and gaim-side lists
	serv_remove_buddy(account->gc, buddyUID, groupUTF8String);
	if (buddy){
		gaim_blist_remove_buddy(buddy);
	}
}

- (oneway void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	[runLoopMessenger target:self performSelector:@selector(gaimThreadMoveUID:onAccount:toGroup:)
				  withObject:objectUID
				  withObject:adiumAccount
				  withObject:groupName];
}
- (oneway void)gaimThreadMoveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	const char  *buddyUID = [objectUID UTF8String];
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	
	//Get the destination group (creating if necessary)
	const char  *groupUTF8String = (groupName ? [groupName UTF8String] : "");
	GaimGroup 	*destGroup = gaim_find_group(groupUTF8String);
	if(!destGroup) destGroup = gaim_group_new(groupUTF8String);
	
	//Get the gaim buddy and group for this move
	GaimBuddy *buddy = gaim_find_buddy(account,buddyUID);
	GaimGroup *oldGroup = gaim_find_buddys_group(buddy);
	if(buddy){
		if (oldGroup) {
			//Procede to move the buddy gaim-side and locally
			serv_move_buddy(buddy, oldGroup, destGroup);
		} else {
			//The buddy was not in any group before; add the buddy to the desired group
			serv_add_buddy(account->gc, buddyUID, destGroup);
		}
	}	
}

- (oneway void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName
{	
	[runLoopMessenger target:self performSelector:@selector(gaimThreadRenameGroup:onAccount:to:)
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

		/*
	     //Is this needed?
		 gaim_blist_remove_group(group);                         //remove the old one gaimside
		 */
	}	
}

- (oneway void)openChat:(AIChat *)chat onAccount:(id)adiumAccount
{
	[runLoopMessenger target:self performSelector:@selector(gaimThreadOpenChat:onAccount:)
				  withObject:chat
				  withObject:adiumAccount];
}
- (oneway void)gaimThreadOpenChat:(AIChat *)chat onAccount:(id)adiumAccount
{
	GaimConversation *conv = convLookupFromChat(chat,adiumAccount);
}

- (oneway void)closeChat:(AIChat *)chat
{
	[runLoopMessenger target:self performSelector:@selector(gaimThreadCloseChat:)
				  withObject:chat];
}
- (oneway void)gaimThreadCloseChat:(AIChat *)chat
{
	GaimConversation *conv = convLookupFromChat(chat,nil);
	
	[chatDict removeObjectForKey:[chat uniqueChatID]];
	
	if (conv){
		AIChat *uiDataChat = conv->ui_data;
		if (chat == uiDataChat){
			[uiDataChat release];
		}
		conv->ui_data = nil;
		
		gaim_conversation_destroy(conv);
	}
}

- (void)dealloc
{
	gaim_signals_disconnect_by_handle(gaim_adium_get_handle());
	[super dealloc];
}


@end
