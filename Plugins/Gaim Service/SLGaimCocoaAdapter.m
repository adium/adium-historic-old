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

#import "SLGaimCocoaAdapter.h"

#import "AIAccountController.h"
#import "AIInterfaceController.h"
#import "AILoginController.h"
#import "CBGaimAccount.h"
#import "ESGaimAIMAccount.h"
#import "CBGaimServicePlugin.h"
#import "adiumGaimCore.h"
#import "adiumGaimOTR.h"
#import <AIUtilities/CBObjectAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/NDRunLoopMessenger.h>
#import <CoreFoundation/CFRunLoop.h>
#import <CoreFoundation/CFSocket.h>
#include <Libgaim/libgaim.h>
#include <glib.h>
#include <stdlib.h>

//For MSN user icons
//#include <libgaim/session.h>
//#include <libgaim/userlist.h>
//#include <libgaim/user.h>



//Gaim slash command interface
#include <Libgaim/cmds.h>

//Webcam
#include <Libgaim/webcam.h>

@interface SLGaimCocoaAdapter (PRIVATE)
- (void)initLibGaim;
- (BOOL)attemptGaimCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat;
@end

/*
 * A pointer to the single instance of this class active in the application.
 * The gaim callbacks need to be C functions with specific prototypes, so they
 * can't be ObjC methods. The ObjC callbacks do need to be ObjC methods. This
 * allows the C ones to call the ObjC ones.
 **/
static SLGaimCocoaAdapter   *sharedInstance = nil;

//Dictionaries to track gaim<->adium interactions
NSMutableDictionary *accountDict = nil;
//NSMutableDictionary *contactDict = nil;
NSMutableDictionary *chatDict = nil;

static NDRunLoopMessenger		*gaimThreadMessenger = nil;
static SLGaimCocoaAdapter		*gaimThreadProxy = nil;
static NSLock					*gaimThreadCreationLock = nil;

//The autorelease pool presently in use; it will be periodically released and recreated
static NSAutoreleasePool *currentAutoreleasePool = nil;
#define	AUTORELEASE_POOL_REFRESH	5.0

@implementation SLGaimCocoaAdapter

/*!
 * @brief Create the instance of SLGaimCocoaAdapter used throughout this program session
 *
 * Called on the Gaim thread, never returns until the program terminates
 */
+ (void)_createThreadedGaimCocoaAdapter
{
	SLGaimCocoaAdapter  *gaimCocoaAdapter;

	//Will not return until the program terminates
    gaimCocoaAdapter = [[self alloc] init];
	
	[gaimCocoaAdapter release];
}

/*!
 * @brief Called early in the startup process by CBGaimServicePlugin to begin initializing Gaim
 *
 * Should only be called once.  Creates and locks gaimThreadCreationLock so later activity can relock in order to wait
 * on the thread to be ready for use.
 */
+ (void)prepareSharedInstance
{
	//Create the lock to be able to wait for the gaim thread to be ready
	gaimThreadCreationLock = [[NSLock alloc] init];
	
	//Obtain it
	[gaimThreadCreationLock lock];
	
	//Detach the thread which will serve for all gaim messaging in the future
	[NSThread detachNewThreadSelector:@selector(_createThreadedGaimCocoaAdapter)
							 toTarget:[self class]
						   withObject:nil];
}

/*!
 * @brief Return the shared instance
 *
 * Should only be called once and then cached by CBGaimAccount.  Locks gaimThreadCreationLock, which will only be
 * unlocked once the gaim thread is fully ready for use.
 */
+ (SLGaimCocoaAdapter *)sharedInstance
{
	//Wait for the lock to be unlocked once the thread is ready
	[gaimThreadCreationLock lock];
	
	//No further need for the lock
	[gaimThreadCreationLock release]; gaimThreadCreationLock = nil;
	
	return sharedInstance;
}

+ (NDRunLoopMessenger *)gaimThreadMessenger
{
	return gaimThreadMessenger;
}

//Register the account gaimside in the gaim thread to avoid a conflict on the g_hash_table containing accounts
- (void)gaimThreadAddGaimAccount:(GaimAccount *)account
{
    gaim_accounts_add(account);	
}
- (void)addAdiumAccount:(CBGaimAccount *)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	account->ui_data = [adiumAccount retain];
	
	[gaimThreadProxy gaimThreadAddGaimAccount:account];
}

//Remove an account gaimside
- (void)gaimThreadRemoveGaimAccount:(GaimAccount *)account
{
    gaim_accounts_remove(account);	
}
- (void)removeAdiumAccount:(CBGaimAccount *)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);

	[(CBGaimAccount *)account->ui_data release];
	account->ui_data = nil;
	
	[gaimThreadProxy gaimThreadRemoveGaimAccount:account];
}

