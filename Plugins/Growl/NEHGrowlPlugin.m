//
//  NEHGrowlPlugin.m
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "NEHGrowlPlugin.h"
#import <Growl-WithInstaller/Growl.h>

#define PREF_GROUP_EVENT_BEZEL              @"Event Bezel"
#define KEY_EVENT_BEZEL_SHOW_AWAY           AILocalizedString(@"Show While Away",nil)
#define GROWL_ALERT							AILocalizedString(@"Display Growl Notification",nil)

#define GROWL_DEBUG TRUE
 
#define GROWL_INSTALLATION_WINDOW_TITLE AILocalizedString(@"Growl Installation Recommended", "Growl installation window title")
#define GROWL_UPDATE_WINDOW_TITLE AILocalizedString(@"Growl Update Available", "Growl update window title")

#define GROWL_INSTALLATION_EXPLANATION AILocalizedString(@"Adium can display contact status changes, incoming messages, and more via Growl, a centralized notification system.  Growl is not currently installed; to see Growl notifications from Adium and other applications, you must install it.  No download is required.","Growl installation explanation")
#define GROWL_UPDATE_EXPLANATION AILocalizedString(@"Adium can display contact status changes, incoming messages, and more via Growl, a centralized notification system.  A version of Growl is currently installed, but this release of Adium includes an updated version of Growl.  It is strongly recommended that you update now.  No download is required.","Growl update explanation")

#define GROWL_TEXT_SIZE 11

@interface NEHGrowlPlugin (PRIVATE)
- (NSDictionary *)growlRegistrationDict;
- (NSAttributedString *)_growlInformationForUpdate:(BOOL)isUpdate;
@end

@implementation NEHGrowlPlugin

- (void)installPlugin
{
	//Wait for Adium to finish launching before we perform further actions so all events are registered
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];	
}

- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[super dealloc];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//Now delay one more run loop so any events which are registered on this notification are guaranteed to be complete
	//regardless of the order in which the observers are called
	[self performSelector:@selector(beginGrowling)
			   withObject:nil
			   afterDelay:0.00001];

	[[adium notificationCenter] removeObserver:self
										  name:Adium_CompletedApplicationLoad
										object:nil];
}

- (void)beginGrowling
{
	[GrowlAppBridge setGrowlDelegate:self];

	//Install our contact alert
	[[adium contactAlertsController] registerActionID:@"Growl" withHandler:self];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EVENT_BEZEL];	
	
#ifdef GROWL_DEBUG
	[GrowlAppBridge notifyWithTitle:@"We have found a witch."
						description:@"May we burn her?"
				   notificationName:CONTENT_MESSAGE_RECEIVED
						   iconData:nil
						   priority:0
						   isSticky:YES
					   clickContext:[NSDictionary dictionaryWithObjectsAndKeys:
						   @"AIM.tekjew", @"internalObjectID",
						   CONTENT_MESSAGE_RECEIVED, @"eventID",
						   nil]];
#endif
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	showWhileAway = [[prefDict objectForKey:KEY_EVENT_BEZEL_SHOW_AWAY] boolValue];
}

#pragma mark AIActionHandler

- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(GROWL_ALERT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return(GROWL_ALERT);
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"GrowlAlert" forClass:[self class]]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
#warning bleh
	if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] && ! showWhileAway)
		return;
	
	NSString			*title, *description;
	NSDictionary		*clickContext = nil;
	NSData				*iconData = nil;
	
	BOOL isMessageEvent = ([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED] ||
						   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST] ||
						   [eventID isEqualToString:CONTENT_MESSAGE_SENT]);
	
	if(listObject){
		if([listObject isKindOfClass:[AIListContact class]]){
			title = [listObject longDisplayName];
		}else{
			title = [listObject formattedUID];
		}
		
		iconData = [listObject userIconData];
		
		if (!iconData) {
			iconData = [[AIServiceIcons serviceIconForObject:listObject
														type:AIServiceIconLarge
												   direction:AIIconNormal] TIFFRepresentation];
		}
		
		//If it is a message event for a list object, we can just use the list object's internalObjectID
		//as the uniqueChatID for quick look up if the bubble is clicked.
		if(isMessageEvent){
			clickContext = [NSDictionary dictionaryWithObjectsAndKeys:
				[listObject internalObjectID], @"uniqueChatID",
				eventID, @"eventID",
				nil];
			
		}else{
			clickContext = [NSDictionary dictionaryWithObjectsAndKeys:
				[listObject internalObjectID], @"internalObjectID",
				eventID, @"eventID",
				nil];
		}

	}else{
		if(isMessageEvent){
			AIChat	*chat = [userInfo objectForKey:@"AIChat"];
			title = [chat name];

			clickContext = [NSDictionary dictionaryWithObjectsAndKeys:
				[chat uniqueChatID], @"uniqueChatID",
				eventID, @"eventID",
				nil];
		}else{
			title = @"Adium";
		}
	}
	
	description = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:eventID
																			 listObject:listObject
																			   userInfo:userInfo
																		 includeSubject:NO];

	[GrowlAppBridge notifyWithTitle:title
						description:description
				   notificationName:eventID /* Use the same ID as Adium uses to keep things simple */
						   iconData:iconData
						   priority:0
						   isSticky:NO
					   clickContext:clickContext];
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
    return nil;
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

