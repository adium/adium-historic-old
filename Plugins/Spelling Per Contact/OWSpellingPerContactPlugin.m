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

#import "OWSpellingPerContactPlugin.h"
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>

#define LastUsedSpellingGroup	@"Last Used Spelling"
#define LastUsedSpellingLang	@"Last Used Spelling Languge"

@interface OWSpellingPerContactPlugin (private)
- (void)chatDidBecomeVisible:(NSNotification *)notification;
- (void)chatWillClose:(NSNotification *)notification;
@end


@implementation OWSpellingPerContactPlugin

- (void)installPlugin
{
	NSNotificationCenter *notificationCenter = [adium notificationCenter];
	
	[notificationCenter addObserver:self
						   selector:@selector(chatDidBecomeVisible:)
							   name:@"AIChatDidBecomeVisible"
							 object:nil];
	
	[notificationCenter addObserver:self
						   selector:@selector(chatWillClose:)
							   name:Chat_WillClose
							 object:nil];
	
	previousChat = nil;
}

- (void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
	[previousChat release];
	previousChat = nil;
}

- (void)chatDidBecomeVisible:(NSNotification *)notification
{
	AIChat *newChat;
	
	if([[notification object] isKindOfClass:[AIChat class]]){
		newChat = [notification object];
		
		if(previousChat)
			//Save the last used language for the previous chat
			[[previousChat listObject] setPreference:[[NSSpellChecker sharedSpellChecker] language]
											  forKey:LastUsedSpellingLang
											   group:LastUsedSpellingGroup];
		[previousChat release];
		previousChat = [newChat retain];
		
		//Load the last used language for the new chat
		[[NSSpellChecker sharedSpellChecker] setLanguage:[[newChat listObject] preferenceForKey:LastUsedSpellingLang group:LastUsedSpellingGroup]];
	}
}

- (void)chatWillClose:(NSNotification *)notification
{
	if(previousChat == [notification object]){
		//Save the last used language for the previous chat
		[[previousChat listObject] setPreference:[[NSSpellChecker sharedSpellChecker] language]
										  forKey:LastUsedSpellingLang
										   group:LastUsedSpellingGroup];
		[previousChat release];
		previousChat = nil;
	}
}

@end