#pragma mark Initialization
- (id)init
{
	NSTimer	*autoreleaseTimer;

	currentAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	if((self = [super init]))
	{
		accountDict = [[NSMutableDictionary alloc] init];
		chatDict = [[NSMutableDictionary alloc] init];
			
		sharedInstance = self;
		
		[self initLibGaim];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(gotNewAccount:) 
													 name:@"AddAccount"
												   object:nil];
		
		gaimThreadMessenger = [[NDRunLoopMessenger runLoopMessengerForCurrentRunLoop] retain];
		gaimThreadProxy = [[gaimThreadMessenger target:self] retain];
		
		//Use a time to periodically release our autorelease pool so we don't continually grow in memory usage
		autoreleaseTimer = [[NSTimer scheduledTimerWithTimeInterval:AUTORELEASE_POOL_REFRESH
															 target:self
														   selector:@selector(refreshAutoreleasePool:)
														   userInfo:nil
															repeats:YES] retain];

		//We're ready now, so unlock the creation lock which is being waited upon in the main thread
		[gaimThreadCreationLock unlock];

		CFRunLoopRun();

		[autoreleaseTimer invalidate]; [autoreleaseTimer release];
		[gaimThreadMessenger release]; gaimThreadMessenger = nil;
		[gaimThreadProxy release]; gaimThreadProxy = nil;
		[currentAutoreleasePool release];
	}
			
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


- (void)initLibGaim
{	
	//Set the gaim user directory to be within this user's directory
	NSString	*gaimUserDir = [[[adium loginController] userDirectory] stringByAppendingPathComponent:@"libgaim"];
	set_gaim_user_dir([[gaimUserDir stringByExpandingTildeInPath] UTF8String]);
	
	//Register ourself as libgaim's UI handler; this will call back on a function in which we finish configuring libgaim
	gaim_core_set_ui_ops(adium_gaim_core_get_ops());
	if(!gaim_core_init("Adium")) {
		NSLog(@"*** FATAL ***: Failed to initialize gaim core");
		GaimDebug (@"*** FATAL ***: Failed to initialize gaim core");
	}
}

#pragma mark Lookup functions

NSString* serviceClassForGaimProtocolID(const char *protocolID)
{
	NSString	*serviceClass = nil;
	if(protocolID){
		if(!strcmp(protocolID, "prpl-oscar"))
			serviceClass = @"AIM-compatible";
		else if(!strcmp(protocolID, "prpl-gg"))
			serviceClass = @"Gadu-Gadu";
		else if(!strcmp(protocolID, "prpl-jabber"))
			serviceClass = @"Jabber";
		else if(!strcmp(protocolID, "prpl-meanwhile"))
			serviceClass = @"Sametime";
		else if(!strcmp(protocolID, "prpl-msn"))
			serviceClass = @"MSN";
		else if(!strcmp(protocolID, "prpl-novell"))
			serviceClass = @"GroupWise";
		else if(!strcmp(protocolID, "prpl-yahoo"))
			serviceClass = @"Yahoo!";
		else if(!strcmp(protocolID, "prpl-zephyr"))
			serviceClass = @"Zephyr";
	}
	
	return serviceClass;
}

/*
 * Finds an instance of CBGaimAccount for a pointer to a GaimAccount struct.
 */
CBGaimAccount* accountLookup(GaimAccount *acct)
{
	CBGaimAccount *adiumGaimAccount = (acct ? (CBGaimAccount *)acct->ui_data : nil);
	/* If the account doesn't have its ui_data associated yet (we haven't tried to connect) but we want this
	 * lookup data, we have to do some manual parsing.  This is used for example from the OTR preferences.
	 */
	if(!adiumGaimAccount && acct){
		const char	*protocolID = acct->protocol_id;
		NSString	*serviceClass = serviceClassForGaimProtocolID(protocolID);

		NSEnumerator	*enumerator = [[[[AIObject sharedAdiumInstance] accountController] accounts] objectEnumerator];
		while(adiumGaimAccount = [enumerator nextObject]){
			if([adiumGaimAccount isKindOfClass:[CBGaimAccount class]] &&
			   [[[adiumGaimAccount service] serviceClass] isEqualToString:serviceClass] &&
			   [[adiumGaimAccount UID] caseInsensitiveCompare:[NSString stringWithUTF8String:acct->username]] == NSOrderedSame){
				break;
			}
		}
	}
    return adiumGaimAccount;
}

GaimAccount* accountLookupFromAdiumAccount(CBGaimAccount *adiumAccount)
{
	return [adiumAccount gaimAccount];
}