#pragma mark Growl

- (NSString *)growlAppName
{
	return @"Adium";
}

- (NSDictionary *)growlRegistrationDict
{
	//Register us with Growl
	NSArray *allNotes = [[adium contactAlertsController] allEventIDs];
	
	NSDictionary * growlReg = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Adium", GROWL_APP_NAME,
		allNotes, GROWL_NOTIFICATIONS_ALL,
		allNotes, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	
	return(growlReg);
}

- (void)growlIsReady
{
#ifdef GROWL_DEBUG
	AILog(@"Growl is go for launch.");
#endif
}

- (void)growlNotificationWasClicked:(NSDictionary *)clickContext
{
	NSString		*internalObjectID, *uniqueChatID;
	AIListObject	*listObject;
	AIChat			*chat;
		
	if(internalObjectID = [clickContext objectForKey:@"internalObjectID"]){
		
		if ((listObject = [[adium contactController] existingListObjectWithUniqueID:internalObjectID]) &&
			([listObject isKindOfClass:[AIListContact class]])){
			
			//First look for an existing chat to avoid changing anything
			if(!(chat = [[adium contentController] existingChatWithContact:(AIListContact *)listObject])){
				//If we don't find one, create one
				chat = [[adium contentController] openChatWithContact:(AIListContact *)listObject];
			}
		}
	}else if(uniqueChatID = [clickContext objectForKey:@"uniqueChatID"]){
		chat = [[adium contentController] existingChatWithUniqueChatID:uniqueChatID];
		
		//If we didn't find a chat, it may have closed since the notification was posted.
		//If we have an appropriate existing list object, we can create a new chat.
		if ((!chat) &&
			(listObject = [[adium contactController] existingListObjectWithUniqueID:uniqueChatID]) &&
			([listObject isKindOfClass:[AIListContact class]])){
		
			//If the uniqueChatID led us to an existing contact, create a chat with it
			chat = [[adium contentController] openChatWithContact:(AIListContact *)listObject];
		}	
	}

	if(chat){
		//Make the chat active
		[[adium interfaceController] setActiveChat:chat];
		
		//And make Adium active (needed if, for example, our notification was clicked with another app active)
		[NSApp activateIgnoringOtherApps:YES];
	}
	
	NSLog(@"%@ was clicked",clickContext);
}

- (NSString *)growlInstallationWindowTitle
{
	return GROWL_INSTALLATION_WINDOW_TITLE;	
}

- (NSString *)growlUpdateWindowTitle
{
	return GROWL_UPDATE_WINDOW_TITLE;
}

- (NSAttributedString *)growlInstallationInformation
{
	return [self _growlInformationForUpdate:NO];
}

- (NSAttributedString *)growlUpdateInformation
{
	return [self _growlInformationForUpdate:YES];
}

- (NSAttributedString *)_growlInformationForUpdate:(BOOL)isUpdate
{
	NSMutableAttributedString	*growlInfo;
	
	//Start with the window title, centered and bold
	NSMutableParagraphStyle	*centeredStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[centeredStyle setAlignment:NSCenterTextAlignment];
	
	growlInfo = [[NSMutableAttributedString alloc] initWithString:(isUpdate ? GROWL_UPDATE_WINDOW_TITLE : GROWL_INSTALLATION_WINDOW_TITLE)
													   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
														   centeredStyle,NSParagraphStyleAttributeName,
														   [NSFont boldSystemFontOfSize:GROWL_TEXT_SIZE], NSFontAttributeName,
														   nil]];
	//Skip a line
	[[growlInfo mutableString] appendString:@"\n\n"];
	
	//Now provide a default explanation
	NSAttributedString *defaultExplanation;
	defaultExplanation = [[[NSAttributedString alloc] initWithString:(isUpdate ? GROWL_UPDATE_EXPLANATION : GROWL_INSTALLATION_EXPLANATION)
														  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
															  [NSFont systemFontOfSize:GROWL_TEXT_SIZE], NSFontAttributeName,
															  nil]] autorelease];
	
	[growlInfo appendAttributedString:defaultExplanation];
	
	return growlInfo;
}

@end
