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

#define GROUP_LAST_USED_SPELLING	@"Last Used Spelling"
#define KEY_LAST_USED_SPELLING		@"Last Used Spelling Languge"

@interface OWSpellingPerContactPlugin (private)
- (void)chatDidBecomeVisible:(NSNotification *)notification;
- (void)chatWillClose:(NSNotification *)notification;
@end

@implementation OWSpellingPerContactPlugin

- (void)installPlugin
{
	NSNotificationCenter *notificationCenter = [adium notificationCenter];
	
	[notificationCenter addObserver:self
						   selector:@selector(chatBecameActive:)
							   name:Chat_BecameActive
							 object:nil];
	
	[notificationCenter addObserver:self
						   selector:@selector(chatWillClose:)
							   name:Chat_WillClose
							 object:nil];
	
	languageDict = [[NSMutableDictionary alloc] init];
}

- (void)uninstallPlugin
{
	[languageDict release]; languageDict = nil;

	[[adium notificationCenter] removeObserver:self];
}

- (void)chatBecameActive:(NSNotification *)notification
{
	AIChat	 *newChat = [notification object];
	AIChat	 *previousChat = [[notification userInfo] objectForKey:@"PreviouslyActiveChat"];

	if (previousChat) {
		NSString *language = [[NSSpellChecker sharedSpellChecker] language];
		NSString *chatID = [previousChat uniqueChatID];

		if (language &&
			![[languageDict objectForKey:chatID] isEqualToString:language]) {
			//If this chat is not known to be in the current language, store its setting in our languageDict
			[languageDict setObject:language
							 forKey:chatID];
		}
	}
	
	if (newChat) {
		NSString *chatID = [newChat uniqueChatID];
		NSString *newChatLanguage = [languageDict objectForKey:chatID];
		
		//If we don't have a previously noted language, try to load one from a preference
		if (!newChatLanguage) {
			AIListObject *listObject = [newChat listObject];

			if (listObject) {
				//Load the preference if possible
				newChatLanguage = [listObject preferenceForKey:KEY_LAST_USED_SPELLING group:GROUP_LAST_USED_SPELLING];
			}

			if (!newChatLanguage) {
				//If no preference, set to @"" so we won't keep trying to load the preference
				newChatLanguage = @"";
			}

			[languageDict setObject:newChatLanguage
							 forKey:chatID];
		}
		
		if ([newChatLanguage length]) {
			//Only set the language if we have one specified
			[[NSSpellChecker sharedSpellChecker] setLanguage:newChatLanguage];
		}
	}
}

- (void)chatWillClose:(NSNotification *)notification
{
	AIChat		 *chat = [notification object];
	AIListObject *listObject = [chat listObject];

	if (listObject) {
		NSString	 *chatID = [chat uniqueChatID];
		NSString	 *chatLanguage = [languageDict objectForKey:chatID];

		//If we didn't cache a language for this chat, we might just never have made it inactive; save the current language
		if (!chatLanguage) chatLanguage = [[NSSpellChecker sharedSpellChecker] language];
		
		//Save the last used language for this chat as it closes
		[listObject setPreference:chatLanguage
						   forKey:KEY_LAST_USED_SPELLING
							group:GROUP_LAST_USED_SPELLING];

		[languageDict removeObjectForKey:chatID];
	}
}

@end
