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

#import "IdleMessagePlugin.h"
#import "IdleMessagePreferences.h"

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
    [[adium notificationCenter] addObserver:self
				   selector:@selector(preferencesChanged:)
				       name:Preference_GroupChanged
				     object:nil];
	
	[self preferencesChanged:nil];
}

//Account preferences changed
- (void)preferencesChanged:(NSNotification *)notification
{
	
	//FIX ME!
    //NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    
    //if([group compare:GROUP_ACCOUNT_STATUS] == 0){
        //NSString	*modifiedKey = [[notification userInfo] objectForKey:@"Key"];
	
        //if([modifiedKey compare:@"IdleSince"] == 0 ){ //We ignore account specific idle (why?)

	if( notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:GROUP_ACCOUNT_STATUS] ) {
            if([[[adium preferenceController] preferenceForKey:KEY_IDLE_MESSAGE_ENABLED group:PREF_GROUP_IDLE_MESSAGE] boolValue] ) {

                //Remove existing content sent/received observer, and install new (if away)
                [[adium notificationCenter] removeObserver:self name:Content_DidReceiveContent object:nil];
                [[adium notificationCenter] removeObserver:self name:Content_FirstContentRecieved object:nil];
                [[adium notificationCenter] removeObserver:self name:Content_DidSendContent object:nil];
				[[adium notificationCenter] removeObserver:self name:Chat_WillClose object:nil];

                //Only install new observers if we're idle
				if( [[adium preferenceController] preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS] != nil ) {

					[[adium notificationCenter] addObserver:self 
						   selector:@selector(didReceiveContent:) 
						       name:Content_DidReceiveContent object:nil];
                    [[adium notificationCenter] addObserver:self
						   selector:@selector(didReceiveContent:)
						       name:Content_FirstContentRecieved object:nil];
                    [[adium notificationCenter] addObserver:self
						   selector:@selector(didSendContent:) 
						       name:Content_DidSendContent object:nil];
					[[adium notificationCenter] addObserver:self
						   selector:@selector(chatWillClose:)
						       name:Chat_WillClose object:nil];
                }

                //Flush our array of 'responded' contacts
                [receivedIdleMessage release]; receivedIdleMessage = [[NSMutableArray alloc] init];
            }
        }
    //}
}

//Called when Adium receives content
- (void)didReceiveContent:(NSNotification *)notification
{

    AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"Object"];
            
    NSAttributedString	*idleMessage = [NSAttributedString stringWithData:[[adium preferenceController] preferenceForKey:@"IdleMessage" group:GROUP_ACCOUNT_STATUS]];
    //If the user received a message, send our idle message to them
    if([[contentObject type] isEqualToString:CONTENT_MESSAGE_TYPE]){
        if(idleMessage && [idleMessage length] != 0){
            //Only send if there's no away message up!
            if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] == nil) {
                AIChat	*chat = [contentObject chat];
                //Create and send an idle bounce message (If the sender hasn't received one already)
                if([receivedIdleMessage indexOfObjectIdenticalTo:chat] == NSNotFound){
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
    AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"Object"];

    if([[contentObject type] isEqualToString:CONTENT_MESSAGE_TYPE]){
        AIChat	*chat = [contentObject chat];

        if([receivedIdleMessage indexOfObjectIdenticalTo:chat] == NSNotFound){
            [receivedIdleMessage addObject:chat];
        }
    }
}

- (void)chatWillClose:(NSNotification *)notification
{
    AIChat *chat = [notification object];
    int chatIndex = [receivedIdleMessage indexOfObjectIdenticalTo:chat];
    
    if (chatIndex != NSNotFound)
	[receivedIdleMessage removeObjectAtIndex:chatIndex];
}

@end