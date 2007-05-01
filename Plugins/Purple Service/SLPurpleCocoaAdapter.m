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

#import "SLPurpleCocoaAdapter.h"

#import <Adium/AIAccountControllerProtocol.h>

#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import "CBPurpleAccount.h"
#import "CBPurpleServicePlugin.h"
#import "adiumPurpleCore.h"
#import "adiumPurpleEventloop.h"
#import "UndeclaredLibpurpleFunctions.h"
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AICorePluginLoader.h>
#import <Adium/AIService.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/NDRunLoopMessenger.h>

#import <CoreFoundation/CFRunLoop.h>
#import <CoreFoundation/CFSocket.h>
#include <Libpurple/libpurple.h>
#include <glib.h>
#include <stdlib.h>

#ifndef JOSCAR_SUPERCEDE_LIBGAIM
	#import "ESPurpleAIMAccount.h"
	#import "CBPurpleOscarAccount.h"
#endif

//Purple slash command interface
#include <Libpurple/cmds.h>

@interface SLPurpleCocoaAdapter (PRIVATE)
- (void)initLibPurple;
- (BOOL)attemptPurpleCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat;
- (void)refreshAutoreleasePool:(NSTimer *)inTimer;
@end

/*
 * A pointer to the single instance of this class active in the application.
 * The gaim callbacks need to be C functions with specific prototypes, so they
 * can't be ObjC methods. The ObjC callbacks do need to be ObjC methods. This
 * allows the C ones to call the ObjC ones.
 **/
static SLPurpleCocoaAdapter   *sharedInstance = nil;

//Dictionaries to track gaim<->adium interactions
NSMutableDictionary *accountDict = nil;
//NSMutableDictionary *contactDict = nil;
NSMutableDictionary *chatDict = nil;

//The autorelease pool presently in use; it will be periodically released and recreated
static NSAutoreleasePool *currentAutoreleasePool = nil;
#define	AUTORELEASE_POOL_REFRESH	5.0

static NSMutableArray	*libgaimPluginArray = nil;

@implementation SLPurpleCocoaAdapter

/*!
 * @brief Return the shared instance
 */
+ (SLPurpleCocoaAdapter *)sharedInstance
{	
	@synchronized(self) {
		if (!sharedInstance) {
			sharedInstance = [[self alloc] init];
		}
	}

	return sharedInstance;
}

/*!
 * @brief Plugin loaded
 *
 * Initialize each libgaim plugin.  These plugins should not do anything within libgaim itself; this should be done in
 * -[plugin initLibgaimPlugin].
 */
+ (void)pluginDidLoad
{
	NSEnumerator	*enumerator;
	NSString		*libgaimPluginPath;

	libgaimPluginArray = [[NSMutableArray alloc] init];
	
	enumerator = [[[AIObject sharedAdiumInstance] allResourcesForName:@"Plugins"
													   withExtensions:@"AdiumLibpurplePlugin"] objectEnumerator];
	while ((libgaimPluginPath = [enumerator nextObject])) {
		[AICorePluginLoader loadPluginAtPath:libgaimPluginPath
							  confirmLoading:YES
								 pluginArray:libgaimPluginArray];
	}
}

+ (NSArray *)libgaimPluginArray
{
	return libgaimPluginArray;
}

//Register the account gaimside in the gaim thread
- (void)addAdiumAccount:(CBPurpleAccount *)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	account->ui_data = [adiumAccount retain];
	
	purple_accounts_add(account);
	purple_account_set_status_list(account, "offline", YES, NULL);
}

//Remove an account gaimside
- (void)removeAdiumAccount:(CBPurpleAccount *)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);

	[(CBPurpleAccount *)account->ui_data release];
	account->ui_data = nil;
	
    purple_accounts_remove(account);	
}

#pragma mark Initialization
- (id)init
{
	if ((self = [super init])) {
		accountDict = [[NSMutableDictionary alloc] init];
		chatDict = [[NSMutableDictionary alloc] init];

		[self initLibPurple];		
	}
	
    return self;
}

/*!
 * @brief Empty and recreate the autorelease pool
 *
 * Our autoreleased objects will only be released when the outermost autorelease pool is released.
 * This is handled automatically in the main thread, but we need to do it manually here.
 */
- (void)refreshAutoreleasePool:(NSTimer *)inTimer
{
	[currentAutoreleasePool release];
	currentAutoreleasePool = [[NSAutoreleasePool alloc] init];
}

static void ZombieKiller_Signal(int i)
{
	int status;
	pid_t child_pid;

	while ((child_pid = waitpid(-1, &status, WNOHANG)) > 0);
}

- (void)networkDidChange:(NSNotification *)inNotification
{
	purple_signal_emit(purple_network_get_handle(), "network-configuration-changed", NULL);
}

- (void)initLibPurple
{	
	//Set the gaim user directory to be within this user's directory
	NSString	*gaimUserDir = [[[adium loginController] userDirectory] stringByAppendingPathComponent:@"libgaim"];
	purple_util_set_user_dir([[gaimUserDir stringByExpandingTildeInPath] UTF8String]);

	/* Delete blist.xml once when 1.0 runs to clear out any old silliness */
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Adium 1.0 deleted blist.xml"]) {
		[[NSFileManager defaultManager] removeFileAtPath:
			[[[NSString stringWithUTF8String:purple_user_dir()] stringByAppendingPathComponent:@"blist"] stringByAppendingPathExtension:@"xml"]
												 handler:nil];
		[[NSUserDefaults standardUserDefaults] setBool:YES
												forKey:@"Adium 1.0 deleted blist.xml"];
	}

	purple_core_set_ui_ops(adium_purple_core_get_ops());
	purple_eventloop_set_ui_ops(adium_purple_eventloop_get_ui_ops());

	//Initialize the libgaim core; this will call back on the function specified in our core UI ops for us to finish configuring libgaim
	if (!purple_core_init("Adium")) {
		NSLog(@"*** FATAL ***: Failed to initialize gaim core");
		PurpleDebug (@"*** FATAL ***: Failed to initialize gaim core");
	}
	
	//Libgaim's async DNS lookup tends to create zombies.
	{
		struct sigaction act;
		
		act.sa_handler = ZombieKiller_Signal;		
		//Send for terminated but not stopped children
		act.sa_flags = SA_NOCLDWAIT;

		sigaction(SIGCHLD, &act, NULL);
	}
	
	//Observe for network changes to tell libgaim about it
	[[adium notificationCenter] addObserver:self
								   selector:@selector(networkDidChange:)
									   name:AINetworkDidChangeNotification
									 object:nil];
}

