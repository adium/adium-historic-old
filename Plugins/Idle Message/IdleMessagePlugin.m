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

#import "IdleMessagePlugin.h"
#import "IdleMessagePreferences.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/BZArrayAdditions.h>

@interface IdleMessagePlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)accountIdleStatusChanged:(NSNotification *)notification;
@end

@implementation IdleMessagePlugin

- (void)installPlugin
{
    //Setup our preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_MESSAGE_DEFAULT_PREFS forClass:[self class]]
					  forGroup:PREF_GROUP_IDLE_MESSAGE];
    preferences = [[IdleMessagePreferences preferencePane] retain];

    //Observe
	[[adium preferenceController] registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];
}

//Account preferences changed
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if([[[adium preferenceController] preferenceForKey:KEY_IDLE_MESSAGE_ENABLED group:PREF_GROUP_IDLE_MESSAGE] boolValue] ) {
		
		//Remove existing content sent/received observer, and install new (if away)
		[[adium notificationCenter] removeObserver:self name:CONTENT_MESSAGE_RECEIVED object:nil];
		[[adium notificationCenter] removeObserver:self name:CONTENT_MESSAGE_SENT object:nil];
		[[adium notificationCenter] removeObserver:self name:Chat_WillClose object:nil];
		
		//Only install new observers if we're idle
		if([prefDict objectForKey:@"IdleSince"] != nil ) {
			[[adium notificationCenter] addObserver:self 
										   selector:@selector(didReceiveContent:) 
											   name:CONTENT_MESSAGE_RECEIVED object:nil];
			[[adium notificationCenter] addObserver:self
										   selector:@selector(didSendContent:) 
											   name:CONTENT_MESSAGE_SENT object:nil];
			[[adium notificationCenter] addObserver:self
										   selector:@selector(chatWillClose:)
											   name:Chat_WillClose object:nil];
		}
		
		//Flush our array of 'responded' contacts
		[receivedIdleMessage release]; receivedIdleMessage = [[NSMutableArray alloc] init];
	}
}

//Called when Adium receives content
- (void)didReceiveContent:(NSNotification *)notification
{
    AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"AIContentObject"];
            
    NSAttributedString	*idleMessage = [NSAttributedString stringWithData:[[adium preferenceController] preferenceForKey:@"IdleMessage" group:GROUP_ACCOUNT_STATUS]];
    //If the user received a message, send our idle message to them
    if([[contentObject type] isEqualToString:CONTENT_MESSAGE_TYPE]){
        if(idleMessage && [idleMessage length] != 0){
            //Only send if there's no away message up!
            if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] == nil) {
                AIChat	*chat = [contentObject chat];
                //Create and send an idle bounce message (If the sender hasn't received one already)
                if(![receivedIdleMessage containsObjectIdenticalTo:chat] && ([chat name] == nil)){
                    AIContentMessage	*responseContent;
                    
                    responseContent = [AIContentMessage messageInChat:chat
                                                           withSource:[contentObject destination]
                                                          destination:[contentObject source]
                                                                 date:nil
                                                              message:idleMessage
                                                            autoreply:YES];
                    [[adium contentController] sendContentObject:responseContent];
                }	
            }	
        }	
    }	
}	

//Called when Adium sends content
- (void)didSendContent:(NSNotification *)notification
{
    AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"AIContentObject"];

    if([[contentObject type] isEqualToString:CONTENT_MESSAGE_TYPE]){
        AIChat	*chat = [contentObject chat];

        if(![receivedIdleMessage containsObjectIdenticalTo:chat]){
            [receivedIdleMessage addObject:chat];
        }
    }
}

- (void)chatWillClose:(NSNotification *)notification
{
    AIChat *chat = [notification object];

	[receivedIdleMessage removeObjectIdenticalTo:chat];
}

@end