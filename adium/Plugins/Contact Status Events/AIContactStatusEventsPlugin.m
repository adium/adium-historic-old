//
//  AIContactStatusEventsPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Feb 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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

- (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    //To increase the speed of heavy contact list operations (connecting/disconnecting/etc), we don't sent out any events when the contact list updates are delayed.
    if(![[owner contactController] holdContactListUpdates]){
        
        if([inModifiedKeys containsObject:@"Online"]){ //Sign on/off
            NSNumber	*online = [[inHandle statusDictionary] objectForKey:@"Online"];

            if(online){ //We only send out events if the handle has a value (nil values mean the flag is being cleared)
                BOOL	oldStatus = [[onlineDict objectForKey:[inHandle UID]] boolValue]; //! UID is not unique enough !
                BOOL	newStatus = [online boolValue];

                if(newStatus != oldStatus){
                    //Post an online/offline notification
                    [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO)
                                                              object:inHandle
                                                            userInfo:nil];
                    [onlineDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inContact UID]];

                    //Clear any existing juston/just off values
                    [[inHandle statusDictionary] removeObjectForKey:@"Signed On"];
                    [[inHandle statusDictionary] removeObjectForKey:@"Signed Off"];

                    //Set status flags and install timers for "Just signed on" and "Just signed off"
                    [[inHandle statusDictionary] setObject:[NSNumber numberWithBool:YES] forKey:(newStatus ? @"Signed On" : @"Signed Off")];
                    [[owner contactController] handleStatusChanged:inHandle
                                                modifiedStatusKeys:[NSArray arrayWithObjects:@"Signed On",@"Signed Off",nil]];

                    [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(clearOnlineFlags:) userInfo:inHandle repeats:NO];
                }
            }
            
        }else if([inModifiedKeys containsObject:@"Away"]){ //Away / Unaway
            NSNumber	*away = [[inHandle statusDictionary] objectForKey:@"Away"];

            if(away){ //We only send out events if the handle has a value (nil values mean the flag is being cleared)
                BOOL	oldStatus = [[awayDict objectForKey:[inHandle UID]] boolValue]; //! UID is not unique enough !
                BOOL	newStatus = [away boolValue];

                if(newStatus != oldStatus){
                    [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO)
                                                              object:inHandle
                                                            userInfo:nil];
                    [awayDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inHandle UID]];
                }
            }
            
        }else if([inModifiedKeys containsObject:@"Idle"]){ //Idle / UnIdle
            NSNumber	*idle = [[inHandle statusDictionary] objectForKey:@"Idle"];

            if(idle){ //We only send out events if the handle has a value (nil values mean the flag is being cleared)
                BOOL	oldStatus = [[idleDict objectForKey:[inHandle UID]] boolValue]; //! UID is not unique enough !
                BOOL	newStatus = ([idle doubleValue] != 0);
    
                if(newStatus != oldStatus){
                    [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO)
                                                            object:inHandle
                                                            userInfo:nil];
                    [idleDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inHandle UID]];
                }
            }
        }            

    }

    return(nil);
}

- (void)clearOnlineFlags:(NSTimer *)inTimer
{
    AIHandle		*handle = [inTimer userInfo];

    [[handle statusDictionary] removeObjectForKey:@"Signed On"];
    [[handle statusDictionary] removeObjectForKey:@"Signed Off"];

    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObjects:@"Signed On", @"Signed Off", nil]];
}

@end
