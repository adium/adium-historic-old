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
    [[owner notificationCenter] addObserver:self selector:@selector(accountIdleStatusChanged:) name:Account_StatusChanged object:nil];
    
}


//Update our menu when the away status changes
- (void)accountIdleStatusChanged:(NSNotification *)notification
{

    if(notification == nil || [notification object] == nil){
        //We ignore account-specific status changes
        NSString	*modifiedKey = [[notification userInfo] objectForKey:@"Key"];
        
        if([modifiedKey compare:@"IdleSince"] == 0){

            NSLog(@"-------- Idle Status Changed --------");

            /*
            //Remove existing content sent/received observer, and install new (if away)
            [[owner notificationCenter] removeObserver:self name:Content_DidReceiveContent object:nil];
            [[owner notificationCenter] removeObserver:self name:Content_DidSendContent object:nil];
            if([[owner accountController] statusObjectForKey:@"AwayMessage" account:nil] != nil){
                [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
                [[owner notificationCenter] addObserver:self selector:@selector(didSendContent:) name:Content_DidSendContent object:nil];
            }

            //Flush our array of 'responded' contacts
            [receivedAwayMessage release]; receivedAwayMessage = [[NSMutableArray alloc] init];
             */
            
        }
    }

    // NEW BLOCK
    /*
    if(notification == nil || [key compare:@"IdleSince"] == 0){
        if(changedAccount == nil){ //Global status change
            BOOL idle = ([[owner accountController] statusObjectForKey:@"IdleSince" account:nil] != nil);

            if(idle && !idleState){
                idleState = [[owner dockController] setIconStateNamed:@"Idle"];

            }else if(!idle && idleState){
                [[owner dockController] removeIconState:idleState];
                idleState = nil;

            }

        }

    }
     */

}



- (void)uninstallPlugin
{

}

@end