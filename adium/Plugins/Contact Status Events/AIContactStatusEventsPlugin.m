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
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIContactStatusEventsPlugin.h"
#import "AIContactStatusEventsPreferences.h"

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
    [[owner contactController] registerListObjectObserver:self];

    onlineDict = [[NSMutableDictionary alloc] init];
    awayDict = [[NSMutableDictionary alloc] init];
    idleDict = [[NSMutableDictionary alloc] init];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_EVENTS_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_STATUS_EVENTS];
    [self preferencesChanged:nil];

    //Our preference view
    preferences = [[AIContactStatusEventsPreferences contactStatusEventsPreferencesWithOwner:owner] retain];

    [owner registerEventNotification:CONTACT_STATUS_ONLINE_YES displayName:@"Contact Signed On"];
    [owner registerEventNotification:CONTACT_STATUS_ONLINE_NO displayName:@"Contact Signed Off"];
    [owner registerEventNotification:CONTACT_STATUS_AWAY_YES displayName:@"Contact Away"];
    [owner registerEventNotification:CONTACT_STATUS_AWAY_NO displayName:@"Contact UnAway"];
    [owner registerEventNotification:CONTACT_STATUS_IDLE_YES displayName:@"Contact Idle"];
    [owner registerEventNotification:CONTACT_STATUS_IDLE_NO displayName:@"Contact UnIdle"];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
    //remove observers
}

- (void)dealloc
{
    [super dealloc];
}

//To increase the speed of heavy contact list operations (connecting/disconnecting/etc), we don't sent out any events when the contact list updates are delayed.
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    int		timeInterval = 15;//time interval that the status should remain

    if([inModifiedKeys containsObject:@"Online"]){ //Sign on/off
        BOOL	newStatus = [[inObject statusArrayForKey:@"Online"] greatestIntegerValue];
        NSNumber	*oldStatusNumber = [onlineDict objectForKey:[inObject UIDAndServiceID]];
        BOOL	oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough

       // NSLog(@"%@ Online changed from %i to %i (Holding Updates: %i)",[inObject displayName],oldStatus,newStatus,[[owner contactController] holdContactListUpdates]);

        if(oldStatusNumber == nil || newStatus != oldStatus){
            //Save the new status
            [onlineDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inObject UIDAndServiceID]];

            //Take action (If this update isn't silent)
            if(!silent){
                AIMutableOwnerArray	*signedOnArray = [inObject statusArrayForKey:@"Signed On"];
                AIMutableOwnerArray	*signedOffArray = [inObject statusArrayForKey:@"Signed Off"];

                //Post an online/offline notification
                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO) object:inObject userInfo:nil];

                //Clear any existing juston/just off values
                [signedOnArray setObject:nil withOwner:inObject];
                [signedOffArray setObject:nil withOwner:inObject];

                //Set status flags and install timers for "Just signed on" and "Just signed off"
                [(newStatus ? signedOnArray : signedOffArray) setObject:[NSNumber numberWithBool:YES] withOwner:inObject];
                [[owner contactController] listObjectStatusChanged:inObject
                                                modifiedStatusKeys:[NSArray arrayWithObjects:@"Signed On",@"Signed Off",nil]
                                                           delayed:delayed
                                                            silent:silent];

                timeInterval = (newStatus ? signedOnLength : signedOffLength);
                if(timeInterval >= 0){
                    [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(clearOnlineFlags:) userInfo:inObject repeats:NO];
                }
                
            }
        }
    }

    if([inModifiedKeys containsObject:@"Away"]){ //Away / Unaway
        BOOL 	newStatus = [[inObject statusArrayForKey:@"Away"] greatestIntegerValue];
        NSNumber	*oldStatusNumber = [awayDict objectForKey:[inObject UIDAndServiceID]];
        BOOL	oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough

        if(oldStatusNumber == nil || newStatus != oldStatus){
            //Save the new state
            [awayDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inObject UIDAndServiceID]];

            //Take action (If this update isn't silent)
            if(!silent){
                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO) object:inObject userInfo:nil];
            }
            
        }
    }

    if([inModifiedKeys containsObject:@"IdleSince"]){ //Idle / UnIdle
        NSDate 	*idleSince = [[inObject statusArrayForKey:@"IdleSince"] earliestDate];
        NSNumber	*oldStatusNumber = [idleDict objectForKey:[inObject UIDAndServiceID]];
        BOOL	oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough
        BOOL	newStatus = (idleSince != nil);

        if(oldStatusNumber == nil || newStatus != oldStatus){
            //Save the new state
            [idleDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inObject UIDAndServiceID]];

            //Take action (If this update isn't silent)
            if(!silent){
                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO) object:inObject userInfo:nil];
            }
            
        }
    }

    return(nil);
}

- (void)clearOnlineFlags:(NSTimer *)inTimer
{
    AIListObject	*object = [inTimer userInfo];

    [[object statusArrayForKey:@"Signed On"] setObject:nil withOwner:object];
    [[object statusArrayForKey:@"Signed Off"] setObject:nil withOwner:object];

    [[owner contactController] listObjectStatusChanged:object modifiedStatusKeys:[NSArray arrayWithObjects:@"Signed On", @"Signed Off", nil] delayed:NO silent:NO];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    //Optimize this...
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_STATUS_EVENTS] == 0){
	NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_STATUS_EVENTS];

	//Release the old values..
	//Cache the preference values
	signedOffLength = [[prefDict objectForKey:KEY_SIGNED_OFF_LENGTH] intValue];
	signedOnLength = [[prefDict objectForKey:KEY_SIGNED_ON_LENGTH] intValue];
    }
}

@end
