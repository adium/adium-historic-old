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

#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIPreferenceController.h"
#import "ESContactAlertsController.h"
#import "ESContactAlertsController.h"
#import "NEHGrowlPlugin.h"
#import "CBGrowlAlertDetailPane.h"
#import <AIUtilities/CBApplicationAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>
#import <Growl-WithInstaller/Growl.h>

//#define GROWL_DEBUG 1

#define PREF_GROUP_EVENT_BEZEL              @"Event Bezel"
#define KEY_EVENT_BEZEL_SHOW_AWAY           @"Show While Away"
#define GROWL_ALERT							AILocalizedString(@"Display a Growl notification",nil)
#define GROWL_STICKY_ALERT					AILocalizedString(@"Display a sticky Growl notification",nil)

#define GROWL_INSTALLATION_WINDOW_TITLE AILocalizedString(@"Growl Installation Recommended", "Growl installation window title")
#define GROWL_UPDATE_WINDOW_TITLE AILocalizedString(@"Growl Update Available", "Growl update window title")

#define GROWL_INSTALLATION_EXPLANATION AILocalizedString(@"Adium uses the Growl notification system to provide a configurable interface to display status changes, incoming messages and more.\n\nIt is strongly recommended that you allow Adium to automatically install Growl; no download is required.","Growl installation explanation")
#define GROWL_UPDATE_EXPLANATION AILocalizedString(@"Adium uses the Growl notification system to provide a configurable interface to display status changes, incoming messages and more.\n\nThis release of Adium includes an updated version of Growl. It is strongly recommended that you allow Adium to automatically update Growl; no download is required.","Growl update explanation")

#define GROWL_TEXT_SIZE 11

#define GROWL_EVENT_ALERT_IDENTIFIER			@"Growl"

@interface NEHGrowlPlugin (PRIVATE)
- (NSDictionary *)growlRegistrationDict;
- (NSAttributedString *)_growlInformationForUpdate:(BOOL)isUpdate;
@end

/*
 * @class NEHGrowlPlugin
 * @brief Implements Growl functionality in Adium
 *
 * This class manages the Growl event type, and controls the display of Growl notifications that Adium generates.
 */
@implementation NEHGrowlPlugin

/*
 * @brief Initialize the Growl plugin
 *
 * Waits for Adium to finish launching before we perform further actions so all events are registered.
 */
- (void)installPlugin
{
	//Growl only works in 10.3 and later
	if([NSApp isOnPantherOrBetter]){
		[[adium notificationCenter] addObserver:self
									   selector:@selector(adiumFinishedLaunching:)
										   name:Adium_CompletedApplicationLoad
										 object:nil];	
	}
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[super dealloc];
}

/*
 * @brief Adium finished launching
 *
 * Delays one more run loop so any events which are registered on this notification are guaranteed to be complete
 * regardless of the order in which the observers are called.
 */
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	[self performSelector:@selector(beginGrowling)
			   withObject:nil
			   afterDelay:0.00001];

	[[adium notificationCenter] removeObserver:self
										  name:Adium_CompletedApplicationLoad
										object:nil];
}

/*
 * @brief Begin accepting Growl events
 */
- (void)beginGrowling
{
	[GrowlApplicationBridge setGrowlDelegate:self];

	//Install our contact alert
	[[adium contactAlertsController] registerActionID:GROWL_EVENT_ALERT_IDENTIFIER withHandler:self];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EVENT_BEZEL];	
	
