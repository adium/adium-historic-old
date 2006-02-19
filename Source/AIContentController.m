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

// $Id$

#import "AIAccountController.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "AdiumTyping.h"
#import "AdiumFormatting.h"
#import "AdiumMessageEvents.h"
#import "AdiumContentFiltering.h"
#import "AdiumOTREncryption.h"
#import "ESContactAlertsController.h"
#import "ESFileTransferController.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITextAttachmentAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/ESFileWrapperExtension.h>
#import <Adium/NDRunLoopMessenger.h>
#import <Adium/AITextAttachmentExtension.h>

@interface AIContentController (PRIVATE)
- (void)finishReceiveContentObject:(AIContentObject *)inObject;
- (void)finishSendContentObject:(AIContentObject *)inObject;
- (void)finishDisplayContentObject:(AIContentObject *)inObject;

- (BOOL)processAndSendContentObject:(AIContentObject *)inContentObject;
@end

/*
 * @class AIContentController
 * @brief Controller to manage incoming and outgoing content and chats.
 *
 * This controller handles default formatting and text entry filters, which can respond as text is entered in a message
 * window.  It the center for content filtering, including registering/unregistering of content filters.
 * It handles sending and receiving of content objects.  It manages chat observers, which are objects notified as
 * status objects are set and removed on AIChat objects.  It manages chats themselves, tracking open ones, closing
 * them when needed, etc.  Finally, it provides Events related to sending and receiving content, such as Message Received.
 */
@implementation AIContentController

/*
 * @brief Initialize the controller
 */
