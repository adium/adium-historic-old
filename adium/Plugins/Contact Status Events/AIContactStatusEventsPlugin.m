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
#define CONTACT_STATUS_TYPING_YES	@"Contact_StatusTypingYes"
#define CONTACT_STATUS_TYPING_NO	@"Contact_StatusTypingNo"

//Generates events when a contact changes status, so other plugins may respond to them.  This plugin correctly handles multiple accounts, so a contact changing status on n accounts will only ever generate 1 event.

@implementation AIContactStatusEventsPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactObserver:self];

    onlineDict = [[NSMutableDictionary alloc] init];
    awayDict = [[NSMutableDictionary alloc] init];
    idleDict = [[NSMutableDictionary alloc] init];
    typingDict = [[NSMutableDictionary alloc] init];

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

- (NSArray *)updateContact:(AIListContact *)inContact keys:(NSArray *)inModifiedKeys
{
    int		timeInterval = 15;//time interval that the status should remain
    
    //To increase the speed of heavy contact list operations (connecting/disconnecting/etc), we don't sent out any events when the contact list updates are delayed.
    if(![[owner contactController] holdContactListUpdates]){        
        if([inModifiedKeys containsObject:@"Online"]){ //Sign on/off
            BOOL	newStatus = [[inContact statusArrayForKey:@"Online"] greatestIntegerValue];
            NSNumber	*oldStatusNumber = [onlineDict objectForKey:[inContact UIDAndServiceID]];
            BOOL	oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough

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

		if(newStatus){
		    timeInterval = signedOnLength;
		    
		}else{
		    timeInterval = signedOffLength;
		    
		}

                if(timeInterval >= 0){
		    [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(clearOnlineFlags:) userInfo:inContact repeats:NO];
		}
            }
        }

        if([inModifiedKeys containsObject:@"Away"]){ //Away / Unaway
            BOOL 	newStatus = [[inContact statusArrayForKey:@"Away"] greatestIntegerValue];
            NSNumber	*oldStatusNumber = [awayDict objectForKey:[inContact UIDAndServiceID]];
            BOOL	oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough

            if(oldStatusNumber == nil || newStatus != oldStatus){
                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO)
                                                          object:inContact
                                                        userInfo:nil];
                [awayDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inContact UIDAndServiceID]];
            }
        }

        if([inModifiedKeys containsObject:@"IdleSince"]){ //Idle / UnIdle
            NSDate 	*idleSince = [[inContact statusArrayForKey:@"IdleSince"] earliestDate];
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

        if([inModifiedKeys containsObject:@"Typing"]){ //Typing / Not Typing
            BOOL 	newStatus = [[inContact statusArrayForKey:@"Typing"] greatestIntegerValue];
            NSNumber	*oldStatusNumber = [typingDict objectForKey:[inContact UIDAndServiceID]];
            BOOL	oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough

            if(oldStatusNumber == nil || newStatus != oldStatus){
                [[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_TYPING_YES : CONTACT_STATUS_TYPING_NO)
                                                          object:inContact
                                                        userInfo:nil];
		[typingDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inContact UIDAndServiceID]];

		timeInterval = typingLength;

                if(timeInterval >= 0){
		    [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(clearTypingFlags:) userInfo:inContact repeats:NO];
		}
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

- (void)clearTypingFlags:(NSTimer *)inTimer
{
    AIListContact	*contact = [inTimer userInfo];

    [[contact statusArrayForKey:@"Typing"] setObject:nil withOwner:contact];

    [[owner contactController] contactStatusChanged:contact modifiedStatusKeys:[NSArray arrayWithObjects:@"Typing", nil]];
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
	typingLength = [[prefDict objectForKey:KEY_TYPING_LENGTH] intValue];
    }
}

@end
