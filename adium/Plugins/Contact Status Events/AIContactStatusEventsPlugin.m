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
    [[owner contactController] registerHandleObserver:self];

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

- (NSArray *)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    //To increase the speed of heavy contact list operations (connecting/disconnecting/etc), we don't sent out any events when the contact list updates are delayed.
    if(![[owner contactController] contactListUpdatesDelayed]){
        
        if([inModifiedKeys containsObject:@"Online"]){ //Sign on/off
            BOOL	oldStatus = [[onlineDict objectForKey:[inHandle UID]] boolValue]; //! UID is not unique enough !
            BOOL	newStatus = [[inHandle statusArrayForKey:@"Online"] containsAnyIntegerValueOf:1];

            if(newStatus != oldStatus){
                AIMutableOwnerArray	*ownerArray;

                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO)
                                                          object:inHandle
                                                        userInfo:nil];
                [onlineDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inHandle UID]];

                //Set status flags and install timers for "Just signed on" and "Just signed off"
                ownerArray = [inHandle statusArrayForKey:(newStatus ? @"Signed On" : @"Signed Off")];
                [ownerArray removeObjectsWithOwner:self];
                [ownerArray addObject:[NSNumber numberWithBool:YES] withOwner:self];
                [[owner contactController] handleStatusChanged:inHandle
                                            modifiedStatusKeys:[NSArray arrayWithObject:(newStatus ? @"Signed On" : @"Signed Off")]];

                [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(clearOnlineFlags:) userInfo:inHandle repeats:NO];
            }

        }else if([inModifiedKeys containsObject:@"Away"]){ //Away / Unaway
            BOOL	oldStatus = [[awayDict objectForKey:[inHandle UID]] boolValue]; //! UID is not unique enough !
            BOOL	newStatus = [[inHandle statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1];

            if(newStatus != oldStatus){
                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO)
                                                          object:inHandle
                                                        userInfo:nil];
                [awayDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inHandle UID]];
            }            
            
        }else if([inModifiedKeys containsObject:@"Idle"]){ //Idle / UnIdle
            BOOL	oldStatus = [[idleDict objectForKey:[inHandle UID]] boolValue]; //! UID is not unique enough !
            BOOL	newStatus = ([[inHandle statusArrayForKey:@"Idle"] greatestDoubleValue] != 0);

            if(newStatus != oldStatus){
                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO)
                                                          object:inHandle
                                                        userInfo:nil];
                [idleDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inHandle UID]];
            }

        }            

    }

    return(nil);
}

- (void)clearOnlineFlags:(NSTimer *)inTimer
{
    AIContactHandle	*handle = [inTimer userInfo];

    [[handle statusArrayForKey:@"Signed On"] removeObjectsWithOwner:self];
    [[handle statusArrayForKey:@"Signed Off"] removeObjectsWithOwner:self];

    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:[NSArray arrayWithObjects:@"Signed On", @"Signed Off", nil]];
}

@end
