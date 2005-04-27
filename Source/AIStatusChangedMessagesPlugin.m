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

#import "AIStatusChangedMessagesPlugin.h"
#import "AIContentController.h"
#import "ESContactAlertsController.h"
#import <Adium/AIListContact.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentStatus.h>

@interface AIStatusChangedMessagesPlugin (PRIVATE)
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact 
			 withType:(NSString *)type
 phraseWithoutSubject:(NSString *)statusPhrase
			  inChats:(NSSet *)inChats;
@end

/*!
 * @class AIStatusChangedMessagesPlugin
 * @brief Generate <tt>AIContentStatus</tt> messages in open chats in response to contact status changes
 */
@implementation AIStatusChangedMessagesPlugin

static	NSDictionary	*statusTypeDict = nil;

/*!
 * @brief Install
 */
- (void)installPlugin
{
	statusTypeDict = [[NSDictionary dictionaryWithObjectsAndKeys:
		@"away",CONTACT_STATUS_AWAY_YES,
		@"return_away",CONTACT_STATUS_AWAY_NO,
		@"online",CONTACT_STATUS_ONLINE_YES,
		@"offline",CONTACT_STATUS_ONLINE_NO,
		@"idle",CONTACT_STATUS_IDLE_YES,
		@"return_idle",CONTACT_STATUS_IDLE_NO,
		@"away_message",CONTACT_STATUS_MESSAGE,
		nil] retain];
		
    //Observe contact status changes
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_ONLINE_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_ONLINE_NO object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_IDLE_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_IDLE_NO object:nil];

	[[adium notificationCenter] addObserver:self selector:@selector(contactAwayChanged:) name:CONTACT_STATUS_AWAY_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactAwayChanged:) name:CONTACT_STATUS_AWAY_NO object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contact_statusMessage:) name:CONTACT_STATUS_MESSAGE object:nil];
}

/*!
 * @brief Notification a changed status message
 *
 * @param notification <tt>NSNotification</tt> whose object is the AIListContact
 */
- (void)contact_statusMessage:(NSNotification *)notification{
	NSSet			*allChats;
	AIListContact	*contact = [notification object];
	
	allChats = [[adium contentController] allChatsWithContact:contact];
	if([allChats count]){	
		if([contact statusType] != AIAvailableStatusType){
			NSString		*statusMessage = [[contact statusMessage] string];
			NSString		*statusType = [statusTypeDict objectForKey:CONTACT_STATUS_MESSAGE];
			
			if(statusMessage && [statusMessage length] != 0){
				[self statusMessage:[NSString stringWithFormat:AILocalizedString(@"Away Message: %@",nil),statusMessage] 
						 forContact:contact
						   withType:statusType
			   phraseWithoutSubject:statusMessage
							inChats:allChats];
			}
		}
	}
}

/*!
 * @brief Contact status changed notification
 *
 * @param notification <tt>NSNotification</tt> whose object is the AIListContact and whose name is the eventID
 */
- (void)contactStatusChanged:(NSNotification *)notification{
	NSSet			*allChats;
	AIListContact	*contact = [notification object];
	
	allChats = [[adium contentController] allChatsWithContact:contact];
	if([allChats count]){
		NSString		*description, *phraseWithoutSubject;
		NSString		*name = [notification name];
		NSDictionary	*userInfo = [notification userInfo];
		
		description = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:name
																				 listObject:contact
																				   userInfo:userInfo
																			 includeSubject:YES];
		phraseWithoutSubject = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:name
																						  listObject:contact
																							userInfo:userInfo
																					  includeSubject:NO];		
		[self statusMessage:description
				 forContact:contact
				   withType:[statusTypeDict objectForKey:name]
	   phraseWithoutSubject:phraseWithoutSubject
					inChats:allChats];
	}
}

/*
 * @brief Special handling for away changes
 *
 * We only display the "Went away" message if a status message for the away hasn't already been printed
 */
- (void)contactAwayChanged:(NSNotification *)notification
{
	NSDictionary	*userInfo = [notification userInfo];
	
	if(![[userInfo objectForKey:@"Already Posted StatusMessage"] boolValue]){
		[self contactStatusChanged:notification];
	}
}

/*!
 * @brief Post a status message on all active chats for this object
 */
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact 
			 withType:(NSString *)type
 phraseWithoutSubject:(NSString *)statusPhrase
			  inChats:(NSSet *)inChats
{
    NSEnumerator		*enumerator;
    AIChat				*chat;
	NSAttributedString	*attributedMessage = [[[NSAttributedString alloc] initWithString:message
																			  attributes:[[adium contentController] defaultFormattingAttributes]] autorelease];

	enumerator = [inChats objectEnumerator];
	while((chat = [enumerator nextObject])){
		AIContentStatus	*content;
		
		//Create our content object
		content = [AIContentStatus statusInChat:chat
									 withSource:contact
									destination:[chat account]
										   date:[NSDate date]
										message:attributedMessage
									   withType:type];
		
		if(statusPhrase){
			NSDictionary	*userInfo = [NSDictionary dictionaryWithObject:statusPhrase
																	forKey:@"Status Phrase"];
			[content setUserInfo:userInfo];
		}

		//Add the object
		[[adium contentController] receiveContentObject:content];
	}
}

@end