- (id)init
{
	if ((self = [super init])) {
		adiumTyping = [[AdiumTyping alloc] init];
		adiumFormatting = [[AdiumFormatting alloc] init];
		adiumContentFiltering = [[AdiumContentFiltering alloc] init];
		adiumMessageEvents = [[AdiumMessageEvents alloc] init];
		adiumOTREncryption = [[AdiumOTREncryption alloc] init];

		objectsBeingReceived = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (void)controllerDidLoad
{
	[adiumFormatting controllerDidLoad];
	[adiumMessageEvents controllerDidLoad];
	[adiumOTREncryption controllerDidLoad];
}

/*
 * @brief Close the controller
 */
- (void)controllerWillClose
{
	[adiumTyping release];
	[adiumFormatting release];
	[adiumContentFiltering release];
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[objectsBeingReceived release];

    [super dealloc];
}




#pragma mark Typing
- (void)userIsTypingContentForChat:(AIChat *)chat hasEnteredText:(BOOL)hasEnteredText {
	[adiumTyping userIsTypingContentForChat:chat hasEnteredText:hasEnteredText];
}

#pragma mark Formatting
- (NSDictionary *)defaultFormattingAttributes {
	return [adiumFormatting defaultFormattingAttributes];
}

#pragma mark Content Filtering
- (void)registerContentFilter:(id <AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction {
	[adiumContentFiltering registerContentFilter:inFilter ofType:type direction:direction];
}
- (void)registerDelayedContentFilter:(id <AIDelayedContentFilter>)inFilter
							  ofType:(AIFilterType)type
						   direction:(AIFilterDirection)direction {
	[adiumContentFiltering registerDelayedContentFilter:inFilter ofType:type direction:direction];
}
- (void)unregisterContentFilter:(id <AIContentFilter>)inFilter {
	[adiumContentFiltering unregisterContentFilter:inFilter];
}
- (void)registerFilterStringWhichRequiresPolling:(NSString *)inPollString {
	[adiumContentFiltering registerFilterStringWhichRequiresPolling:inPollString];
}
- (BOOL)shouldPollToUpdateString:(NSString *)inString {
	return [adiumContentFiltering shouldPollToUpdateString:inString];
}
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)attributedString
							   usingFilterType:(AIFilterType)type
									 direction:(AIFilterDirection)direction
									   context:(id)context {
	return [adiumContentFiltering filterAttributedString:attributedString
										 usingFilterType:type
											   direction:direction
												 context:context];
}
- (void)filterAttributedString:(NSAttributedString *)attributedString
			   usingFilterType:(AIFilterType)type
					 direction:(AIFilterDirection)direction
				 filterContext:(id)filterContext
			   notifyingTarget:(id)target
					  selector:(SEL)selector
					   context:(id)context {
	[adiumContentFiltering filterAttributedString:attributedString
								  usingFilterType:type
										direction:direction
									filterContext:filterContext
								  notifyingTarget:target
										 selector:selector
										  context:context];
}
- (void)delayedFilterDidFinish:(NSAttributedString *)attributedString uniqueID:(unsigned long long)uniqueID
{
	[adiumContentFiltering delayedFilterDidFinish:attributedString
										 uniqueID:uniqueID];
}

//Messaging ------------------------------------------------------------------------------------------------------------
#pragma mark Messaging
//Receiving step 1: Add an incoming content object - entry point
- (void)receiveContentObject:(AIContentObject *)inObject
{
	if (inObject) {
		AIChat			*chat = [inObject chat];

		//Only proceed if the contact is not ignored
		if (![chat isListContactIgnored:[inObject source]]) {
			//Notify: Will Receive Content
			if ([inObject trackContent]) {
				[[adium notificationCenter] postNotificationName:Content_WillReceiveContent
														  object:chat
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
			}

			//Run the object through our incoming content filters
			if ([inObject filterContent]) {
				//Track that we are in the process of receiving this object
				[objectsBeingReceived addObject:inObject];

				[self filterAttributedString:[inObject message]
							 usingFilterType:AIFilterContent
								   direction:AIFilterIncoming
							   filterContext:inObject
							 notifyingTarget:self
									selector:@selector(didFilterAttributedString:receivingContext:)
									 context:inObject];
				
			} else {
				[self finishReceiveContentObject:inObject];
			}
		}
    }
}

//Receiving step 2: filtering callback
- (void)didFilterAttributedString:(NSAttributedString *)filteredMessage receivingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredMessage];
	
	[self finishReceiveContentObject:inObject];
}

//Receiving step 3: Display the content
- (void)finishReceiveContentObject:(AIContentObject *)inObject
{
	//Display the content
	[self displayContentObject:inObject];
}

//Sending step 1: Entry point for any method in Adium which sends content
/*
 * @brief Send a content object
 *
 * Sending step 1: Public method to send a content object.
 *
 * This method checks to be sure that messages are sent by accounts in the order they are sent by the user;
 * this can only be problematic when a delayedFilter is involved, leading to the user sending more messages before
 * the first finished sending.
 */
- (BOOL)sendContentObject:(AIContentObject *)inObject
{
	//Only proceed if the chat allows it; if it doesn't, it will handle calling this method again when it is ready
	if ([[inObject chat] willBeginSendingContentObject:inObject]) {

		//Run the object through our outgoing content filters
		if ([inObject filterContent]) {
			//Track that we are in the process of send this object
			[objectsBeingReceived addObject:inObject];

			[self filterAttributedString:[inObject message]
						 usingFilterType:AIFilterContent
							   direction:AIFilterOutgoing
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:contentSendingContext:)
								 context:inObject];
			
		} else {
			[self finishSendContentObject:inObject];
		}
	}

	// XXX
	return YES;
}

//Sending step 2: Sending filter callback
-(void)didFilterAttributedString:(NSAttributedString *)filteredString contentSendingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];

	//Special outgoing content filter for AIM away message bouncing.  Used to filter %n,%t,...
	if ([inObject isKindOfClass:[AIContentMessage class]] && [(AIContentMessage *)inObject isAutoreply]) {
		[self filterAttributedString:[inObject message]
					 usingFilterType:AIFilterAutoReplyContent
						   direction:AIFilterOutgoing
					   filterContext:inObject
					 notifyingTarget:self
							selector:@selector(didFilterAttributedString:autoreplySendingContext:)
							 context:inObject];
	} else {		
		[self finishSendContentObject:inObject];
	}
}

//Sending step 3, applicable only when sending an autreply: Filter callback
-(void)didFilterAttributedString:(NSAttributedString *)filteredString autoreplySendingContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];

	[self finishSendContentObject:inObject];
}

