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

#import "AIContactIdlePlugin.h"
#import <AIUtilities/AIUtilities.h>

@interface AIContactIdlePlugin (PRIVATE)
- (void)contact:(AIListContact *)inContact isIdle:(BOOL)inIdle;
- (void)setIdleForContact:(AIListContact *)inContact;
- (void)updateIdleContactsTimer:(NSTimer *)inTimer;
@end

@implementation AIContactIdlePlugin


- (void)installPlugin
{
    //
    idleContactArray = nil;

    //Install our tooltip entry
    [[owner interfaceController] registerContactListTooltipEntry:self];

    //
    [[owner contactController] registerContactObserver:self];
}

- (void)uninstallPlugin
{
    //Stop tracking all idle handles
    [idleContactTimer invalidate]; [idleContactTimer release]; idleContactTimer = nil;
    [idleContactArray release]; idleContactArray = nil;
}

//Called when a handle's status changes
- (NSArray *)updateContact:(AIListContact *)inContact keys:(NSArray *)inModifiedKeys
{
    if(	inModifiedKeys == nil ||
        [inModifiedKeys containsObject:@"IdleSince"]){
        
        //Start/Stop tracking the handle
        [self contact:inContact isIdle:([[inContact statusArrayForKey:@"IdleSince"] earliestDate] != nil)];
    }

    return(nil);
}
        
        
//Adds or removes a handle from our idle tracking array
//Handles in the array have their idle times increased every minute
- (void)contact:(AIListContact *)inContact isIdle:(BOOL)inIdle
{
    if(inIdle){
        //Track the handle
        if(!idleContactArray){
            idleContactArray = [[NSMutableArray alloc] init];
            idleContactTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateIdleContactsTimer:) userInfo:nil repeats:YES] retain];
        }
        [idleContactArray addObject:inContact];
        
    }else{
        //Stop tracking the handle
        [idleContactArray removeObject:inContact];
        if([idleContactArray count] == 0){
            [idleContactTimer invalidate]; [idleContactTimer release]; idleContactTimer = nil;
            [idleContactArray release]; idleContactArray = nil;
        }

    }

    //Set the correct idle value
    [self setIdleForContact:inContact];

}

//Updates the idle duration of all idle handles
- (void)updateIdleContactsTimer:(NSTimer *)inTimer
{
    NSEnumerator	*enumerator;
    AIListContact	*contact;

    [[owner contactController] setHoldContactListUpdates:YES]; //Hold updates to prevent multiple updates and re-sorts

    enumerator = [idleContactArray objectEnumerator];
    while((contact = [enumerator nextObject])){
        [self setIdleForContact:contact]; //Update the contact's idle time
    }

    [[owner contactController] setHoldContactListUpdates:NO]; //Resume updates
}

//Give a contact its correct idle value
- (void)setIdleForContact:(AIListContact *)inContact
{
    NSDate		*idleSince = [[inContact statusArrayForKey:@"IdleSince"] earliestDate];
    
//    NSMutableDictionary	*statusDict = [inHandle statusDictionary];
//    NSDate		*idleSince = [statusDict objectForKey:@"IdleSince"];

    if(idleSince){ //Set the handle's 'idle' value
        double	idle = -[idleSince timeIntervalSinceNow] / 60.0;
        [[inContact statusArrayForKey:@"Idle"] setObject:[NSNumber numberWithDouble:idle] withOwner:inContact];
        
    }else{ //Remove its idle value
        [[inContact statusArrayForKey:@"Idle"] setObject:nil withOwner:inContact];
    }

    //Let everyone know we changed it
    [[owner contactController] contactStatusChanged:inContact
                                modifiedStatusKeys:[NSArray arrayWithObject:@"Idle"]];
}



//Tooltip entry ---------------------------------------------------------------------------------
- (NSString *)label
{
    return(@"Idle");
}

- (NSString *)entryForObject:(AIListObject *)inObject
{
    NSString	*entry = nil;

    if([inObject isKindOfClass:[AIListContact class]]){
        int idle = (int)[[(AIListContact *)inObject statusArrayForKey:@"Idle"] greatestDoubleValue];

        if(idle != 0){
            int	hours = (int)(idle / 60);
            int	minutes = (int)(idle % 60);

            if(hours){
                entry = [NSString stringWithFormat:@"%i hour%@, %i minute%@", hours, (hours == 1 ? @"": @"s"), minutes, (minutes == 1 ? @"": @"s")];
            }else{
                entry = [NSString stringWithFormat:@"%i minute%@", minutes, (minutes == 1 ? @"": @"s")];
            }
        }
    }

    return(entry);
}


@end
