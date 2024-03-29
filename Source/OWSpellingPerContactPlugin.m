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

/*!
 * @class OWSpellingPerContactPlugin
 * @brief Component to save and restore spelling dictionary language preferences on a per-contact basis for chats
 *
 * Language settings on a group chat basis are not currently saved.
 */
@implementation OWSpellingPerContactPlugin

/*!
 * @brief Install
 */
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
	
	//Find the first language the user prefers which the spellchecker knows about, then keep it around for future reference
	NSEnumerator *enumerator = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectEnumerator];
	NSString	 *language;
	while ((language = [enumerator nextObject])) {
		if ([[NSSpellChecker sharedSpellChecker] setLanguage:language]) {
			preferredLanguage = [language retain];
			break;
		}
	}
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[languageDict release]; languageDict = nil;
	[preferredLanguage release]; preferredLanguage = nil;
	
	[[adium notificationCenter] removeObserver:self];
}

/*!
 * @brief A chat became active; set the spelling language preference appropriately
 *
 * If a chat was previously active, as indicated by the PreviouslyActiveChat key in the notification's userInfo,
 * its language preference is stored before switching.
 */
- (void)chatBecameActive:(NSNotification *)notification
{
	@try
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
					//If no preference, use the preferred language
					newChatLanguage = preferredLanguage;
				}

				[languageDict setObject:newChatLanguage
								 forKey:chatID];
			}

			[[NSSpellChecker sharedSpellChecker] setLanguage:newChatLanguage];
		}
	}
	@catch(id exc) {}
}

/*!
 * @brief Chat will close; save the language preference for its contact before it closes
 */
- (void)chatWillClose:(NSNotification *)notification
{
	AIChat			*chat = [notification object];
	AIListContact	*listObject = [chat listObject];

	if (listObject) {
		NSString	 *chatID = [chat uniqueChatID];
		NSString	 *chatLanguage = [languageDict objectForKey:chatID];

		//If we didn't cache a language for this chat, we might just never have made it inactive; use the spell checker's current language
		if (!chatLanguage) chatLanguage = [[NSSpellChecker sharedSpellChecker] language];

		//Now, if we end up at the user's default language, we don't want to store anything
		if ([preferredLanguage isEqualToString:chatLanguage])
			chatLanguage = nil;
		
		[listObject setPreference:chatLanguage
						   forKey:KEY_LAST_USED_SPELLING
							group:GROUP_LAST_USED_SPELLING];			

		[languageDict removeObjectForKey:chatID];
	}
}

@end