AIListContact* contactLookupFromBuddy(GaimBuddy *buddy)
{
	//Get the node's ui_data
	AIListContact *theContact = (buddy ? (AIListContact *)buddy->node.ui_data : nil);

	//If the node does not have ui_data yet, we need to create a contact and associate it
	if (!theContact && buddy){
		NSString	*UID;
	
		UID = [NSString stringWithUTF8String:gaim_normalize(buddy->account, buddy->name)];
		
		theContact = [accountLookup(buddy->account) mainThreadContactWithUID:UID];
		
		//Associate the handle with ui_data and the buddy with our statusDictionary
		buddy->node.ui_data = [theContact retain];
	}
	
	return theContact;
}

AIListContact* contactLookupFromIMConv(GaimConversation *conv)
{
	
}

AIChat* chatLookupFromConv(GaimConversation *conv)
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

AIChat* existingChatLookupFromConv(GaimConversation *conv)
{
	return((conv ? conv->ui_data : nil));
}

AIChat* imChatLookupFromConv(GaimConversation *conv)
{
	AIChat			*chat;
	
	chat = (AIChat *)conv->ui_data;

	if (!chat){
		//No chat is associated with the IM conversation
		AIListContact   *sourceContact;
		GaimBuddy		*buddy;
		GaimAccount		*account;
		
		account = conv->account;
//		GaimDebug (@"%x conv->name %s; normalizes to %s",account,conv->name,gaim_normalize(account,conv->name));

		//First, find the GaimBuddy with whom we are conversing
		buddy = gaim_find_buddy(account, conv->name);
		if (!buddy) {
			GaimDebug (@"imChatLookupFromConv: Creating %s %s",account->username,gaim_normalize(account,conv->name));
			//No gaim_buddy corresponding to the conv->name is on our list, so create one
			buddy = gaim_buddy_new(account, gaim_normalize(account, conv->name), NULL);	//create a GaimBuddy
		}

		NSCAssert(buddy != nil, @"buddy was nil");
		
		sourceContact = contactLookupFromBuddy(buddy);

		// Need to start a new chat, associating with the GaimConversation
		chat = [accountLookup(account) mainThreadChatWithContact:sourceContact];

		NSCAssert5(chat != nil, @"conv %x: Got nil chat in lookup for sourceContact %@ (%x) on adiumAccount %@ (%x)",
				   conv,
				   sourceContact,
				   buddy,
				   accountLookup(account),
				   account);

		//Associate the GaimConversation with the AIChat
		[chatDict setObject:[NSValue valueWithPointer:conv] forKey:[chat uniqueChatID]];
		conv->ui_data = [chat retain];
	}

	return chat;	
}

GaimConversation* convLookupFromChat(AIChat *chat, id adiumAccount)
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
			if(conv) imChatLookupFromConv(conv);

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
					
					if( shouldTryToJoin ) {
					//Join the chat serverside - the GHsahTable components, couple with the originating GaimConnect,
					//now contains all the information the prpl will need to process our request.
						GaimDebug (@"In the event of an emergency, your GHashTable may be used as a flotation device...");
						serv_join_chat(gc, components);
					} else {
						//NSLog(@"#### Bailing out of group chat");
					}
				}
			}
		}
	}
	
	return conv;
}

GaimConversation* existingConvLookupFromChat(AIChat *chat)
{
	return (GaimConversation *)[[chatDict objectForKey:[chat uniqueChatID]] pointerValue];
}

void* adium_gaim_get_handle(void)
{
	static int adium_gaim_handle;
	
	return &adium_gaim_handle;
}

NSMutableDictionary* get_chatDict(void)
{
	return chatDict;
}

