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

#import "AIContactStatusEventsPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define CONTACT_STATUS_ONLINE_YES	@"Contact_StatusOnlineYes"
#define CONTACT_STATUS_ONLINE_NO	@"Contact_StatusOnlineNO"
#define CONTACT_STATUS_AWAY_YES		@"Contact_StatusAwayYes"
#define CONTACT_STATUS_AWAY_NO		@"Contact_StatusAwayNo"
#define CONTACT_STATUS_IDLE_YES		@"Contact_StatusIdleYes"
#define CONTACT_STATUS_IDLE_NO		@"Contact_StatusIdleNo"

//Generates events when a contact changes status, so other plugins may respond to them.  This plugin correctly handles multiple accounts, so a contact changing status on n accounts will only ever generate 1 event.

@implementation AIContactStatusEventsPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactObserver:self];

    onlineDict = [[NSMutableDictionary alloc] init];
    awayDict = [[NSMutableDictionary alloc] init];
    idleDict = [[NSMutableDictionary alloc] init];

    [owner registerEventNotification:CONTACT_STATUS_ONLINE_YES displayName:@"Contact Signed On"];
    [owner registerEventNotification:CONTACT_STATUS_ONLINE_NO displayName:@"Contact Signed Off"];
    [owner registerEventNotification:CONTACT_STATUS_AWAY_YES displayName:@"Contact Away"];
    [owner registerEventNotification:CONTACT_STATUS_AWAY_NO displayName:@"Contact UnAway"];
    [owner registerEventNotification:CONTACT_STATUS_IDLE_YES displayName:@"Contact Idle"];
    [owner registerEventNotification:CONTACT_STATUS_IDLE_NO displayName:@"Contact UnIdle"];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
    //remove observers
}

- (NSArray *)updateContact:(AIListContact *)inContact keys:(NSArray *)inModifiedKeys
{
    //To increase the speed of heavy contact list operations (connecting/disconnecting/etc), we don't sent out any events when the contact list updates are delayed.
    if(![[owner contactController] holdContactListUpdates]){        
        if([inModifiedKeys containsObject:@"Online"]){ //Sign on/off
            BOOL	newStatus = [[inContact statusArrayForKey:@"Online"] greatestIntegerValue];

//            if(online){ //We only send out events if the handle has a value (nil values mean the flag is being cleared)
                NSNumber	*oldStatusNumber = [onlineDict objectForKey:[inContact UIDAndServiceID]];
                BOOL		oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough
//                BOOL		newStatus = [online boolValue];

                if(oldStatusNumber == nil || newStatus != oldStatus){
                    AIMutableOwnerArray	*signedOnArray = [inContact statusArrayForKey:@"Signed On"];
                    AIMutableOwnerArray	*signedOffArray = [inContact statusArrayForKey:@"Signed Off"];
                    
                    //Post an online/offline notification
                    [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO)
                                                              object:inContact
                                                            userInfo:nil];
                    [onlineDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inContact UIDAndServiceID]];

                    //Clear any existing juston/just off values
                    [signedOnArray setObject:nil withOwner:inContact];
                    [signedOffArray setObject:nil withOwner:inContact];

                    //Set status flags and install timers for "Just signed on" and "Just signed off"
                    [(newStatus ? signedOnArray : signedOffArray) setObject:[NSNumber numberWithBool:YES] withOwner:inContact];
                    [[owner contactController] contactStatusChanged:inContact
                                                modifiedStatusKeys:[NSArray arrayWithObjects:@"Signed On",@"Signed Off",nil]];

                    [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(clearOnlineFlags:) userInfo:inContact repeats:NO];
                }
//            }
            
        }else if([inModifiedKeys containsObject:@"Away"]){ //Away / Unaway
            BOOL newStatus = [[inContact statusArrayForKey:@"Away"] greatestIntegerValue];
//            NSNumber	*away = [[inHandle statusDictionary] objectForKey:@"Away"];

//            if(away){ //We only send out events if the handle has a value (nil values mean the flag is being cleared)
                NSNumber	*oldStatusNumber = [awayDict objectForKey:[inContact UIDAndServiceID]];
                BOOL		oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough
//                BOOL		newStatus = [away boolValue];

                if(oldStatusNumber == nil || newStatus != oldStatus){
                    [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO)
                                                              object:inContact
                                                            userInfo:nil];
                    [awayDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inContact UIDAndServiceID]];
                }
//            }

        }else if([inModifiedKeys containsObject:@"IdleSince"]){ //Idle / UnIdle
            NSDate 	*idleSince = [[inContact statusArrayForKey:@"IdleSince"] earliestDate];
            
//            NSDate	*idleSince = [[inHandle statusDictionary] objectForKey:@"IdleSince"];
            NSNumber	*oldStatusNumber = [idleDict objectForKey:[inContact UIDAndServiceID]];
            BOOL	oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough
            BOOL	newStatus = (idleSince != nil);

            if(oldStatusNumber == nil || newStatus != oldStatus){
                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO)
                                                          object:inContact
                                                        userInfo:nil];
                [idleDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inContact UIDAndServiceID]];
            }
        }
    }

    return(nil);
}

- (void)clearOnlineFlags:(NSTimer *)inTimer
{
    AIListContact	*contact = [inTimer userInfo];

    [[contact statusArrayForKey:@"Signed On"] setObject:nil withOwner:contact];
    [[contact statusArrayForKey:@"Signed Off"] setObject:nil withOwner:contact];
    
    [[owner contactController] contactStatusChanged:contact modifiedStatusKeys:[NSArray arrayWithObjects:@"Signed On", @"Signed Off", nil]];
}

@end