#pragma mark Lookup functions

NSString* serviceClassForPurpleProtocolID(const char *protocolID)
{
	NSString	*serviceClass = nil;
	if (protocolID) {
		if (!strcmp(protocolID, "prpl-oscar"))
			serviceClass = @"AIM-compatible";
		else if (!strcmp(protocolID, "prpl-gg"))
			serviceClass = @"Gadu-Gadu";
		else if (!strcmp(protocolID, "prpl-jabber"))
			serviceClass = @"Jabber";
		else if (!strcmp(protocolID, "prpl-meanwhile"))
			serviceClass = @"Sametime";
		else if (!strcmp(protocolID, "prpl-msn"))
			serviceClass = @"MSN";
		else if (!strcmp(protocolID, "prpl-novell"))
			serviceClass = @"GroupWise";
		else if (!strcmp(protocolID, "prpl-yahoo"))
			serviceClass = @"Yahoo!";
		else if (!strcmp(protocolID, "prpl-zephyr"))
			serviceClass = @"Zephyr";
	}
	
	return serviceClass;
}

/*
 * Finds an instance of CBPurpleAccount for a pointer to a PurpleAccount struct.
 */
CBPurpleAccount* accountLookup(PurpleAccount *acct)
{
	CBPurpleAccount *adiumPurpleAccount = (acct ? (CBPurpleAccount *)acct->ui_data : nil);
	/* If the account doesn't have its ui_data associated yet (we haven't tried to connect) but we want this
	 * lookup data, we have to do some manual parsing.  This is used for example from the OTR preferences.
	 */
	if (!adiumPurpleAccount && acct) {
		const char	*protocolID = acct->protocol_id;
		NSString	*serviceClass = serviceClassForPurpleProtocolID(protocolID);

		NSEnumerator	*enumerator = [[[[AIObject sharedAdiumInstance] accountController] accounts] objectEnumerator];
		while ((adiumPurpleAccount = [enumerator nextObject])) {
			if ([adiumPurpleAccount isKindOfClass:[CBPurpleAccount class]] &&
			   [[[adiumPurpleAccount service] serviceClass] isEqualToString:serviceClass] &&
			   [[adiumPurpleAccount UID] caseInsensitiveCompare:[NSString stringWithUTF8String:acct->username]] == NSOrderedSame) {
				break;
			}
		}
	}
    return adiumPurpleAccount;
}

PurpleAccount* accountLookupFromAdiumAccount(CBPurpleAccount *adiumAccount)
{
	return [adiumAccount gaimAccount];
}

AIListContact* contactLookupFromBuddy(PurpleBuddy *buddy)
{
	//Get the node's ui_data
	AIListContact *theContact = (buddy ? (AIListContact *)buddy->node.ui_data : nil);

	//If the node does not have ui_data yet, we need to create a contact and associate it
	if (!theContact && buddy) {
		NSString	*UID;
	
		UID = [NSString stringWithUTF8String:purple_normalize(buddy->account, buddy->name)];
		
		theContact = [accountLookup(buddy->account) contactWithUID:UID];
		
		//Associate the handle with ui_data and the buddy with our statusDictionary
		buddy->node.ui_data = [theContact retain];
	}
	
	return theContact;
}

AIListContact* contactLookupFromIMConv(PurpleConversation *conv)
{
	return nil;
}

AIChat* groupChatLookupFromConv(PurpleConversation *conv)
{
	AIChat *chat;
	
	chat = (AIChat *)conv->ui_data;
	if (!chat) {
		NSString *name = [NSString stringWithUTF8String:conv->name];
		
		chat = [accountLookup(conv->account) chatWithName:name];

		[chatDict setObject:[NSValue valueWithPointer:conv] forKey:[chat uniqueChatID]];
		conv->ui_data = [chat retain];
		AILog(@"group chat lookup assigned %@ to %p",chat,conv);
	}

	return chat;
}

AIChat* existingChatLookupFromConv(PurpleConversation *conv)
{
	return (conv ? conv->ui_data : nil);
}

AIChat* chatLookupFromConv(PurpleConversation *conv)
{
	switch(purple_conversation_get_type(conv)) {
		case PURPLE_CONV_TYPE_CHAT:
			return groupChatLookupFromConv(conv);
			break;
		case PURPLE_CONV_TYPE_IM:
			return imChatLookupFromConv(conv);
			break;
		default:
			return existingChatLookupFromConv(conv);
			break;
	}
}

AIChat* imChatLookupFromConv(PurpleConversation *conv)
{
	AIChat			*chat;
	
	chat = (AIChat *)conv->ui_data;

	if (!chat) {
		//No chat is associated with the IM conversation
		AIListContact   *sourceContact;
		PurpleBuddy		*buddy;
		PurpleAccount		*account;
		
		account = conv->account;
//		PurpleDebug (@"%x conv->name %s; normalizes to %s",account,conv->name,purple_normalize(account,conv->name));

		//First, find the PurpleBuddy with whom we are conversing
		buddy = purple_find_buddy(account, conv->name);
		if (!buddy) {
			PurpleDebug (@"imChatLookupFromConv: Creating %s %s",account->username,purple_normalize(account,conv->name));
			//No purple_buddy corresponding to the conv->name is on our list, so create one
			buddy = purple_buddy_new(account, purple_normalize(account, conv->name), NULL);	//create a PurpleBuddy
		}

		NSCAssert(buddy != nil, @"buddy was nil");
		
		sourceContact = contactLookupFromBuddy(buddy);

		// Need to start a new chat, associating with the PurpleConversation
		chat = [accountLookup(account) chatWithContact:sourceContact];

		if (!chat) {
			NSString	*errorString;

			errorString = [NSString stringWithFormat:@"conv %x: Got nil chat in lookup for sourceContact %@ (%x ; \"%s\" ; \"%s\") on adiumAccount %@ (%x ; \"%s\")",
				conv,
				sourceContact,
				buddy,
				(buddy ? buddy->name : ""),
				((buddy && buddy->account && buddy->name) ? purple_normalize(buddy->account, buddy->name) : ""),
				accountLookup(account),
				account,
				(account ? account->username : "")];

			NSCAssert(chat != nil, errorString);
		}

		//Associate the PurpleConversation with the AIChat
		[chatDict setObject:[NSValue valueWithPointer:conv] forKey:[chat uniqueChatID]];
		conv->ui_data = [chat retain];
	}

	return chat;	
}

