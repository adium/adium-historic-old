/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import "IdleMessagePlugin.h"
#import "IdleMessagePreferences.h"

#define IDLE_MESSAGE_DEFAULT_PREFS	@"IdleMessageDefaultPrefs"

@interface IdleMessagePlugin (PRIVATE)
- (void)accountIdleStatusChanged:(NSNotification *)notification;
@end

@implementation IdleMessagePlugin

- (void)installPlugin
{

    //Register default preferences and pre-set behavior
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_MESSAGE_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_IDLE_MESSAGE];

    //Install our preference view
    preferences = [[IdleMessagePreferences idleMessagePreferencesWithOwner:owner] retain];

    // Observe
    [[owner notificationCenter] addObserver:self selector:@selector(accountIdleStatusChanged:) name:Account_PropertiesChanged object:nil];
    
}


- (void)accountIdleStatusChanged:(NSNotification *)notification
{

    if(notification == nil || [notification object] == nil){
        //We ignore account-specific status changes
        NSString	*modifiedKey = [[notification userInfo] objectForKey:@"Key"];
        
        if([modifiedKey compare:@"IdleSince"] == 0){

            if([[[[owner preferenceController] preferencesForGroup:PREF_GROUP_IDLE_MESSAGE] objectForKey:KEY_IDLE_MESSAGE_ENABLED] boolValue] == TRUE) {

                //Remove existing content sent/received observer, and install new (if away)
                [[owner notificationCenter] removeObserver:self name:Content_DidReceiveContent object:nil];
                [[owner notificationCenter] removeObserver:self name:Content_DidSendContent object:nil];
                if([[owner accountController] propertyForKey:@"IdleSince" account:nil] != nil){
                    [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
                    [[owner notificationCenter] addObserver:self selector:@selector(didSendContent:) name:Content_DidSendContent object:nil];
                }

                //Flush our array of 'responded' contacts
                [receivedIdleMessage release]; receivedIdleMessage = [[NSMutableArray alloc] init];
            
            }
        }
    }

}

//Called when Adium receives content
- (void)didReceiveContent:(NSNotification *)notification
{
    AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"Object"];
    // TEMPORARY!!!
    NSAttributedString	*idleMessage = [NSAttributedString stringWithData:[[owner accountController] propertyForKey:@"IdleMessage" account:nil]];
    //NSAttributedString	*idleMessage = [NSAttributedString stringWithData:[[owner accountController] propertyForKey:@"AwayMessage" account:nil]];

    //If the user received a message, send our idle message to them
    if([[contentObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        if(idleMessage && [idleMessage length] != 0){
            // Only send if there's no away message up!
            if([[owner accountController] propertyForKey:@"AwayMessage" account:nil] == nil) {
                AIListContact	*contact = [contentObject source];

                //Create and send an idle bounce message (If the sender hasn't received one already)
                if(![receivedIdleMessage containsObject:[contact UIDAndServiceID]]){
                    AIContentMessage	*responseContent;

                    responseContent = [AIContentMessage messageInChat:[contentObject chat]
                                                           withSource:[contentObject destination]
                                                          destination:contact
                                                                 date:nil
                                                              message:idleMessage
                                                            autoreply:YES];

                    [[owner contentController] sendContentObject:responseContent];
                }	
            }	
        }	
    }	
}	

//Called when Adium sends content
- (void)didSendContent:(NSNotification *)notification
{
    AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"Object"];

    if([[contentObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIListContact	*contact = [contentObject destination];
        NSString 	*senderUID = [contact UIDAndServiceID];

        //Add the handle's UID to our 'already received idle message' array, so they only receive the message once.
        if(![receivedIdleMessage containsObject:senderUID]){
            [receivedIdleMessage addObject:senderUID];
        }
    }
}


- (void)uninstallPlugin
{

}

@end