#pragma mark Notify
// Notify ----------------------------------------------------------------------------------------------------------
// We handle the notify messages within SLGaimCocoaAdapter so we can use our localized string macro
- (void *)handleNotifyMessageOfType:(GaimNotifyType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;
{
    NSString *primaryString = [NSString stringWithUTF8String:primary];
	NSString *secondaryString = secondary ? [NSString stringWithUTF8String:secondary] : nil;
	
	NSString *titleString;
	if (title){
		titleString = [NSString stringWithFormat:AILocalizedString(@"Adium Notice: %@",nil),[NSString stringWithUTF8String:title]];
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
			([secondaryString rangeOfString:@"Not logged in"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Passport not verified"].location != NSNotFound)){
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
	
	//If we didn't grab a translated version, at least display the English version Gaim supplied
	[[adium interfaceController] mainPerformSelector:@selector(handleMessage:withDescription:withWindowTitle:)
										  withObject:([errorMessage length] ? errorMessage : primaryString)
										  withObject:([description length] ? description : ([secondaryString length] ? secondaryString : @"") )
										  withObject:titleString];
	
	return(adium_gaim_get_handle());
}

/* XXX ugly */
- (void *)handleNotifyFormattedWithTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary text:(const char *)text
{
	NSString *titleString = (title ? [NSString stringWithUTF8String:title] : nil);
	NSString *primaryString = (primary ? [NSString stringWithUTF8String:primary] : nil);
	
	if(!titleString){
		titleString = primaryString;
		primaryString = nil;
	}
	
	NSString *secondaryString = (secondary ? [NSString stringWithUTF8String:secondary] : nil);
	if(!primaryString){
		primaryString = secondaryString;
		secondaryString = nil;
	}
	
	static AIHTMLDecoder	*notifyFormattedHTMLDecoder = nil;
	if(!notifyFormattedHTMLDecoder) notifyFormattedHTMLDecoder = [[AIHTMLDecoder decoder] retain];

	NSString	*textString = (text ? [NSString stringWithUTF8String:text] : nil); 
	if(textString) textString = [[notifyFormattedHTMLDecoder decodeHTML:textString] string];
	
	NSString	*description = nil;
	if([textString length] && [secondaryString length]){
		description = [NSString stringWithFormat:@"%@\n\n%@",secondaryString,textString];
		
	}else if(textString){
		description = textString;
		
	}else if(secondaryString){
		description = secondaryString;
		
	}
	
	NSString	*message = primaryString;
	
	[[adium interfaceController] mainPerformSelector:@selector(handleMessage:withDescription:withWindowTitle:)
										  withObject:(message ? message : @"")
										  withObject:(description ? description : @"")
										  withObject:(titleString ? titleString : @"")];
}


#pragma mark File transfers
- (void)displayFileSendError
{
	[[adium interfaceController] mainPerformSelector:@selector(handleMessage:withDescription:withWindowTitle:)
										  withObject:AILocalizedString(@"File Send Error",nil)
										  withObject:AILocalizedString(@"An error was encoutered sending the file.  Please note that sending of folders is not currently supported; this includes Application bundles.",nil)
										  withObject:AILocalizedString(@"File Send Error",nil)];
}

#pragma mark Thread accessors
- (void)gaimThreadConnectAccount:(id)adiumAccount
{
	GaimAccount		*account = accountLookupFromAdiumAccount(adiumAccount); 
	GaimConnection	*gc;
	GaimDebug(@"Gaim thread: %@ lookup gave account %x",adiumAccount,account);
	gc = gaim_account_connect(account);
	GaimDebug(@"Gaim thread: gaim_account_connect(%x) gave %x [%x]",account,gc,account->gc);
}
- (void)connectAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadConnectAccount:adiumAccount];
}

- (void)gaimThreadDisconnectAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	
	if(gaim_account_is_connected(account)){
		gaim_account_disconnect(account);
	}
}
- (void)disconnectAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadDisconnectAccount:adiumAccount];
}

- (void)gaimThreadRegisterAccount:(id)adiumAccount
{
	gaim_account_register(accountLookupFromAdiumAccount(adiumAccount));
}
- (void)registerAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadRegisterAccount:adiumAccount];
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
			[gaimThreadProxy gaimThreadDoCommand:originalMessage
									 fromAccount:sourceAccount
										  inChat:chat];
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
	
- (oneway void)gaimThreadSendEncodedMessage:(NSString *)encodedMessage
							originalMessage:(NSString *)originalMessage
								fromAccount:(id)sourceAccount
									 inChat:(AIChat *)chat
								  withFlags:(int)flags
{	
	const char *encodedMessageUTF8String;
	
	if(encodedMessage && (encodedMessageUTF8String = [encodedMessage UTF8String])){
		GaimConversation	*conv = convLookupFromChat(chat,sourceAccount);

		switch (gaim_conversation_get_type(conv)) {				
			case GAIM_CONV_IM: {
				GaimConvIm			*im = gaim_conversation_get_im_data(conv);
				gaim_conv_im_send_with_flags(im, encodedMessageUTF8String, flags);
				break;
			}

			case GAIM_CONV_CHAT: {
				GaimConvChat	*gaimChat = gaim_conversation_get_chat_data(conv);
				gaim_conv_chat_send(gaimChat, encodedMessageUTF8String);
				break;
			}
		}
	}else{
		GaimDebug (@"*** Error encoding %@ to UTF8",encodedMessage);
	}
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
		[gaimThreadProxy gaimThreadSendEncodedMessage:encodedMessage
									  originalMessage:originalMessage
										  fromAccount:sourceAccount
											   inChat:chat
											withFlags:flags];
	}
	
	return(sendMessage);
}

