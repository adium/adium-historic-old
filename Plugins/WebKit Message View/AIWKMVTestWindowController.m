//
//  AIWKMVTestWindowController.m
//  Adium
//
//  Created by David Smith on 10/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIWKMVTestWindowController.h"
#import "AIPreviewChat.h"
#import "AIWebKitMessageViewController.h"
#import "AIWebKitMessageViewStyle.h"
#import "AIWebKitMessageViewPlugin.h"
#import "ESWebFrameViewAdditions.h"
#import "ESWebKitMessageViewPreferences.h"
#import <Adium/AIAdiumProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIFileTransferControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentContext.h>
#import "AIHTMLDecoder.h"
#import <Adium/AIContentObject.h>
#import <Adium/AIContentEvent.h>
#import <Adium/AIEmoticon.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

#define WEBKIT_PREVIEW_CONVERSATION_FILE	@"Preview"

#define	PREF_GROUP_DISPLAYFORMAT			@"Display Format"  //To watch when the contact name display format changes

@implementation AIWKMVTestWindowController

- (void)windowDidLoad
{
	plugin = [[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"AIWebKitMessageViewPlugin"];
	[self _configureChatPreview];
}

- (IBAction) sendMessage:(id)sender
{
	NSDictionary *messageDict = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:NO], @"Autoreply"
										@"2004-04-19 12:46:07 -0500", @"Date",
										@"&lt;HTML&gt;&lt;BODY BGCOLOR=\"#FFFF00\"&gt;&lt;FONT FACE=\"Comic Sans MS\" SIZE=\"4\" COLOR=\"#FF0000\"&gt;I'm pretty sure I've heard this one before&lt;/FONT&gt;&lt;/BODY&gt;&lt;/HTML&gt;", @"Message",
										[NSNumber numberWithBool:NO], @"Outgoing",
										@"TekJew", @"To",
										@"Message", @"Type", nil];
	[self _addContent:[NSArray arrayWithObject:messageDict]
			   toChat:previewChat
	 withParticipants:list];
}

- (void)_configureChatPreview
{
	NSDictionary	*previewDict;
	NSString		*previewFilePath;
	NSString		*previewPath;
	
	//Create our fake chat and message controller for the live preview
	previewFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:WEBKIT_PREVIEW_CONVERSATION_FILE ofType:@"plist"];
	previewDict = [[NSDictionary alloc] initWithContentsOfFile:previewFilePath];
	previewPath = [previewFilePath stringByDeletingLastPathComponent];
	
	NSDictionary *listObjects;
	previewChat = [self previewChatWithDictionary:previewDict fromPath:previewPath listObjects:&listObjects];
	previewController = [[AIWebKitMessageViewController messageViewControllerForChat:previewChat
																		  withPlugin:plugin] retain];
	
	//Enable live refreshing of our preview
	[previewController setShouldReflectPreferenceChanges:YES];	
	[previewController setPreferencesChangedDelegate:self];
	
	//Add fake users and content to our chat
	[self _fillContentOfChat:previewChat withDictionary:previewDict fromPath:previewPath listObjects:listObjects];
	[previewDict release];
	
	//Place the preview chat in our view
	preview = [[previewController messageView] retain];
	[preview setFrame:[view_previewLocation frame]];
	//Will be released in viewWillClose
	[view_previewLocation retain];
	[[view_previewLocation superview] replaceSubview:view_previewLocation with:preview];
	
	//Disable drag and drop onto the preview chat - Jeff doesn't need your porn :)
	if ([preview respondsToSelector:@selector(setAllowsDragAndDrop:)]) {
		[(ESWebView *)preview setAllowsDragAndDrop:NO];
	}
	
	//Disable forwarding of events so the preferences responder chain works properly
	if ([preview respondsToSelector:@selector(setShouldForwardEvents:)]) {
		[(ESWebView *)preview setShouldForwardEvents:NO];		
	}	
}


- (AIChat *)previewChatWithDictionary:(NSDictionary *)previewDict fromPath:(NSString *)previewPath listObjects:(NSDictionary **)outListObjects
{
	previewChat = [AIChat chatForAccount:nil];
	[previewChat setDisplayName:AILocalizedString(@"Sample Conversation", "Title for the sample conversation")];
	
	//Process and create all participants
	*outListObjects = list = [[self _addParticipants:[previewDict objectForKey:@"Participants"]
											  toChat:previewChat fromPath:previewPath] retain];
	
	
	
	//Setup the chat, and its source/destination
	[self _applySettings:[previewDict objectForKey:@"Chat"]
				  toChat:previewChat withParticipants:*outListObjects];
	
	return previewChat;
}

/*!
* @brief Fill the content of the specified chat using content archived in the dictionary
 */
- (void)_fillContentOfChat:(AIChat *)inChat withDictionary:(NSDictionary *)previewDict fromPath:(NSString *)previewPath listObjects:(NSDictionary *)listObjects
{
	//Add the archived chat content
	[self _addContent:[previewDict objectForKey:@"Preview Messages"]
			   toChat:inChat withParticipants:listObjects];
}

