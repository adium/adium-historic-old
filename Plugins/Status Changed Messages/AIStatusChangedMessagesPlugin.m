/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIStatusChangedMessagesPlugin.h"

@interface AIStatusChangedMessagesPlugin (PRIVATE)
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact withType:(NSString *)type inChats:(NSSet *)inChats;
@end

@implementation AIStatusChangedMessagesPlugin

static	NSDictionary	*statusTypeDict = nil;
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
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_AWAY_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_AWAY_NO object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_ONLINE_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_ONLINE_NO object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_IDLE_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactStatusChanged:) name:CONTACT_STATUS_IDLE_NO object:nil];

    [[adium notificationCenter] addObserver:self selector:@selector(Contact_StatusMessage:) name:CONTACT_STATUS_MESSAGE object:nil];
}

- (void)Contact_StatusMessage:(NSNotification *)notification{
	NSSet			*allChats;
	AIListContact	*contact = [notification object];
	
	allChats = [[adium contentController] allChatsWithContact:contact];
	if([allChats count]){	
		NSString		*statusMessage = [contact stringFromAttributedStringStatusObjectForKey:@"StatusMessage"
																		fromAnyContainedObject:YES];
		NSString		*statusType = @"away_message";
		
		if(statusMessage && [statusMessage length] != 0){
			[self statusMessage:[NSString stringWithFormat:AILocalizedString(@"Away Message: %@",nil),statusMessage] 
					 forContact:contact
					   withType:statusType
						inChats:allChats];
		}
	}
}

- (void)contactStatusChanged:(NSNotification *)notification{
	NSSet			*allChats;
	AIListContact	*contact = [notification object];
	
	allChats = [[adium contentController] allChatsWithContact:contact];
	if([allChats count]){
		NSString		*description;
		NSString		*name = [notification name];
		
		description = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:name
																				 listObject:contact
																				   userInfo:[notification userInfo]
																			 includeSubject:YES];
		
		
		[self statusMessage:description
				 forContact:contact
				   withType:[statusTypeDict objectForKey:name]
					inChats:allChats];
	}
}

//Post a status message on all active chats for this object
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact withType:(NSString *)type inChats:(NSSet *)inChats
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
		
		//Add the object
		[[adium contentController] receiveContentObject:content];
	}
}

@end
