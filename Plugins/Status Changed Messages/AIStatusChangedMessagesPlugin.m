/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact withType:(NSString *)type;
@end

@implementation AIStatusChangedMessagesPlugin

- (void)installPlugin
{
    //Observe contact status changes
    [[adium notificationCenter] addObserver:self selector:@selector(Contact_StatusAwayYes:) name:CONTACT_STATUS_AWAY_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(Contact_StatusAwayNo:) name:CONTACT_STATUS_AWAY_NO object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(Contact_StatusOnlineYes:) name:CONTACT_STATUS_ONLINE_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(Contact_StatusOnlineNO:) name:CONTACT_STATUS_ONLINE_NO object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(Contact_StatusIdleYes:) name:CONTACT_STATUS_IDLE_YES object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(Contact_StatusIdleNo:) name:CONTACT_STATUS_IDLE_NO object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(Contact_StatusMessage:) name:CONTACT_STATUS_MESSAGE object:nil];
}

- (void)Contact_StatusMessage:(NSNotification *)notification{
	AIListContact	*contact = [notification object];
	NSString		*statusMessage = [contact stringFromAttributedStringStatusObjectForKey:@"StatusMessage"
																	fromAnyContainedObject:YES];
	NSString		*statusType = @"away_message";
	
	if(statusMessage && [statusMessage length] != 0){
		[self statusMessage:[NSString stringWithFormat:AILocalizedString(@"Away Message: %@",nil),statusMessage] forContact:contact withType:statusType];
	}
}

- (void)Contact_StatusAwayYes:(NSNotification *)notification{
    AIListContact *contact = [notification object];
	NSString *statusType = @"away";
	
    [self statusMessage:[NSString stringWithFormat:AILocalizedString(@"%@ went away",nil),[contact displayName]] forContact:contact withType:statusType];
}
- (void)Contact_StatusAwayNo:(NSNotification *)notification{
    AIListContact *contact = [notification object];
	NSString *statusType = @"return_away";
    
    if([contact integerStatusObjectForKey:@"Online"])
		[self statusMessage:[NSString stringWithFormat:AILocalizedString(@"%@ came back",nil),[contact displayName]] forContact:contact withType:statusType];
}
- (void)Contact_StatusOnlineYes:(NSNotification *)notification{
    AIListContact *contact = [notification object];
	NSString *statusType = @"online";
	
	[self statusMessage:[NSString stringWithFormat:AILocalizedString(@"%@ connected",nil),[contact displayName]] forContact:contact withType:statusType];
}
- (void)Contact_StatusOnlineNO:(NSNotification *)notification{
    AIListContact *contact = [notification object];
	NSString *statusType = @"offline";
	
	[self statusMessage:[NSString stringWithFormat:AILocalizedString(@"%@ disconnected",nil),[contact displayName]] forContact:contact withType:statusType];
}
- (void)Contact_StatusIdleYes:(NSNotification *)notification{
    AIListContact *contact = [notification object];
	NSString *statusType = @"idle";
	
	[self statusMessage:[NSString stringWithFormat:AILocalizedString(@"%@ went idle",nil),[contact displayName]] forContact:contact withType:statusType];
}
- (void)Contact_StatusIdleNo:(NSNotification *)notification{
    AIListContact *contact = [notification object];
	NSString *statusType = @"return_idle";
	
	[self statusMessage:[NSString stringWithFormat:AILocalizedString(@"%@ became active",nil),[contact displayName]] forContact:contact withType:statusType];
}


//Post a status message on all active chats for this object
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact withType:(NSString *)type
{
    NSEnumerator		*enumerator;
    AIChat				*chat;
	NSAttributedString	*attributedMessage = [[[NSAttributedString alloc] initWithString:message
																			  attributes:[[adium contentController] defaultFormattingAttributes]] autorelease];
	
    enumerator = [[[adium contentController] allChatsWithContact:contact] objectEnumerator];
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
