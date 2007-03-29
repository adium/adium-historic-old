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

#import <AIChat.h>
#import <AIListGroup.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AINudgeBuzzHandlerPlugin.h"

@implementation AINudgeBuzzHandlerPlugin

- (void)installPlugin
{
	// Register our event.
	[[adium contactAlertsController] registerEventID:CONTENT_NUDGE_BUZZ_OCCURED
										 withHandler:self
											 inGroup:AIMessageEventHandlerGroup
										  globalOnly:NO];
	
	// Register to observe a nudge or buzz event.
	[[adium notificationCenter] addObserver:self
								   selector:@selector(nudgeBuzzDidOccur:)
									   name:Chat_NudgeBuzzOccured
									 object:nil];
}

- (void)uninstallPlugin
{
	// Unregister ourself.
	[[adium notificationCenter] removeObserver:self];
}

#pragma mark Nudge/Buzz Handling

// Echoes the buzz event to the window and generates the event.
- (void)nudgeBuzzDidOccur:(NSNotification *)notification
{
	AIChat			*chat     = [notification object];
	NSString		*description, *format, *type = [[notification userInfo] objectForKey:@"Type"];
	
	if ([type isEqualToString:@"Buzz"]) {
		format = AILocalizedString(@"%@ sent a Buzz!", "Contact sent a Buzz!");
	} else if ([type isEqualToString:@"Nudge"]) {
		format = AILocalizedString(@"%@ sent a Nudge!", "Contact sent a Nudge!");
	} else if ([type isEqualToString:@"notification"]) {
		format = AILocalizedString(@"%@ sent a notification!", "Contact sent a notification.");
	}
	
	// Create the display text.
	description = [NSString stringWithFormat:format, [[chat listObject] displayName]];
	
	// Print the text to the window.
	[[adium contentController] displayEvent:description
									 ofType:@"notificationOccured"
									 inChat:chat];
	
	// Fire off the event
	[[adium contactAlertsController] generateEvent:CONTENT_NUDGE_BUZZ_OCCURED
									 forListObject:[chat listObject]
										  userInfo:nil
					  previouslyPerformedActionIDs:nil];
	
	// Flash content if this isn't the active chat.
	if ([[adium interfaceController] activeChat] != chat) {
		[chat incrementUnviewedContentCount];
	}
}


#pragma mark Event descriptions
- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	return AILocalizedString(@"Notification received", nil);
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	return AILocalizedString(@"Notification received", nil);
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	return AILocalizedString(@"Notification received", nil);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description = nil;
	
	if (listObject) {
		NSString	*name;
		NSString	*format = AILocalizedString(@"When %@ sends a notification", nil);
		
		name = ([listObject isKindOfClass:[AIListGroup class]] ?
				[NSString stringWithFormat:AILocalizedString(@"a member of %@", nil),[listObject displayName]] :
				[listObject displayName]);
			
		description = [NSString stringWithFormat:format, name];
	} else {
		description = AILocalizedString(@"When a contact sends a notification", nil);
	}
	
	return description;
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString		*description = nil;
	
	if (includeSubject) {		
		description = [NSString stringWithFormat:
			AILocalizedString(@"%@ sent a notification","Contact sent a notification"),
			[listObject displayName]];
	} else {
		description = AILocalizedString(@"Sent a notification", nil);
	}
	
	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	//Use the message icon from the main bundle
	if (!eventImage) eventImage = [[NSImage imageNamed:@"message"] retain];
	return eventImage;
}

@end