PurpleConversation* convLookupFromChat(AIChat *chat, id adiumAccount)
{
	PurpleConversation	*conv = [[chatDict objectForKey:[chat uniqueChatID]] pointerValue];
	PurpleAccount			*account = accountLookupFromAdiumAccount(adiumAccount);
	
	if (!conv && adiumAccount) {
		AIListObject *listObject = [chat listObject];
		
		//If we have a listObject, we are dealing with a one-on-one chat, so proceed accordingly
		if (listObject) {
			char *destination;
			
			destination = g_strdup(purple_normalize(account, [[listObject UID] UTF8String]));
			
			conv = purple_conversation_new(PURPLE_CONV_TYPE_IM, account, destination);
			
			//associate the AIChat with the gaim conv
			if (conv) imChatLookupFromConv(conv);

			g_free(destination);
			
		} else {
			//Otherwise, we have a multiuser chat.
			
			//All multiuser chats should have a non-nil name.
			NSString	*chatName = [chat name];
			if (chatName) {
				const char *name = [chatName UTF8String];
				
				/*
				 Look for an existing gaimChat.  If we find one, our job is complete.
				 
				 We will never find one if we are joining a chat on our own (via the Join Chat dialogue).
				 
				 We should never get to this point if we were invited to a chat, as groupChatLookupFromConv(),
				 which was called when we accepted the invitation and got the chat information from Purple,
				 will have associated the PurpleConversation with the chat and we would have stopped after
				 [[chatDict objectForKey:[chat uniqueChatID]] pointerValue] above.
				 
				 However, there's no reason not to check just in case.
				 */
				PurpleChat *gaimChat = purple_blist_find_chat(account, name);
				if (!gaimChat) {
					
					/*
					 If we don't have a PurpleChat with this name on this account, we need to create one.
					 Our chat, which should have been created via the Adium Join Chat API, should have
					 a ChatCreationInfo status object with the information we need to ask Purple to
					 perform the join.
					 */
					NSDictionary	*chatCreationInfo = [chat statusObjectForKey:@"ChatCreationInfo"];
					
					if (!chatCreationInfo) {
						AILog(@"*** No chat creation info for %@ on %@",chat,adiumAccount);
						return NULL;
					}
					
					PurpleDebug (@"Creating a chat.");

					GHashTable				*components;
					
					//Prpl Info
					PurpleConnection			*gc = purple_account_get_connection(account);
					GList					*list, *tmp;
					struct proto_chat_entry *pce;
					NSString				*identifier;
					NSEnumerator			*enumerator;
					
					//Create a hash table
					//The hash table should contain char* objects created via a g_strdup method
					components = g_hash_table_new_full(g_str_hash, g_str_equal,
													   g_free, g_free);
					
					enumerator = [chatCreationInfo keyEnumerator];
					while ((identifier = [enumerator nextObject])) {
						id		value = [chatCreationInfo objectForKey:identifier];
						char	*valueUTF8String = NULL;
						
						if ([value isKindOfClass:[NSNumber class]]) {
							valueUTF8String = g_strdup_printf("%d",[value intValue]);

						} else if ([value isKindOfClass:[NSString class]]) {
							valueUTF8String = g_strdup([value UTF8String]);

						} else {
							PurpleDebug (@"Invalid value %@ for identifier %@",value,identifier);
						}
						
						//Store our chatCreationInfo-supplied value in the compnents hash table
						if (valueUTF8String) {
							g_hash_table_replace(components,
												 g_strdup([identifier UTF8String]),
												 valueUTF8String);
						}
					}

					//In debug mode, verify we didn't miss any required values
					if (GAIM_DEBUG) {
						/*
						 Get the chat_info for our desired account.  This will be a GList of proto_chat_entry
						 objects, each of which has a label and identifier.  Each may also have is_int, with a minimum
						 and a maximum integer value.
						 */
						if ((PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl))->chat_info)
						{
							list = (PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl))->chat_info(gc);

							//Look at each proto_chat_entry in the list to verify we have it in chatCreationInfo
							for (tmp = list; tmp; tmp = tmp->next)
							{
								pce = tmp->data;
								char	*identifier = g_strdup(pce->identifier);
								
								NSString	*value = [chatCreationInfo objectForKey:[NSString stringWithUTF8String:identifier]];
								if (!value) {
									PurpleDebug (@"Danger, Will Robinson! %s is in the proto_info but can't be found in %@",identifier,chatCreationInfo);
								}
							}
						}
					}

					/*
					 //Add the PurpleChat to our local buddy list?
					gaimChat = purple_chat_new(account,
											 name,
											 components);
					if ((group = purple_find_group(group_name)) == NULL) {
						group = purple_group_new(group_name);
						purple_blist_add_group(group, NULL);
					}
					
					if (gaimChat != NULL) {
						purple_blist_add_chat(gaimChat, group, NULL);
					}
					*/

					//Join the chat serverside - the GHashTable components, couple with the originating PurpleConnect,
					//now contains all the information the prpl will need to process our request.
					PurpleDebug (@"In the event of an emergency, your GHashTable may be used as a flotation device...");
					serv_join_chat(gc, components);
				}
			}
		}
	}
	
	return conv;
}

PurpleConversation* existingConvLookupFromChat(AIChat *chat)
{
	return (PurpleConversation *)[[chatDict objectForKey:[chat uniqueChatID]] pointerValue];
}

void* adium_purple_get_handle(void)
{
	static int adium_purple_handle;
	
	return &adium_purple_handle;
}

NSMutableDictionary* get_chatDict(void)
{
	return chatDict;
}

#pragma mark Images

static NSString* _messageImageCachePath(int imageID, AIAccount* adiumAccount)
{
    NSString    *messageImageCacheFilename = [NSString stringWithFormat:@"TEMP-Image_%@_%i", [adiumAccount internalObjectID], imageID];
    return [[[[AIObject sharedAdiumInstance] cachesPath] stringByAppendingPathComponent:messageImageCacheFilename] stringByAppendingPathExtension:@"png"];
}