/*!
* @brief Add participants
 */
- (NSMutableDictionary *)_addParticipants:(NSDictionary *)participants toChat:(AIChat *)inChat fromPath:(NSString *)previewPath
{
	NSMutableDictionary	*listObjectDict = [NSMutableDictionary dictionary];
	NSEnumerator		*enumerator = [participants objectEnumerator];
	NSDictionary		*participant;
	AIService			*aimService = [[adium accountController] firstServiceWithServiceID:@"AIM"];
	
	while ((participant = [enumerator nextObject])) {
		NSString		*UID, *alias, *userIconName;
		AIListContact	*listContact;
		
		//Create object
		UID = [participant objectForKey:@"UID"];
		listContact = [[AIListContact alloc] initWithUID:UID service:aimService];
		
		//Display name
		if ((alias = [participant objectForKey:@"Display Name"])) {
			[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
													  object:listContact
													userInfo:[NSDictionary dictionaryWithObject:alias forKey:@"Alias"]];
		}
		
		//User icon
		if ((userIconName = [participant objectForKey:@"UserIcon Name"])) {
			[listContact setStatusObject:[previewPath stringByAppendingPathComponent:userIconName]
								  forKey:@"UserIconPath"
								  notify:YES];
		}
		
		[listObjectDict setObject:listContact forKey:UID];
		[listContact release];
	}
	
	return listObjectDict;
}

/*!
* @brief Chat settings
 */
- (void)_applySettings:(NSDictionary *)chatDict toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants
{
	NSString			*dateOpened, *type, *name, *UID;
	
	//Date opened
	if ((dateOpened = [chatDict objectForKey:@"Date Opened"])) {
		[inChat setDateOpened:[NSDate dateWithNaturalLanguageString:dateOpened]];
	}
	
	//Source/Destination
	type = [chatDict objectForKey:@"Type"];
	if ([type isEqualToString:@"IM"]) {
		if ((UID = [chatDict objectForKey:@"Destination UID"])) {
			[inChat addParticipatingListObject:[participants objectForKey:UID]];
		}
		if ((UID = [chatDict objectForKey:@"Source UID"])) {
			[inChat setAccount:(AIAccount *)[participants objectForKey:UID]];
		}
	} else {
		if ((name = [chatDict objectForKey:@"Name"])) {
			[inChat setName:name];
		}
	}
	
	//We don't want the interface controller to try to open this fake chat
	[inChat setIsOpen:YES];
}

/*!
* @brief Chat content
 */
- (void)_addContent:(NSArray *)chatArray toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants
{
	NSEnumerator		*enumerator;
	NSDictionary		*messageDict;
	
	enumerator = [chatArray objectEnumerator];
	while ((messageDict = [enumerator nextObject])) {
		AIContentObject		*content = nil;
		AIListObject		*source;
		NSString			*from, *msgType;
		NSAttributedString  *message;
		
		msgType = [messageDict objectForKey:@"Type"];
		from = [messageDict objectForKey:@"From"];
		
		source = (from ? [participants objectForKey:from] : nil);
		
		if ([msgType isEqualToString:CONTENT_MESSAGE_TYPE]) {
			//Create message content object
			AIListObject		*dest;
			NSString			*to;
			BOOL				outgoing;
			
			message = [AIHTMLDecoder decodeHTML:[messageDict objectForKey:@"Message"]];
			to = [messageDict objectForKey:@"To"];
			outgoing = [[messageDict objectForKey:@"Outgoing"] boolValue];
			
			//The other person is always the one we're chatting with right now
			dest = [participants objectForKey:to];
			content = [AIContentMessage messageInChat:inChat
										   withSource:source
										  destination:dest
												 date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
											  message:message
											autoreply:[[messageDict objectForKey:@"Autoreply"] boolValue]];
			
			//AIContentMessage won't know whether the message is outgoing unless we tell it since neither our source
			//nor our destination are AIAccount objects.
			[content _setIsOutgoing:outgoing];
			
		} else if ([msgType isEqualToString:CONTENT_STATUS_TYPE]) {
			//Create status content object
			NSString			*statusMessageType;
			
			message = [AIHTMLDecoder decodeHTML:[messageDict objectForKey:@"Message"]];
			statusMessageType = [messageDict objectForKey:@"Status Message Type"];
			
			//Create our content object
			content = [AIContentStatus statusInChat:inChat
										 withSource:source
										destination:nil
											   date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
											message:message
										   withType:statusMessageType];
		}
		
		if (content) {			
			[content setTrackContent:NO];
			[content setPostProcessContent:NO];
			[content setDisplayContentImmediately:NO];
			
			[[adium contentController] displayContentObject:content];
		}
	}
	
	//We finished adding untracked content
	[[adium notificationCenter] postNotificationName:Content_ChatDidFinishAddingUntrackedContent
											  object:inChat];
}

@end
