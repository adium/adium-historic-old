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
- (void)handle:(AIHandle *)inHandle isIdle:(BOOL)inIdle;
- (void)updateIdleHandlesTimer:(NSTimer *)inTimer;
- (void)setIdleForHandle:(AIHandle *)inHandle;
@end

@implementation AIContactIdlePlugin


- (void)installPlugin
{
    //
    idleHandleArray = nil;

    //Install our tooltip entry
    [[owner interfaceController] registerContactListTooltipEntry:self];

    //
    [[owner contactController] registerContactObserver:self];
}

- (void)uninstallPlugin
{
    //Stop tracking all idle handles
    [idleHandleTimer invalidate]; [idleHandleTimer release]; idleHandleTimer = nil;
    [idleHandleArray release]; idleHandleArray = nil;
}

//Called when a handle's status changes
- (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    if(	inModifiedKeys == nil ||
        [inModifiedKeys containsObject:@"IdleSince"]){

        //Start/Stop tracking the handle
        [self handle:inHandle isIdle:([[inHandle statusDictionary] objectForKey:@"IdleSince"] != nil)];
    }

    return(nil);
}
        
        
//Adds or removes a handle from our idle tracking array
//Handles in the array have their idle times increased every minute
- (void)handle:(AIHandle *)inHandle isIdle:(BOOL)inIdle
{
    if(inIdle){
        //Track the handle
        if(!idleHandleArray){
            idleHandleArray = [[NSMutableArray alloc] init];
            idleHandleTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateIdleHandlesTimer:) userInfo:nil repeats:YES] retain];
        }
        [idleHandleArray addObject:inHandle];
        
    }else{
        //Stop tracking the handle
        [idleHandleArray removeObject:inHandle];
        if([idleHandleArray count] == 0){
            [idleHandleTimer invalidate]; [idleHandleTimer release]; idleHandleTimer = nil;
            [idleHandleArray release]; idleHandleArray = nil;
        }

    }

    //Set the correct idle value
    [self setIdleForHandle:inHandle];

}

//Updates the idle duration of all idle handles
- (void)updateIdleHandlesTimer:(NSTimer *)inTimer
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;

    [[owner contactController] setHoldContactListUpdates:YES]; //Hold updates to prevent multiple updates and re-sorts

    enumerator = [idleHandleArray objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self setIdleForHandle:handle]; //Update the handle's idle time
    }

    [[owner contactController] setHoldContactListUpdates:NO]; //Resume updates
}

//Give a handle its correct idle value
- (void)setIdleForHandle:(AIHandle *)inHandle
{
    NSMutableDictionary	*statusDict = [inHandle statusDictionary];
    NSDate		*idleSince = [statusDict objectForKey:@"IdleSince"];

    if(idleSince){ //Set the handle's 'idle' value
        double	idle = -[idleSince timeIntervalSinceNow] / 60.0;
        [statusDict setObject:[NSNumber numberWithDouble:idle] forKey:@"Idle"];

    }else{ //Remove its idle value
        [statusDict removeObjectForKey:@"Idle"];
    }

    //Let everyone know we changed it
    [[owner contactController] handleStatusChanged:inHandle
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