- (oneway void)gaimThreadSendTyping:(AITypingState)typingState inChat:(AIChat *)chat
{
	GaimConversation *conv = convLookupFromChat(chat,nil);
	if (conv){
		//		BOOL isTyping = (([typingState intValue] == AINotTyping) ? FALSE : TRUE);

		GaimTypingState gaimTypingState;
		
		switch (typingState){
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
- (oneway void)sendTyping:(AITypingState)typingState inChat:(AIChat *)chat
{
	[gaimThreadProxy gaimThreadSendTyping:typingState
								   inChat:chat];
}

- (oneway void)gaimThreadAddUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	const char	*groupUTF8String, *buddyUTF8String;
	GaimGroup	*group;
	GaimBuddy	*buddy;
	
	//Find the group (Create if necessary)
	groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
	if(!(group = gaim_find_group(groupUTF8String))){
		group = gaim_group_new(groupUTF8String);
		gaim_blist_add_group(group, NULL);
	}
	
	//Find the buddy (Create if necessary)
	buddyUTF8String = [objectUID UTF8String];
	buddy = gaim_find_buddy(account, buddyUTF8String);
	if(!buddy) buddy = gaim_buddy_new(account, buddyUTF8String, NULL);

	GaimDebug (@"Adding buddy %s to group %s",buddy->name, group->name);

	/* gaim_blist_add_buddy() will move an existing contact serverside, but will not add a buddy serverside.
	 * We're working with a new contact, hopefully, so we want to call serv_add_buddy() after modifying the gaim list.
	 * This is the order done in add_buddy_cb() in gtkblist.c */
	gaim_blist_add_buddy(buddy, NULL, group, NULL);
	serv_add_buddy(gaim_account_get_connection(account), buddy);
}

- (oneway void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	[gaimThreadProxy gaimThreadAddUID:objectUID
							onAccount:adiumAccount
							  toGroup:groupName];
}

- (oneway void)gaimThreadRemoveUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	GaimBuddy 	*buddy;
	
	if (buddy = gaim_find_buddy(account, [objectUID UTF8String])){
		const char	*groupUTF8String;
		GaimGroup	*group;

		groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
		if (group = gaim_find_group(groupUTF8String)){
			/* Remove this contact from the server-side and gaim-side lists. 
			 * Updating gaimside does not change the server.
			 *
			 * Gaim has a commented XXX as to whether this order or the reverse (blist, then serv) is correct.
			 * We'll use the order which gaim uses as of gaim 1.1.4. */
			serv_remove_buddy(gaim_account_get_connection(account), buddy, group);
			gaim_blist_remove_buddy(buddy);
		}
	}
}

- (oneway void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName
{
	[gaimThreadProxy gaimThreadRemoveUID:objectUID
							   onAccount:adiumAccount
							   fromGroup:groupName];
}

- (oneway void)gaimThreadMoveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	GaimAccount *account;
	GaimGroup 	*group;
	GaimBuddy	*buddy;
	const char	*buddyUTF8String;
	const char	*groupUTF8String;
	BOOL		needToAddServerside = NO;

	account = accountLookupFromAdiumAccount(adiumAccount);

	//Get the destination group (creating if necessary)
	groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
	group = gaim_find_group(groupUTF8String);
	if(!group){
		/* If we can't find the group, something's gone wrong... we shouldn't be using a group we don't have.
		 * We'll just silently turn this into an add operation. */
		group = gaim_group_new(groupUTF8String);
		gaim_blist_add_group(group, NULL);
	}

	buddyUTF8String = [objectUID UTF8String];
	buddy = gaim_find_buddy(account, buddyUTF8String);
	if(!buddy){
		/* If we can't find a buddy, something's gone wrong... we shouldn't be moving a buddy we don't have.
 		 * As with the group, we'll just silently turn this into an add operation. */
		buddy = gaim_buddy_new(account, buddyUTF8String, NULL);
		needToAddServerside = YES;
	}

	/* gaim_blist_add_buddy() will update the local list and perform a serverside move as necessary */
	gaim_blist_add_buddy(buddy, NULL, group, NULL);

	/* gaim_blist_add_buddy() won't perform a serverside add, however.  Add if necessary. */
	if(needToAddServerside) serv_add_buddy(gaim_account_get_connection(account), buddy);
}
- (oneway void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	[gaimThreadProxy gaimThreadMoveUID:objectUID
							 onAccount:adiumAccount
							   toGroup:groupName];
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
- (oneway void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName
{	
	[gaimThreadProxy gaimThreadRenameGroup:oldGroupName
								 onAccount:adiumAccount
										to:newGroupName];
}

- (oneway void)gaimThreadDeleteGroup:(NSString *)groupName onAccount:(id)adiumAccount
{
	GaimGroup *group = gaim_find_group([groupName UTF8String]);
	
	if (group){
		gaim_blist_remove_group(group);
	}
}
- (oneway void)deleteGroup:(NSString *)groupName onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadDeleteGroup:groupName
								 onAccount:adiumAccount];
}

#pragma mark Alias
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
- (oneway void)setAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadSetAlias:alias
								 forUID:UID
							  onAccount:adiumAccount];
}