//Sending step 4: Post notifications and ask the account to actually send the content.
- (void)finishSendContentObject:(AIContentObject *)inObject
{
    AIChat		*chat = [inObject chat];
	
	//Notify: Will Send Content
    if ([inObject trackContent]) {
        [[adium notificationCenter] postNotificationName:Content_WillSendContent
												  object:chat 
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inObject,@"Object",nil]];
    }
	
    //Send the object
	if ([inObject sendContent]) {
		if ([self processAndSendContentObject:inObject]) {
			if ([inObject displayContent]) {
				//Add the object
				[self displayContentObject:inObject];

			} else {
				//We are no longer in the process of receiving this object
				[objectsBeingReceived removeObject:inObject];
			}
			
			if ([inObject trackContent]) {
				//Did send content
				[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_SENT
												 forListObject:[chat listObject]
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:chat,@"AIChat",inObject,@"AIContentObject",nil]
								  previouslyPerformedActionIDs:nil];				
			}

		} else {
			//We are no longer in the process of receiving this object
			[objectsBeingReceived removeObject:inObject];
			
			NSString *message = [NSString stringWithFormat:AILocalizedString(@"Could not send from %@ to %@",nil),
				[[inObject source] formattedUID],[[inObject destination] formattedUID]];

			[self displayStatusMessage:message
								ofType:@"chat-error"
								inChat:chat];			
		}
	}
	
	//Let the chat know we finished sending
	[chat finishedSendingContentObject:inObject];
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters
{
	[self displayContentObject:inObject usingContentFilters:useContentFilters immediately:NO];
}

//Immediately YES means the main thread will halt until the content object is displayed;
//Immediately NO shuffles it off into the filtering thread, which will handle content sequentially but allows the main
//thread to continue operation.  
//This facility primarily exists for message history, which needs to put its display in before the first message;
//without this, the use of threaded filtering means that message history shows up after the first message.
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters immediately:(BOOL)immediately
{
	if (useContentFilters) {
		
		if (immediately) {
			//Filter in the main thread, set the message, and continue
			[inObject setMessage:[self filterAttributedString:[inObject message]
											  usingFilterType:AIFilterContent
													direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
													  context:inObject]];
			[self displayContentObject:inObject immediately:YES];
			
			
		} else {
			//Filter in the filter thread
			[self filterAttributedString:[inObject message]
						 usingFilterType:AIFilterContent
							   direction:([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming)
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:contentFilterDisplayContext:)
								 context:inObject];
		}
	} else {
		//Just continue
		[self displayContentObject:inObject immediately:immediately];
	}
}

- (void)didFilterAttributedString:(NSAttributedString *)filteredString contentFilterDisplayContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];
	
	//Continue
	[self displayContentObject:inObject immediately:NO];
}

//Display a content object
//Add content to the message view.  Doesn't do any sending or receiving, just adds the content.
- (void)displayContentObject:(AIContentObject *)inObject
{
	[self displayContentObject:inObject immediately:NO];
}

- (void)displayContentObject:(AIContentObject *)inObject immediately:(BOOL)immediately
{
    //Filter the content object
    if ([inObject filterContent]) {
		BOOL				message = ([inObject isKindOfClass:[AIContentMessage class]] && ![(AIContentMessage *)inObject isAutoreply]);
		AIFilterType		filterType = (message ? AIFilterMessageDisplay : AIFilterDisplay);
		AIFilterDirection	direction = ([inObject isOutgoing] ? AIFilterOutgoing : AIFilterIncoming);
		
		if (immediately) {
			
			//Set it after filtering in the main thread, then display it
			[inObject setMessage:[self filterAttributedString:[inObject message]
											  usingFilterType:filterType
													direction:direction
													  context:inObject]];
			[self finishDisplayContentObject:inObject];		
			
		} else {
			//Filter in the filtering thread
			[self filterAttributedString:[inObject message]
						 usingFilterType:filterType
							   direction:direction
						   filterContext:inObject
						 notifyingTarget:self
								selector:@selector(didFilterAttributedString:displayContext:)
								 context:inObject];
		}
		
    } else {
		[self finishDisplayContentObject:inObject];
	}

}