NSString* processPurpleImages(NSString* inString, AIAccount* adiumAccount)
{
	NSScanner			*scanner;
    NSString			*chunkString = nil;
    NSMutableString		*newString;
	NSString			*targetString = @"<IMG ID=";
	NSCharacterSet		*quoteApostropheCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\'"];
    int imageID;
	
	if ([inString rangeOfString:targetString options:NSCaseInsensitiveSearch].location == NSNotFound) {
		return inString;
	}
	
    //set up
	newString = [[NSMutableString alloc] init];
	
    scanner = [NSScanner scannerWithString:inString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	//A gaim image tag takes the form <IMG ID='12'></IMG> where 12 is the reference for use in PurpleStoredImage* purple_imgstore_get(int)
	
	//Parse the incoming HTML
    while (![scanner isAtEnd]) {
		
		//Find the beginning of a gaim IMG ID tag
		if ([scanner scanUpToString:targetString intoString:&chunkString]) {
			[newString appendString:chunkString];
		}
		
		if ([scanner scanString:targetString intoString:&chunkString]) {
			//Skip past a quote or apostrophe
			[scanner scanCharactersFromSet:quoteApostropheCharacterSet intoString:NULL];
			
			//Get the image ID from the tag
			[scanner scanInt:&imageID];

			//Skip past a quote or apostrophe
			[scanner scanCharactersFromSet:quoteApostropheCharacterSet intoString:NULL];

			//Scan past a >
			[scanner scanString:@">" intoString:nil];
			
			//Get the image, then write it out as a png
			PurpleStoredImage		*gaimImage = purple_imgstore_find_by_id(imageID);
			if (gaimImage) {
				NSString		*filename = (purple_imgstore_get_filename(gaimImage) ?
											 [NSString stringWithUTF8String:purple_imgstore_get_filename(gaimImage)] :
											 @"Image");
				NSString		*imagePath = _messageImageCachePath(imageID, adiumAccount);
				
				//First make an NSImage, then request a TIFFRepresentation to avoid an obscure bug in the PNG writing routines
				//Exception: PNG writer requires compacted components (bits/component * components/pixel = bits/pixel)
				NSImage				*image = [[NSImage alloc] initWithData:[NSData dataWithBytes:purple_imgstore_get_data(gaimImage)
																						  length:purple_imgstore_get_size(gaimImage)]];
				NSData				*imageTIFFData = [image TIFFRepresentation];
				NSBitmapImageRep	*bitmapRep = [NSBitmapImageRep imageRepWithData:imageTIFFData];
				
				//If writing the PNG file is successful, write an <IMG SRC="filepath"> tag to our string; the 'scaledToFitImage' class lets us apply CSS to directIM images only
				if ([[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToFile:imagePath atomically:YES]) {
					[newString appendString:[NSString stringWithFormat:@"<IMG CLASS=\"scaledToFitImage\" SRC=\"%@\" ALT=\"%@\">",
						imagePath, filename]];
				}
				
				[image release];
			} else {
				//If we didn't get a gaimImage, just leave the tag for now.. maybe it was important?
				[newString appendFormat:@"<IMG ID=\"%i\">",chunkString];
			}
		}
	}

	return ([newString autorelease]);
}

#pragma mark Notify
// Notify ----------------------------------------------------------------------------------------------------------
// We handle the notify messages within SLPurpleCocoaAdapter so we can use our localized string macro
- (void *)handleNotifyMessageOfType:(PurpleNotifyType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;
{
    NSString *primaryString = [NSString stringWithUTF8String:primary];
	NSString *secondaryString = secondary ? [NSString stringWithUTF8String:secondary] : nil;
	
	NSString *titleString;
	if (title) {
		titleString = [NSString stringWithFormat:AILocalizedString(@"Adium Notice: %@",nil),[NSString stringWithUTF8String:title]];
	} else {
		titleString = AILocalizedString(@"Adium : Notice", nil);
	}
	
	NSString *errorMessage = nil;
	NSString *description = nil;
	
	if (primaryString) {
		if (([primaryString rangeOfString:@"Already there"].location != NSNotFound) ||
			([primaryString rangeOfString:@"Group not removed"].location != NSNotFound)) {
			return adium_purple_get_handle();
		}
	}

	//Suppress notification warnings we have no interest in seeing
	if (secondaryString) {
		if (([secondaryString rangeOfString:@"Could not add the buddy 1 for an unknown reason"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Your screen name is currently formatted as follows"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Unable to format screen name"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Error reading from Switchboard server"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"0x001a: Unknown error"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Not supported by host"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Not logged in"].location != NSNotFound) ||
			([secondaryString rangeOfString:@"Your buddy list was downloaded from the server."].location != NSNotFound) || /* Gadu-gadu */
			([secondaryString rangeOfString:@"Your buddy list was stored on the server."].location != NSNotFound) /* Gadu-gadu */ ||
			([secondaryString rangeOfString:@"Your contact is using Windows Live"].location != NSNotFound) /* Yahoo without MSN support */) {
			return adium_purple_get_handle();
		}
	}

    if ([primaryString rangeOfString: @"Yahoo! message did not get sent."].location != NSNotFound) {
		//Yahoo send error
		errorMessage = AILocalizedString(@"Your Yahoo! message did not get sent.", nil);
		
	} else if ([primaryString rangeOfString: @"did not get sent"].location != NSNotFound) {
		//Oscar send error
		NSString *targetUserName = [[[[primaryString componentsSeparatedByString:@" message to "] objectAtIndex:1] componentsSeparatedByString:@" did not get "] objectAtIndex:0];
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"Your message to %@ did not get sent",nil),targetUserName];
		
		if ([secondaryString rangeOfString:@"Rate"].location != NSNotFound) {
			description = AILocalizedString(@"You are sending messages too quickly; wait a moment and try again.",nil);
		} else if ([secondaryString isEqualToString:@"Service unavailable"] || [secondaryString isEqualToString:@"Not logged in"]) {
			description = AILocalizedString(@"Connection error.",nil);
		} else if ([secondaryString isEqualToString:@"Refused by client"]) {
			description = AILocalizedString(@"Your message was refused by the other user.",nil);
		} else if ([secondaryString isEqualToString:@"Reply too big"]) {
			description = AILocalizedString(@"Your message was too big.",nil);
		} else if ([secondaryString isEqualToString:@"In local permit/deny"]) {
			description = AILocalizedString(@"The other user is in your deny list.",nil);
		} else if ([secondaryString rangeOfString:@"Too evil"].location != NSNotFound) {
			description = AILocalizedString(@"Warning level is too high.",nil);
		} else if ([secondaryString isEqualToString:@"User temporarily unavailable"]) {
			description = AILocalizedString(@"The other user is temporarily unavailable.",nil);
		} else {
			description = AILocalizedString(@"No reason was given.",nil);
		}
		
    } else if ([primaryString rangeOfString: @"Authorization Denied"].location != NSNotFound) {
		//Authorization denied; grab the user name and reason
		NSArray		*parts = [[[secondaryString componentsSeparatedByString:@" user "] objectAtIndex:1] componentsSeparatedByString:@" has denied your request to add them to your buddy list for the following reason:\n"];
		NSString	*targetUserName =  [parts objectAtIndex:0];
		NSString	*reason = ([parts count] > 1 ? [parts objectAtIndex:1] : AILocalizedString(@"(No reason given)",nil));
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ denied authorization:","User deined authorization; the next line has an explanation."),targetUserName];
		description = reason;

    } else if ([primaryString rangeOfString: @"Authorization Granted"].location != NSNotFound) {
		//ICQ Authorization granted
		NSString *targetUserName = [[[[secondaryString componentsSeparatedByString:@" user "] objectAtIndex:1] componentsSeparatedByString:@" has "] objectAtIndex:0];
		
		errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ granted authorization.",nil),targetUserName];
	}
	
	//If we didn't grab a translated version, at least display the English version Purple supplied
	[[adium interfaceController] handleMessage:([errorMessage length] ? errorMessage : primaryString)
							   withDescription:([description length] ? description : ([secondaryString length] ? secondaryString : @"") )
							   withWindowTitle:titleString];
	
	return NULL;
}

/* XXX ugly */
- (void *)handleNotifyFormattedWithTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary text:(const char *)text
{
	NSString *titleString = (title ? [NSString stringWithUTF8String:title] : nil);
	NSString *primaryString = (primary ? [NSString stringWithUTF8String:primary] : nil);
	
	if (!titleString) {
		titleString = primaryString;
		primaryString = nil;
	}
	
	NSString *secondaryString = (secondary ? [NSString stringWithUTF8String:secondary] : nil);
	if (!primaryString) {
		primaryString = secondaryString;
		secondaryString = nil;
	}
	
	static AIHTMLDecoder	*notifyFormattedHTMLDecoder = nil;
	if (!notifyFormattedHTMLDecoder) notifyFormattedHTMLDecoder = [[AIHTMLDecoder decoder] retain];

	NSString	*textString = (text ? [NSString stringWithUTF8String:text] : nil); 
	if (textString) textString = [[notifyFormattedHTMLDecoder decodeHTML:textString] string];
	
	NSString	*description = nil;
	if ([textString length] && [secondaryString length]) {
		description = [NSString stringWithFormat:@"%@\n\n%@",secondaryString,textString];
		
	} else if (textString) {
		description = textString;
		
	} else if (secondaryString) {
		description = secondaryString;
		
	}
	
	NSString	*message = primaryString;
	
	[[adium interfaceController] handleMessage:(message ? message : @"")
							   withDescription:(description ? description : @"")
							   withWindowTitle:(titleString ? titleString : @"")];

	return NULL;
}


#pragma mark File transfers
- (void)displayFileSendError
{
	[[adium interfaceController] handleMessage:AILocalizedString(@"File Send Error",nil)
							   withDescription:AILocalizedString(@"An error was encoutered sending the file.",nil)
							   withWindowTitle:AILocalizedString(@"File Send Error",nil)];
}

#pragma mark Thread accessors
- (void)disconnectAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	AILog(@"Setting %x disabled and offline (%s)...",account,
		  purple_status_type_get_id(purple_account_get_status_type_with_primitive(account, PURPLE_STATUS_OFFLINE)));

	purple_account_set_enabled(account, "Adium", NO);
}

- (void)registerAccount:(id)adiumAccount
{
	purple_account_register(accountLookupFromAdiumAccount(adiumAccount));
}

//Called on the gaim thread, actually performs the specified command (it should have already been tested by 
//attemptPurpleCommandOnMessage:... above.
- (BOOL)doCommand:(NSString *)originalMessage
			fromAccount:(id)sourceAccount
				 inChat:(AIChat *)chat
{
	PurpleConversation	*conv = convLookupFromChat(chat, sourceAccount);
	PurpleCmdStatus		status;
	char				*markup, *error;
	const char			*cmd;
	BOOL				didCommand = NO;

	cmd = [originalMessage UTF8String];
	
	//cmd+1 will be the cmd without the leading character, which should be "/"
	markup = g_markup_escape_text(cmd+1, -1);
	status = purple_cmd_do_command(conv, cmd+1, markup, &error);
	
	//The only error status which is possible now is either 
	switch (status) {
		case PURPLE_CMD_STATUS_FAILED:
		{
			purple_conv_present_error(conv->name, conv->account, "Command failed");
			didCommand = YES;
			break;
		}	
		case PURPLE_CMD_STATUS_WRONG_ARGS:
		{
			purple_conv_present_error(conv->name, conv->account, "Wrong number of arguments");
			didCommand = YES;			
			break;
		}
		case PURPLE_CMD_STATUS_OK:
			didCommand = YES;
			break;
		case PURPLE_CMD_STATUS_NOT_FOUND:
		case PURPLE_CMD_STATUS_WRONG_TYPE:
		case PURPLE_CMD_STATUS_WRONG_PRPL:
			/* Ignore this command and let the message send; the user probably doesn't even know what they typed is a command */
			didCommand = NO;
			break;
	}

	return didCommand;
}

/*!
 * @brief Check a message for gaim / commands=
 *
 * @result YES if a command was performed; NO if it was not
 */
- (BOOL)attemptPurpleCommandOnMessage:(NSString *)originalMessage fromAccount:(AIAccount *)sourceAccount inChat:(AIChat *)chat
{
	BOOL				didCommand = NO;
	
	if ([originalMessage hasPrefix:@"/"]) {	
		didCommand = [self doCommand:originalMessage
						 fromAccount:sourceAccount
							  inChat:chat];
	}

	return didCommand;
}

//Returns YES if the message was sent (and should therefore be displayed).  Returns NO if it was not sent or was otherwise used.
- (void)sendEncodedMessage:(NSString *)encodedMessage
			   fromAccount:(id)sourceAccount
					inChat:(AIChat *)chat
				 withFlags:(PurpleMessageFlags)flags
{	
	const char *encodedMessageUTF8String;
	
	if (encodedMessage && (encodedMessageUTF8String = [encodedMessage UTF8String])) {
		PurpleConversation	*conv = convLookupFromChat(chat,sourceAccount);

		switch (purple_conversation_get_type(conv)) {				
			case PURPLE_CONV_TYPE_IM: {
				PurpleConvIm			*im = purple_conversation_get_im_data(conv);
				purple_conv_im_send_with_flags(im, encodedMessageUTF8String, flags);
				break;
			}

			case PURPLE_CONV_TYPE_CHAT: {
				PurpleConvChat	*gaimChat = purple_conversation_get_chat_data(conv);
				purple_conv_chat_send(gaimChat, encodedMessageUTF8String);
				break;
			}
			
			case PURPLE_CONV_TYPE_ANY:
				PurpleDebug (@"What in the world? Got PURPLE_CONV_TYPE_ANY.");
				break;

			case PURPLE_CONV_TYPE_MISC:
			case PURPLE_CONV_TYPE_UNKNOWN:
				break;
		}
	} else {
		PurpleDebug (@"*** Error encoding %@ to UTF8",encodedMessage);
	}
}

- (void)sendTyping:(AITypingState)typingState inChat:(AIChat *)chat
{
	PurpleConversation *conv = convLookupFromChat(chat,nil);
	if (conv) {
		//		BOOL isTyping = (([typingState intValue] == AINotTyping) ? FALSE : TRUE);

		PurpleTypingState gaimTypingState;
		
		switch (typingState) {
			case AINotTyping:
			default:
				gaimTypingState = PURPLE_NOT_TYPING;
				break;
			case AITyping:
				gaimTypingState = PURPLE_TYPING;
				break;
			case AIEnteredText:
				gaimTypingState = PURPLE_TYPED;
				break;
		}
	
		serv_send_typing(purple_conversation_get_gc(conv),
						 purple_conversation_get_name(conv),
						 gaimTypingState);
	}	
}

- (void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	const char	*groupUTF8String, *buddyUTF8String;
	PurpleGroup	*group;
	PurpleBuddy	*buddy;
	
	//Find the group (Create if necessary)
	groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
	if (!(group = purple_find_group(groupUTF8String))) {
		group = purple_group_new(groupUTF8String);
		purple_blist_add_group(group, NULL);
	}
	
	//Find the buddy (Create if necessary)
	buddyUTF8String = [objectUID UTF8String];
	buddy = purple_find_buddy(account, buddyUTF8String);
	if (!buddy) buddy = purple_buddy_new(account, buddyUTF8String, NULL);

	PurpleDebug (@"Adding buddy %s to group %s",buddy->name, group->name);

	/* purple_blist_add_buddy() will move an existing contact serverside, but will not add a buddy serverside.
	 * We're working with a new contact, hopefully, so we want to call serv_add_buddy() after modifying the gaim list.
	 * This is the order done in add_buddy_cb() in gtkblist.c */
	purple_blist_add_buddy(buddy, NULL, group, NULL);
	purple_account_add_buddy(account, buddy);
}

- (void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	PurpleBuddy 	*buddy;
	
	if ((buddy = purple_find_buddy(account, [objectUID UTF8String]))) {
		const char	*groupUTF8String;
		PurpleGroup	*group;

		groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
		if ((group = purple_find_group(groupUTF8String))) {
			/* Remove this contact from the server-side and gaim-side lists. 
			 * Updating gaimside does not change the server.
			 *
			 * Purple has a commented XXX as to whether this order or the reverse (blist, then serv) is correct.
			 * We'll use the order which gaim uses as of gaim 1.1.4. */
			purple_account_remove_buddy(account, buddy, group);
			purple_blist_remove_buddy(buddy);
		}
	}
}

- (void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName
{
	PurpleAccount *account;
	PurpleBuddy	*buddy;
	PurpleGroup 	*group;
	const char	*buddyUTF8String;
	const char	*groupUTF8String;

	account = accountLookupFromAdiumAccount(adiumAccount);

	//Get the destination group (creating if necessary)
	groupUTF8String = (groupName ? [groupName UTF8String] : "Buddies");
	group = purple_find_group(groupUTF8String);
	if (!group) {
		/* If we can't find the group, something's gone wrong... we shouldn't be using a group we don't have.
		 * We'll just silently turn this into an add operation. */
		group = purple_group_new(groupUTF8String);
		purple_blist_add_group(group, NULL);
	}

	buddyUTF8String = [objectUID UTF8String];
	/* If we support contacts in multiple groups at once this should change */
	GSList *buddies = purple_find_buddies(account, buddyUTF8String);

	if (buddies) {
		GSList *cur;
		for (cur = buddies; cur; cur = cur->next) {
			/* purple_blist_add_buddy() will update the local list and perform a serverside move as necessary */
			purple_blist_add_buddy(cur->data, NULL, group, NULL);			
		}

	} else {
		/* If we can't find a buddy, something's gone wrong... we shouldn't be moving a buddy we don't have.
 		 * As with the group, we'll just silently turn this into an add operation. */
		buddy = purple_buddy_new(account, buddyUTF8String, NULL);

		/* purple_blist_add_buddy() will update the local list and perform a serverside move as necessary */
		purple_blist_add_buddy(buddy, NULL, group, NULL);
		
		/* purple_blist_add_buddy() won't perform a serverside add, however.  Add if necessary. */
		purple_account_add_buddy(account, buddy);
	}
}

- (void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName
{
    PurpleGroup *group = purple_find_group([oldGroupName UTF8String]);
	
	//If we don't have a group with this name, just ignore the rename request
    if (group) {
		//Rename gaimside, which will rename serverside as well
		purple_blist_rename_group(group, [newGroupName UTF8String]);
	}
}

- (void)deleteGroup:(NSString *)groupName onAccount:(id)adiumAccount
{
	PurpleGroup *group = purple_find_group([groupName UTF8String]);
	
	if (group) {
		purple_blist_remove_group(group);
	}
}

#pragma mark Alias
- (void)setAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (purple_account_is_connected(account)) {
		const char  *uidUTF8String = [UID UTF8String];
		PurpleBuddy   *buddy = purple_find_buddy(account, uidUTF8String);
		const char  *aliasUTF8String = [alias UTF8String];
		const char	*oldAlias = (buddy ? purple_buddy_get_alias(buddy) : nil);
	
		if (buddy && ((aliasUTF8String && !oldAlias) ||
					  (!aliasUTF8String && oldAlias) ||
					  ((oldAlias && aliasUTF8String && (strcmp(oldAlias,aliasUTF8String) != 0))))) {

			purple_blist_alias_buddy(buddy,aliasUTF8String);
			serv_alias_buddy(buddy);
			
			//If we had an alias before but no longer have, adiumPurpleBlistUpdate() is not going to send the update
			//(Because normally it's wasteful to send a nil alias to the account).  We need to manually invoke the update.
			if (oldAlias && !alias) {
				AIListContact *theContact = contactLookupFromBuddy(buddy);
				
				[adiumAccount updateContact:theContact
									toAlias:nil];
			}
		}
	}
}

#pragma mark Chats
- (void)openChat:(AIChat *)chat onAccount:(id)adiumAccount
{
	//Looking up the conv from the chat will create the PurpleConversation gaimside, joining the chat, opening the server
	//connection, or whatever else is done when a chat is opened.
	convLookupFromChat(chat,adiumAccount);
}

- (void)closeChat:(AIChat *)chat
{
	PurpleConversation *conv = existingConvLookupFromChat(chat);

	if (conv) {
		//We use chatDict's objectfor the passed chatUniqueID because we can no longer trust any other
		//values due to threading potentially letting them have changed on us.
		[chatDict removeObjectForKey:[chat uniqueChatID]];
			
		//We retained the chat when setting it as the ui_data; we are releasing here, so be sure to set conv->ui_data
		//to nil so we don't try to do it again.
		[(AIChat *)conv->ui_data release];
		conv->ui_data = nil;
		
		//Tell gaim to destroy the conversation.
		purple_conversation_destroy(conv);
	}	
}

- (void)inviteContact:(AIListContact *)listContact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;
{
	PurpleConversation	*conv;
	PurpleAccount			*account;
	PurpleConvChat		*gaimChat;
	AIAccount			*adiumAccount = [chat account];
	
	PurpleDebug (@"#### inviteContact:%@ toChat:%@",[listContact UID],[chat name]);
	// dchoby98
	if (([adiumAccount isKindOfClass:[CBPurpleAccount class]]) &&
	   (conv = convLookupFromChat(chat, adiumAccount)) &&
	   (account = accountLookupFromAdiumAccount((CBPurpleAccount *)adiumAccount)) &&
	   (gaimChat = purple_conversation_get_chat_data(conv))) {

		//PurpleBuddy		*buddy = purple_find_buddy(account, [[listObject UID] UTF8String]);
		PurpleDebug (@"#### addChatUser chat: %@ (%@) buddy: %@",[chat name], chat,[listContact UID]);
		serv_chat_invite(purple_conversation_get_gc(conv),
						 purple_conv_chat_get_id(gaimChat),
						 (inviteMessage ? [inviteMessage UTF8String] : ""),
						 [[listContact UID] UTF8String]);
		
	}
}

- (void)createNewGroupChat:(AIChat *)chat withListContact:(AIListContact *)contact
{
	//Create the chat
	convLookupFromChat(chat, [chat account]);
	
	//Invite the contact, with no message
	[self inviteContact:contact toChat:chat withMessage:nil];
}

#pragma mark Account Status
- (void)setStatusID:(const char *)statusID 
		   isActive:(NSNumber *)isActive
		  arguments:(NSMutableDictionary *)arguments
		  onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	GList		*attrs = NULL;

	//Generate a GList of attrs from arguments
	if ([arguments count]) {
		NSEnumerator	*enumerator;
		NSString		*key;
		
		enumerator = [arguments keyEnumerator];
		while ((key = [enumerator nextObject])) {
			const char *value = NULL;
			id	 valueObject;

			valueObject = [arguments objectForKey:key];
			
			if ([valueObject isKindOfClass:[NSNumber class]]) {
				value = GINT_TO_POINTER([valueObject intValue]);

			} else if ([valueObject isKindOfClass:[NSString class]]) {
				value = [valueObject UTF8String];
			}				
			
			if (value) {
				//Append the key
				attrs = g_list_append(attrs, (gpointer)[key UTF8String]);
				
				//Now append the value
				attrs = g_list_append(attrs, (gpointer)value);

			} else {
				AILog(@"Warning; could not determine value of %@ for key %@, statusID %s",valueObject,key,statusID);
			}
		}
	}

	AILog(@"Setting status on %x (%s): ID %s, isActive %i, attributes %@",account, purple_account_get_username(account),
		  statusID, [isActive boolValue], arguments);
	purple_account_set_status_list(account, statusID, [isActive boolValue], attrs);

	if (purple_status_is_online(purple_account_get_active_status(account)) &&
		purple_account_is_disconnected(account))  {
		//This status is an online status, but the account is not connected or connecting

		//Ensure the account is enabled
		if (!purple_account_get_enabled(account, "Adium")) {
			purple_account_set_enabled(account, "Adium", YES);
		}

		//Now connect the account
		purple_account_connect(account);
	}
	
}

- (void)setInfo:(NSString *)profileHTML onAccount:(id)adiumAccount
{
	PurpleAccount 	*account = accountLookupFromAdiumAccount(adiumAccount);
	const char *profileHTMLUTF8 = [profileHTML UTF8String];

	purple_account_set_user_info(account, profileHTMLUTF8);

	if (account->gc != NULL && purple_account_is_connected(account)) {
		serv_set_info(account->gc, profileHTMLUTF8);
	}
}

- (void)setBuddyIcon:(NSData *)buddyImageData onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (account) {
		purple_buddy_icons_set_account_icon(account, (guchar *)[buddyImageData bytes], [buddyImageData length]);
	}
}

- (void)setIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (purple_account_is_connected(account)) {
		NSTimeInterval idle = (idleSince != nil ? [idleSince timeIntervalSince1970] : 0);
		PurplePresence *presence;

		presence = purple_account_get_presence(account);

		purple_presence_set_idle(presence, (idle > 0), idle);
	}
}