#pragma mark Chats
- (oneway void)gaimThreadOpenChat:(AIChat *)chat onAccount:(id)adiumAccount
{
	//Looking up the conv from the chat will create the GaimConversation gaimside, joining the chat, opening the server
	//connection, or whatever else is done when a chat is opened.
	convLookupFromChat(chat,adiumAccount);
}
- (oneway void)openChat:(AIChat *)chat onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadOpenChat:chat
							  onAccount:adiumAccount];
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
- (oneway void)closeChat:(AIChat *)chat
{
	//We look up the conv and the chat's uniqueChatID now since threading may make them change before
	//the gaimThread actually utilizes them
	[gaimThreadProxy gaimThreadCloseGaimConversation:[NSValue valueWithPointer:existingConvLookupFromChat(chat)]
										  withChatID:[chat uniqueChatID]];
}

- (oneway void)gaimThreadInviteContact:(AIListContact *)listContact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage
{
	GaimConversation	*conv;
	GaimAccount			*account;
	GaimConvChat		*gaimChat;
	AIAccount			*adiumAccount = [chat account];
	
	GaimDebug (@"#### gaimThreadInviteContact:%@ toChat:%@",[listContact UID],[chat name]);
	// dchoby98
	if(([adiumAccount isKindOfClass:[CBGaimAccount class]]) &&
	   (conv = convLookupFromChat(chat, adiumAccount)) &&
	   (account = accountLookupFromAdiumAccount((CBGaimAccount *)adiumAccount)) &&
	   (gaimChat = gaim_conversation_get_chat_data(conv))){

		//GaimBuddy		*buddy = gaim_find_buddy(account, [[listObject UID] UTF8String]);
		GaimDebug (@"#### gaimThreadAddChatUser chat: %@ (%@) buddy: %@",[chat name], chat,[listContact UID]);
		serv_chat_invite(gaim_conversation_get_gc(conv),
						 gaim_conv_chat_get_id(gaimChat),
						 (inviteMessage ? [inviteMessage UTF8String] : ""),
						 [[listContact UID] UTF8String]);
		
	}
}
- (oneway void)inviteContact:(AIListContact *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;
{
	[gaimThreadProxy gaimThreadInviteContact:contact
									  toChat:chat
								 withMessage:inviteMessage];
}

- (oneway void)gaimThreadCreateNewChat:(AIChat *)chat withListContact:(AIListContact *)contact
{
	//Create the chat
	convLookupFromChat(chat, [chat account]);
	
	//Invite the contact, with no message
	[self gaimThreadInviteContact:contact toChat:chat withMessage:nil];
}
- (void)createNewGroupChat:(AIChat *)chat withListContact:(AIListContact *)contact
{
	[gaimThreadProxy gaimThreadCreateNewChat:chat
							  withListContact:contact];
}

#pragma mark Account Status
- (oneway void)gaimThreadSetGaimStatusType:(const char *)gaimStatusType
							   withMessage:(NSString *)message
								 onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (gaim_account_is_connected(account)){
		
		serv_set_away(account->gc, gaimStatusType, [message UTF8String]);
	}
}

- (oneway void)setGaimStatusType:(const char *)gaimStatusType withMessage:(NSString *)message onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadSetGaimStatusType:gaimStatusType
									 withMessage:message
										 onAccount:adiumAccount];
}


//Set invisible. This will clear any other status.
- (oneway void)gaimThreadSetInvisible:(BOOL)isInvisible onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (gaim_account_is_connected(account)){
		serv_set_away(account->gc, (isInvisible ? "Invisible" : "Visible"), NULL);
	}	
}

- (oneway void)setInvisible:(BOOL)isInvisible onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadSetInvisible:isInvisible
								  onAccount:adiumAccount];
}

- (oneway void)gaimThreadSetInfo:(NSString *)profileHTML onAccount:(id)adiumAccount
{
	GaimAccount 	*account = accountLookupFromAdiumAccount(adiumAccount);
	const char *profileHTMLUTF8 = [profileHTML UTF8String];

	gaim_account_set_user_info(account, profileHTMLUTF8);

	if(account->gc != NULL && gaim_account_is_connected(account)) {
		serv_set_info(account->gc, profileHTMLUTF8);
	}
}
- (oneway void)setInfo:(NSString *)profileHTML onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadSetInfo:profileHTML
							 onAccount:adiumAccount];
}