- (void)didFilterAttributedString:(NSAttributedString *)filteredString displayContext:(AIContentObject *)inObject
{
	[inObject setMessage:filteredString];
	
	[self finishDisplayContentObject:inObject];
}

- (void)finishDisplayContentObject:(AIContentObject *)inObject
{
    //Check if the object should display
    if ([inObject displayContent] && ([[inObject message] length] > 0)) {
		AIChat			*chat = [inObject chat];
		NSDictionary	*userInfo;
		BOOL			contentReceived, shouldPostContentReceivedEvents, chatIsOpen;

		//If the chat of the content object has been cleared, we can't do anything with it, so simply return
		if (!chat) return;
		
		chatIsOpen = [chat isOpen];
		contentReceived = (([inObject isMemberOfClass:[AIContentMessage class]]) &&
						   (![inObject isOutgoing]));
		shouldPostContentReceivedEvents = contentReceived && [inObject trackContent];
		
		if (!chatIsOpen) {
			/*
			 Tell the interface to open the chat
			 For incoming messages, we don't open the chat until we're sure that new content is being received.
			 */
			[[adium interfaceController] openChat:chat];
		}

		userInfo = [NSDictionary dictionaryWithObjectsAndKeys:chat, @"AIChat", inObject, @"AIContentObject", nil];

		//Notify: Content Object Added
		[[adium notificationCenter] postNotificationName:Content_ContentObjectAdded
												  object:chat
												userInfo:userInfo];		
		
		if (shouldPostContentReceivedEvents) {
			NSSet			*previouslyPerformedActionIDs = nil;
			AIListObject	*listObject = [chat listObject];
			
			if (!chatIsOpen) {
				//If the chat wasn't open before, generate CONTENT_MESSAGE_RECEIVED_FIRST
				previouslyPerformedActionIDs = [[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED_FIRST
																				forListObject:listObject
																					 userInfo:userInfo
																 previouslyPerformedActionIDs:nil];	
			}
			
			if (chat != [[adium interfaceController] activeChat]) {
				//If the chat is not currently active, generate CONTENT_MESSAGE_RECEIVED_BACKGROUND
				previouslyPerformedActionIDs = [[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED_BACKGROUND
																				forListObject:listObject
																					 userInfo:userInfo
																 previouslyPerformedActionIDs:previouslyPerformedActionIDs];
			}
			
			[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED
											 forListObject:listObject
												  userInfo:userInfo
							  previouslyPerformedActionIDs:previouslyPerformedActionIDs];
		}		
    }

	//We are no longer in the process of receiving this object
	[objectsBeingReceived removeObject:inObject];
}

#pragma mark -

/*
 * @brief Send any NSTextAttachments embedded in inContentMessage's message
 *
 * This method will remove such attachments after requesting their files being sent.
 *
 * If the account supports sending images on this message's chat and a file is an image it will be left in the
 * attributed string for processing later by AIHTMLDecoder.
 */
- (void)handleFileSendsForContentMessage:(AIContentMessage *)inContentMessage
{
	NSMutableAttributedString	*newAttributedString = nil;
	NSAttributedString			*attributedMessage = [inContentMessage message];
	unsigned					length = [attributedMessage length];

	if (length) {
		NSRange						searchRange = NSMakeRange(0,0);
		NSAttributedString			*currentAttributedString = attributedMessage;

		while (searchRange.location < length) {
			NSTextAttachment *textAttachment = [currentAttributedString attribute:NSAttachmentAttributeName
																		  atIndex:searchRange.location
																   effectiveRange:&searchRange];
			if (textAttachment) {
				BOOL shouldSendAttachmentAsFile;
				//Invariant within the loop, but most calls to handleFileSendsForContentMessage: don't get here at all
				BOOL canSendImages = [(AIAccount *)[inContentMessage source] canSendImagesForChat:[inContentMessage chat]];

				if ([textAttachment isKindOfClass:[AITextAttachmentExtension class]]) {
					AITextAttachmentExtension *textAttachmentExtension = (AITextAttachmentExtension *)textAttachment;
					
					/* Send if:
					 *		This attachment isn't just for display (i.e. isn't an emoticon) AND
					 *		This chat can't send images, or it can but this attachment isn't an image
					 */
					shouldSendAttachmentAsFile = (![textAttachmentExtension shouldAlwaysSendAsText] &&
												  (!canSendImages || ![textAttachmentExtension attachesAnImage]));
					
				} else {
					shouldSendAttachmentAsFile = (!canSendImages || ![textAttachment wrapsImage]);
				}

				if (shouldSendAttachmentAsFile) {
					if (!newAttributedString) {
						newAttributedString = [[attributedMessage mutableCopy] autorelease];
						currentAttributedString = newAttributedString;
					}
					
					NSString	*path;
					if ([textAttachment isKindOfClass:[AITextAttachmentExtension class]]) {
						path = [(AITextAttachmentExtension *)textAttachment path];
						
					} else {
						//Write out the file so we can send it if we have a standard NSTextAttachment to send
						NSFileWrapper *fileWrapper = [textAttachment fileWrapper];
					
						//Desired folder: /private/tmp/$UID/`uuidgen`
						NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
						NSString *filename = [fileWrapper preferredFilename];
						if (!filename) filename = [NSString randomStringOfLength:5];

						path = [tmpDir stringByAppendingPathComponent:filename];
					}

					[[adium fileTransferController] sendFile:path
											   toListContact:(AIListContact *)[inContentMessage destination]];

					//Now remove the attachment
					[newAttributedString removeAttribute:NSAttachmentAttributeName range:NSMakeRange(searchRange.location,
																									 searchRange.length)];
					[newAttributedString replaceCharactersInRange:searchRange withString:@""];
					//Decrease length by the number of characters we replaced
					length -= searchRange.length;
					
					//And don't increase our location in the searchRange.location += searchRange.length below
					searchRange.length = 0;
				}
			}
			
			//Onward and upward
			searchRange.location += searchRange.length;
		}
	}
	
	//If any  changes were made, update the AIContentMessage
	if (newAttributedString) {
		[inContentMessage setMessage:newAttributedString];
	}
}



- (BOOL)processAndSendContentObject:(AIContentObject *)inContentObject
{
	AIAccount	*sendingAccount = (AIAccount *)[inContentObject source];
	BOOL		success = YES;

	if ([inContentObject isKindOfClass:[AIContentTyping class]]) {
		/* Typing */
		success = [sendingAccount sendTypingObject:(AIContentTyping *)inContentObject];
	
	} else if ([inContentObject isKindOfClass:[AIContentMessage class]]) {
		/* Sending a message */
		AIContentMessage *contentMessage = (AIContentMessage *)inContentObject;
		NSString		 *encodedOutgoingMessage;

		//Before we send the message on to the account, we need to look for embedded files which should be sent as file transfers
		[self handleFileSendsForContentMessage:contentMessage];
		
		/* Let the account encode it as appropriate for sending. Note that we succeeded in sending if we have no length
		 * as that means that somewhere we meant to stop the send -- a file send, an encryption message, etc.
		 */
		if ([[contentMessage message] length]) {
			encodedOutgoingMessage = [sendingAccount encodedAttributedStringForSendingContentMessage:contentMessage];
			
			if (encodedOutgoingMessage && [encodedOutgoingMessage length]) {			
				[contentMessage setEncodedMessage:encodedOutgoingMessage];
				[adiumOTREncryption willSendContentMessage:contentMessage];
				
				if ([contentMessage encodedMessage]) {
					success = [sendingAccount sendMessageObject:contentMessage];
				}
			}
		}

	} else {
		/* Eating a tasty sandwich */
		success = NO;
	}

	return success;
}

/*
 * @brief Send a message as-specified without going through any filters or notifications
 */
- (void)sendRawMessage:(NSString *)inString toContact:(AIListContact *)inContact
{
	AIAccount		 *account = [inContact account];
	AIChat			 *chat;
	AIContentMessage *contentMessage;

	if (!(chat = [[adium chatController] existingChatWithContact:inContact])) {
		chat = [[adium chatController] chatWithContact:inContact];
	}

	contentMessage = [AIContentMessage messageInChat:chat
										  withSource:account
										 destination:inContact
												date:nil
											 message:nil
										   autoreply:NO];
	[contentMessage setEncodedMessage:inString];

	[account sendMessageObject:contentMessage];
}

/*
 * @brief Given an incoming message, decrypt it.  It is likely not yet ready for display when returned, as it may still include HTML.
 */
- (NSString *)decryptedIncomingMessage:(NSString *)inString fromContact:(AIListContact *)inListContact onAccount:(AIAccount *)inAccount
{
	return [adiumOTREncryption decryptIncomingMessage:inString fromContact:inListContact onAccount:inAccount];
}

/*
 * @brief Given an incoming message, decrypt it if necessary then convert it to an NSAttributedString, processing HTML if possible
 */
- (NSAttributedString *)decodedIncomingMessage:(NSString *)inString fromContact:(AIListContact *)inListContact onAccount:(AIAccount *)inAccount
{
	return [AIHTMLDecoder decodeHTML:[self decryptedIncomingMessage:inString
														fromContact:inListContact
														  onAccount:inAccount]];
}

#pragma mark OTR
- (void)requestSecureOTRMessaging:(BOOL)inSecureMessaging inChat:(AIChat *)inChat
{
	[adiumOTREncryption requestSecureOTRMessaging:inSecureMessaging inChat:inChat];
}

- (void)promptToVerifyEncryptionIdentityInChat:(AIChat *)inChat
{
	[adiumOTREncryption promptToVerifyEncryptionIdentityInChat:inChat];
}

#pragma mark -
/*
 * @brief Is the passed chat currently receiving content?
 *
 * Note: This may be irrelevent if threaded filtering is removed.
 */
- (BOOL)chatIsReceivingContent:(AIChat *)inChat
{
	BOOL isReceivingContent = NO;

	NSEnumerator	*objectsBeingReceivedEnumerator = [objectsBeingReceived objectEnumerator];
	AIContentObject	*contentObject;
	while ((contentObject = [objectsBeingReceivedEnumerator nextObject])) {
		if ([contentObject chat] == inChat) {
			isReceivingContent = YES;
			break;
		}
	}

	return isReceivingContent;
}

- (void)displayStatusMessage:(NSString *)message ofType:(NSString *)type inChat:(AIChat *)inChat
{
	AIContentStatus		*content;
	NSAttributedString	*attributedMessage;
	
	//Create our content object
	attributedMessage = [[NSAttributedString alloc] initWithString:message
														attributes:[self defaultFormattingAttributes]];
	content = [AIContentStatus statusInChat:inChat
								 withSource:[inChat listObject]
								destination:[inChat account]
									   date:[NSDate date]
									message:attributedMessage
								   withType:type];
	[attributedMessage release];

	//Add the object
	[self receiveContentObject:content];
}

//Returns YES if the account/chat is available for sending content
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact onAccount:(AIAccount *)inAccount 
{
	return [inAccount availableForSendingContentType:inType toContact:inContact];
}

/*! 
 * @brief Generate a menu of encryption preference choices
 */
- (NSMenu *)encryptionMenuNotifyingTarget:(id)target withDefault:(BOOL)withDefault
{
	NSMenu		*encryptionMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSMenuItem	*menuItem;

	[encryptionMenu setTitle:ENCRYPTION_MENU_TITLE];

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Disable chat encryption",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Never];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Encrypt chats as requested",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Manually];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Encrypt chats automatically",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Automatically];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Force encryption and refuse plaintext",nil)
										  target:target
										  action:@selector(selectedEncryptionPreference:)
								   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_RejectUnencryptedMessages];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	if (withDefault) {
		[encryptionMenu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Default",nil)
														  target:target
														  action:@selector(selectedEncryptionPreference:)
												   keyEquivalent:@""];
		
		[menuItem setTag:EncryptedChat_Default];
		[encryptionMenu addItem:menuItem];
		[menuItem release];
	}
	
	return [encryptionMenu autorelease];
}

@end