#ifdef GROWL_DEBUG
	[GrowlApplicationBridge notifyWithTitle:@"We have found a witch."
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

/*
 * @brief Called when preferences changes
 *
 * Used to get the value of the Show While Away preference. 
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	showWhileAway = [[prefDict objectForKey:KEY_EVENT_BEZEL_SHOW_AWAY] boolValue];
}

#pragma mark AIActionHandler
/*
 * @brief Returns a short description of Growl events
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(GROWL_ALERT);
}

/*
 * @brief Returns a long description of Growl events
 *
 * The long description reflects the "sticky"-ness of the notification.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	if([[details objectForKey:KEY_GROWL_ALERT_STICKY] boolValue]){
		return(GROWL_STICKY_ALERT);
	}else{
		return(GROWL_ALERT);
	}
}

/*
 * @brief Returns the image associated with the Growl event
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"GrowlAlert" forClass:[self class]]);
}

/*
 * @brief Post a notification for Growl for display
 *
 * This method is called when by Adium when a Growl alert is activated. It passes this information on to Growl, which displays a notificaion.
 *
 * @param actionID The Action ID being performed, in this case the Growl plugin's Action ID.
 * @param listObject The list object the event is related to
 * @param details A dictionary containing additional information about the event
 * @param eventID The ID of the event (e.g. new message, contact went away, etc)
 * @param userInfo Any additional information
 */
- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	//XXX - bleh
	if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] && ! showWhileAway)
		return;
	
	NSString			*title, *description;
	NSDictionary		*clickContext = nil;
	NSData				*iconData = nil;
	AIChat				*chat = nil;
	BOOL				isMessageEvent = [[adium contactAlertsController] isMessageEvent:eventID];

	//For a message event, listObject should become whomever sent the message
	if(isMessageEvent){
		AIContentObject	*contentObject = [userInfo objectForKey:@"AIContentObject"];
		AIListObject	*source = [contentObject source];
		chat = [userInfo objectForKey:@"AIChat"];

		if(source) listObject = source;
	}

	if(listObject){
		if([listObject isKindOfClass:[AIListContact class]]){
			//Use the parent
			listObject = [[adium contactController] parentContactForListObject:listObject];
			title = [listObject longDisplayName];
		}else{
			title = [listObject displayName];
		}
		
		iconData = [listObject userIconData];
		
		if (!iconData) {
			iconData = [[AIServiceIcons serviceIconForObject:listObject
														type:AIServiceIconLarge
												   direction:AIIconNormal] TIFFRepresentation];
		}
		
		if(chat){
			clickContext = [NSDictionary dictionaryWithObjectsAndKeys:
				[chat uniqueChatID], @"uniqueChatID",
				eventID, @"eventID",
				nil];
			
		}else{
			clickContext = [NSDictionary dictionaryWithObjectsAndKeys:
				[listObject internalObjectID], @"internalObjectID",
				eventID, @"eventID",
				nil];
		}

	}else{
		if(chat){
			title = [chat name];

			clickContext = [NSDictionary dictionaryWithObjectsAndKeys:
				[chat uniqueChatID], @"uniqueChatID",
				eventID, @"eventID",
				nil];
			
			//If we have no listObject or we have a name, we are a group chat and
			//should use the account's service icon
			iconData = [[AIServiceIcons serviceIconForObject:[chat account]
														type:AIServiceIconLarge
												   direction:AIIconNormal] TIFFRepresentation];
			
		}else{
			title = @"Adium";
		}
	}
	
	description = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:eventID
																			 listObject:listObject
																			   userInfo:userInfo
																		 includeSubject:NO];

	NSAssert5((title || description),
			  @"Growl notify error: EventID %@, listObject %@, userInfo %@\nGave Title \"%@\" description \"%@\"",
			  eventID,
			  listObject,
			  userInfo,
			  title,
			  description);
	
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:eventID /* Use the same ID as Adium uses to keep things simple */
								   iconData:iconData
								   priority:0
								   isSticky:[[details objectForKey:KEY_GROWL_ALERT_STICKY] boolValue]
							   clickContext:clickContext];
}

/*
 * @brief Returns our details pane, an instance of <tt>CBGrowlAlertDetailPane</tt>
 */
- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
    return([CBGrowlAlertDetailPane actionDetailsPane]);
}

/*
 * @brief Allow multiple actions?
 *
 * This action should not be performed multiple times for the same triggering event.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(NO);
}

#pragma mark Growl

/*
 * @brief Returns the application name Growl will use
 */
- (NSString *)applicationNameForGrowl
{
	return(@"Adium");
}

/*
 * @brief Registration information for Growl
 *
 * Returns information that Growl needs, like which notifications we will post and our application name.
 */
- (NSDictionary *)registrationDictionaryForGrowl
{
	//Register us with Growl
	NSArray *allNotes = [[adium contactAlertsController] allEventIDs];
	
	NSDictionary * growlReg = [NSDictionary dictionaryWithObjectsAndKeys:
		allNotes, GROWL_NOTIFICATIONS_ALL,
		allNotes, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	return(growlReg);
}

/*
 * @brief Called when Growl is ready
 *
 * Currently, this is just used for debugging Growl.
 */
- (void)growlIsReady
{
#ifdef GROWL_DEBUG
	AILog(@"Growl is go for launch.");
#endif
}

/*
 * @brief Called when a Growl notification is clicked
 *
 * When a Growl notificaion is clicked, this method is called, allowing us to take action (e.g. open a new window, make
 * a conversation active, etc).
 *
 * @param clickContext A dictionary that was passed to Growl when we installed the notification.
 */
- (void)growlNotificationWasClicked:(NSDictionary *)clickContext
{
	NSString		*internalObjectID, *uniqueChatID;
	AIListObject	*listObject;
	AIChat			*chat = nil;
		
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
}

/*
 * @brief The title of the window shown if Growl needs to be installed
 */
- (NSString *)growlInstallationWindowTitle
{
	return(GROWL_INSTALLATION_WINDOW_TITLE);	
}

/*
 * @brief The title of the window shown if Growl needs to be updated
 */
- (NSString *)growlUpdateWindowTitle
{
	return(GROWL_UPDATE_WINDOW_TITLE);
}

/*
 * @brief The body of the window shown if Growl needs to be installed
 *
 * This method calls _growlInformationForUpdate.
 */
- (NSAttributedString *)growlInstallationInformation
{
	return([self _growlInformationForUpdate:NO]);
}

/*
 * @brief The body of the window shown if Growl needs to be update
 *
 * This method calls _growlInformationForUpdate.
 */
- (NSAttributedString *)growlUpdateInformation
{
	return([self _growlInformationForUpdate:YES]);
}

/*
 * @brief Returns the body text for the window displayed when Growl needs to be installed or updated
 *
 * @param isUpdate YES generates the message for the update window, NO likewise for the install window.
 */
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
	
	return(growlInfo);
}

@end