- (oneway void)gaimThreadSetBuddyIcon:(NSString *)buddyImageFilename onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if(account){
		gaim_account_set_buddy_icon(account, [buddyImageFilename UTF8String]);
	}
}
- (oneway void)setBuddyIcon:(NSString *)buddyImageFilename onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadSetBuddyIcon:buddyImageFilename
								  onAccount:adiumAccount];
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
- (oneway void)setIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadSetIdleSinceTo:idleSince onAccount:adiumAccount];
}

#pragma mark Get Info
- (oneway void)gaimThreadGetInfoFor:(NSString *)inUID onAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (gaim_account_is_connected(account)){
		
		serv_get_info(account->gc, [inUID UTF8String]);
	}
}
- (oneway void)getInfoFor:(NSString *)inUID onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadGetInfoFor:inUID
								onAccount:adiumAccount];
}

#pragma mark Xfer
- (oneway void)gaimThreadXferRequest:(NSValue *)xferValue
{
	GaimXfer	*xfer = [xferValue pointerValue];
	gaim_xfer_request(xfer);
}
- (oneway void)xferRequest:(GaimXfer *)xfer
{
	[gaimThreadProxy gaimThreadXferRequest:[NSValue valueWithPointer:xfer]];
}

- (oneway void)gaimThreadXferRequestAccepted:(NSValue *)xferValue withFileName:(NSString *)xferFileName
{
	GaimXfer	*xfer = [xferValue pointerValue];
	gaim_xfer_choose_file_ok_cb(xfer, [xferFileName UTF8String]);
}
- (oneway void)xferRequestAccepted:(GaimXfer *)xfer withFileName:(NSString *)xferFileName
{
	[gaimThreadProxy gaimThreadXferRequestAccepted:[NSValue valueWithPointer:xfer]
									  withFileName:xferFileName];
}

- (oneway void)gaimThreadXferRequestRejected:(NSValue *)xferValue
{
	GaimXfer	*xfer = [xferValue pointerValue];
	gaim_xfer_request_denied(xfer);
}
- (oneway void)xferRequestRejected:(GaimXfer *)xfer
{
	[gaimThreadProxy gaimThreadXferRequestRejected:[NSValue valueWithPointer:xfer]];
}

- (oneway void)gaimThreadXferCancel:(NSValue *)xferValue
{
	GaimXfer	*xfer = [xferValue pointerValue];
	gaim_xfer_cancel_local(xfer);	
}
- (oneway void)xferCancel:(GaimXfer *)xfer
{
	[gaimThreadProxy gaimThreadXferCancel:[NSValue valueWithPointer:xfer]];
}

#pragma mark Account settings
- (oneway void)gaimThreadSetCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount
{
	GaimAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	BOOL		shouldCheckMail = [checkMail boolValue];

	gaim_account_set_check_mail(account, shouldCheckMail);
}
- (oneway void)setCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadSetCheckMail:checkMail
								 forAccount:adiumAccount];
}

#pragma mark Protocol specific accessors
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
- (oneway void)OSCAREditComment:(NSString *)comment forUID:(NSString *)inUID onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadOSCAREditComment:comment
										 forUID:inUID
									  onAccount:adiumAccount];
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
- (oneway void)OSCARSetFormatTo:(NSString *)inFormattedUID onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadOSCARSetFormatTo:inFormattedUID
									  onAccount:adiumAccount];
}

/*!
 * @brief Set the OSCAR available message
 *
 * @param availablePlaintext A plain text available message (not HTML)
 */
- (oneway void)gaimThreadOSCARSetAvailableMessageTo:(NSString *)availablePlaintext onAccount:(id)adiumAccount
{
	GaimAccount		*account;
	GaimConnection	*gc;
	OscarData		*od;

	if((account = accountLookupFromAdiumAccount(adiumAccount)) &&
	   (gc = gaim_account_get_connection(account)) &&
	   (od = gc->proto_data)){
	 	aim_locate_setprofile(od->sess, NULL, NULL, 0, NULL, "", 0);
		aim_srv_setavailmsg(od->sess, (char *)[availablePlaintext UTF8String]);
	}
}

//Only for OSCAR
- (oneway void)OSCARSetAvailableMessageTo:(NSString *)availablePlaintext onAccount:(id)adiumAccount
{
	[gaimThreadProxy gaimThreadOSCARSetAvailableMessageTo:availablePlaintext
												onAccount:adiumAccount];	
}

#pragma mark Request callbacks