#pragma mark Get Info
- (void)getInfoFor:(NSString *)inUID onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (purple_account_is_connected(account)) {
		
		serv_get_info(account->gc, [inUID UTF8String]);
	}
}

#pragma mark Xfer
- (void)xferRequest:(PurpleXfer *)xfer
{
	purple_xfer_request(xfer);
}

- (void)xferRequestAccepted:(PurpleXfer *)xfer withFileName:(NSString *)xferFileName
{
	//Only start the file transfer if it's still not marked as cancelled and therefore can be begun.
	if ((purple_xfer_get_status(xfer) != PURPLE_XFER_STATUS_CANCEL_LOCAL) &&
		(purple_xfer_get_status(xfer) != PURPLE_XFER_STATUS_CANCEL_REMOTE)) {
		//XXX should do further error checking as done by purple_xfer_choose_file_ok_cb() in gaim's ft.c
		purple_xfer_request_accepted(xfer, [xferFileName UTF8String]);
	}
}

- (void)xferRequestRejected:(PurpleXfer *)xfer
{
	purple_xfer_request_denied(xfer);
}

- (void)xferCancel:(PurpleXfer *)xfer
{
	if ((purple_xfer_get_status(xfer) == PURPLE_XFER_STATUS_UNKNOWN) ||
		(purple_xfer_get_status(xfer) == PURPLE_XFER_STATUS_NOT_STARTED) ||
		(purple_xfer_get_status(xfer) == PURPLE_XFER_STATUS_STARTED) ||
		(purple_xfer_get_status(xfer) == PURPLE_XFER_STATUS_ACCEPTED)) {
		purple_xfer_cancel_local(xfer);
	}
}