- (oneway void)gaimThreadPerformContactMenuActionFromDict:(NSDictionary *)dict
{
	GaimBlistNodeAction *act = [[dict objectForKey:@"GaimBlistNodeAction"] pointerValue];
	GaimBuddy			*buddy = [[dict objectForKey:@"GaimBuddy"] pointerValue];

	//Perform act's callback with the desired buddy and data
	if(act->callback)
		act->callback((GaimBlistNode *)buddy, act->data);
}
- (oneway void)performContactMenuActionFromDict:(NSDictionary *)dict 
{
	[gaimThreadProxy gaimThreadPerformContactMenuActionFromDict:dict];
}


- (oneway void)gaimThreadPerformAccountMenuActionFromDict:(NSDictionary *)dict
{
	GaimPluginAction	*pam = [[dict objectForKey:@"GaimPluginAction"] pointerValue];

	if (pam->callback)
		pam->callback(pam);
}

- (oneway void)performAccountMenuActionFromDict:(NSDictionary *)dict
{
	[gaimThreadProxy gaimThreadPerformAccountMenuActionFromDict:dict];
}


#pragma mark Secure messaging
- (oneway void)gaimThreadRequestSecureMessaging:(BOOL)inSecureMessaging
										 inChat:(AIChat *)inChat
{
	GaimConversation	*conv;
	if(conv = convLookupFromChat(inChat, [inChat account])){
		
		if(inSecureMessaging){
			adium_gaim_otr_connect_conv(conv);
		}else{
			adium_gaim_otr_disconnect_conv(conv);	
		}
	}
}

- (oneway void)requestSecureMessaging:(BOOL)inSecureMessaging
							   inChat:(AIChat *)inChat
{
	[gaimThreadProxy gaimThreadRequestSecureMessaging:inSecureMessaging
											   inChat:inChat];
}

- (void)gaimConversation:(GaimConversation *)conv setSecurityDetails:(NSDictionary *)securityDetailsDict
{
	AIChat	*chat = (conv ? imChatLookupFromConv(conv) : nil);

	if(chat){
		NSMutableDictionary	*fullSecurityDetailsDict;
		
		if(securityDetailsDict){
			NSString				*format, *description;
			fullSecurityDetailsDict = [[securityDetailsDict mutableCopy] autorelease];
			
			/* Encrypted by Off-the-Record Messaging
				*
				* Fingerprint for TekJew:
				* <Fingerprint>
				*
				* Secure ID for this session:
				* Incoming: <Incoming SessionID>
				* Outgoing: <Outgoing SessionID>
				*/
			format = [@"%@\n\n" stringByAppendingString:AILocalizedString(@"Fingerprint for %@:","Fingerprint for <name>:")];
			format = [format stringByAppendingString:@"\n%@\n\n%@\n%@ %@\n%@ %@"];
			
			description = [NSString stringWithFormat:format,
				AILocalizedString(@"Encrypted by Off-the-Record Messaging",nil),
				[[chat listObject] formattedUID],
				[securityDetailsDict objectForKey:@"Fingerprint"],
				AILocalizedString(@"Secure ID for this session:",nil),
				AILocalizedString(@"Incoming:",nil),
				[securityDetailsDict objectForKey:@"Incoming SessionID"],
				AILocalizedString(@"Outgoing:",nil),
				[securityDetailsDict objectForKey:@"Outgoing SessionID"],
				nil];
			
			[fullSecurityDetailsDict setObject:description
										forKey:@"Description"];
		}else{
			fullSecurityDetailsDict = nil;	
		}
		
		[chat mainPerformSelector:@selector(setSecurityDetails:)
					   withObject:fullSecurityDetailsDict];
	}
}

- (void)refreshedSecurityOfGaimConversation:(GaimConversation *)conv
{
	GaimDebug (@"*** Refreshed security...");
}

- (NSString *)localizedOTRMessage:(NSString *)message withUsername:(const char *)username
{
	NSString	*localizedOTRMessage = nil;

	if(([message rangeOfString:@"You sent unencrypted data to"].location != NSNotFound) &&
	   ([message rangeOfString:@"who was expecting encrypted messages"].location != NSNotFound)){
		localizedOTRMessage = [NSString stringWithFormat:
			AILocalizedString(@"You sent an unencrypted message, but %s was expecting encryption.", "Message when sending unencrypted messages to a contact expecting encrypted ones. %s will be a name."),
			username];
	}else if([message rangeOfString:@"has closed his private connection to you"].location != NSNotFound){
		localizedOTRMessage = [NSString stringWithFormat:
			AILocalizedString(@"%s is no longer using encryption; you should cancel encryption on your side.", "Message when the remote contact cancels his half of an encrypted conversation. %s will be a name."),
			username];
	}

	return localizedOTRMessage;
}

- (void)dealloc
{
	gaim_signals_disconnect_by_handle(adium_gaim_get_handle());
	[super dealloc];
}


@end