#pragma mark Account settings
- (void)setCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	BOOL		shouldCheckMail = [checkMail boolValue];

	purple_account_set_check_mail(account, shouldCheckMail);
}

- (void)setDefaultPermitDenyForAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);

	if (account && purple_account_get_connection(account)) {
		account->perm_deny = PURPLE_PRIVACY_DENY_USERS;
		serv_set_permit_deny(purple_account_get_connection(account));
	}	
}

#pragma mark Protocol specific accessors
#ifndef JOSCAR_SUPERCEDE_LIBGAIM
- (void)OSCAREditComment:(NSString *)comment forUID:(NSString *)inUID onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);
	if (purple_account_is_connected(account)) {
		PurpleBuddy   *buddy;
		PurpleGroup   *g;
		OscarData   *od;

		const char  *uidUTF8String = [inUID UTF8String];

		if ((buddy = purple_find_buddy(account, uidUTF8String)) &&
			(g = purple_buddy_get_group(buddy)) && 
			(od = account->gc->proto_data)) {
			aim_ssi_editcomment(od, g->name, uidUTF8String, [comment UTF8String]);	
		}
	}
}

- (void)OSCARSetFormatTo:(NSString *)inFormattedUID onAccount:(id)adiumAccount
{
	PurpleAccount *account = accountLookupFromAdiumAccount(adiumAccount);

	if (account &&
		purple_account_is_connected(account) &&
		[inFormattedUID length]) {
		
		oscar_reformat_screenname(purple_account_get_connection(account), [inFormattedUID UTF8String]);
	}
}
#endif

#pragma mark Request callbacks

- (void)performContactMenuActionFromDict:(NSDictionary *)dict forAccount:(id)adiumAccount
{
	PurpleBuddy		*buddy = [[dict objectForKey:@"PurpleBuddy"] pointerValue];
	void (*callback)(gpointer, gpointer);
	
	//Perform act's callback with the desired buddy and data
	callback = [[dict objectForKey:@"PurpleMenuActionCallback"] pointerValue];
	if (callback)
		callback((PurpleBlistNode *)buddy, [[dict objectForKey:@"PurpleMenuActionData"] pointerValue]);
}

- (void)performAccountMenuActionFromDict:(NSDictionary *)dict forAccount:(id)adiumAccount
{
	PurplePluginAction *act;
	PurpleAccount		 *account = accountLookupFromAdiumAccount(adiumAccount);

	if (account && account->gc) {
		act = purple_plugin_action_new(NULL, [[dict objectForKey:@"PurplePluginActionCallback"] pointerValue]);
		if (act->callback) {
			act->plugin = account->gc->prpl;
			act->context = account->gc;
			act->callback(act);
		}
		purple_plugin_action_free(act);
	}
}

/*!
* @brief Call the gaim callback to finish up the window
 *
 * @param inCallBackValue The cb to use
 * @param inUserDataValue Original user data
 */
- (void)doAuthRequestCbValue:(NSValue *)inCallBackValue withUserDataValue:(NSValue *)inUserDataValue 
{	
	PurpleAccountRequestAuthorizationCb callBack = [inCallBackValue pointerValue];
	if (callBack) {
		callBack([inUserDataValue pointerValue]);
	}
}

#pragma mark Secure messaging

- (void)gaimConversation:(PurpleConversation *)conv setSecurityDetails:(NSDictionary *)securityDetailsDict
{
}

- (void)refreshedSecurityOfPurpleConversation:(PurpleConversation *)conv
{
	PurpleDebug (@"*** Refreshed security...");
}

- (void)dealloc
{
	purple_signals_disconnect_by_handle(adium_purple_get_handle());

	[super dealloc];
}

/*
 //This doesn't work for several reasons.  The biggest: libgaim expects strings to be translated immediately;
 //substitutions have already occurred, as of concatenations, because we see them.
#pragma mark Translation

- (NSString *)localizedPurpleString:(NSString *)inString
{
	static BOOL configuredGettext = NO;
	if (!configuredGettext) {
		bindtextdomain("libgaim", [[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"potfiles"] UTF8String]);
		bind_textdomain_codeset("libgaim", "UTF-8");
		
		//Change language.
		NSString	*preferredLocalization = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
		setenv("LANGUAGE", [preferredLocalization UTF8String], 1);
		AILog(@"Purple translation using %s",[preferredLocalization UTF8String]);

		//Make change known. _nl_msg_cat_cntr is an external defined in gettext's loadmsgcat.c
		{
			extern int  _nl_msg_cat_cntr;
			++_nl_msg_cat_cntr;
		}
	}
	
	return [NSString stringWithUTF8String:dgettext("libgaim", [inString UTF8String])];
}
*/

@end
