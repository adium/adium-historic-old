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

@interface AIContactIdlePlugin (PRIVATE)
- (void)setIdleForObject:(AIListObject *)inObject delayed:(BOOL)delayed silent:(BOOL)silent;
- (void)updateIdleObjectsTimer:(NSTimer *)inTimer;
@end

@implementation AIContactIdlePlugin


- (void)installPlugin
{
    //
    idleObjectArray = nil;

    //Install our tooltip entry
    [[owner interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];

    //
    [[owner contactController] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
    //Stop tracking all idle handles
    [idleObjectTimer invalidate]; [idleObjectTimer release]; idleObjectTimer = nil;
    [idleObjectArray release]; idleObjectArray = nil;
}

//Called when a handle's status changes
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    if(	inModifiedKeys == nil || [inModifiedKeys containsObject:@"IdleSince"]){

        if([[inObject statusArrayForKey:@"IdleSince"] earliestDate] != nil){
            //Track the handle
            if(!idleObjectArray){
                idleObjectArray = [[NSMutableArray alloc] init];
                idleObjectTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateIdleObjectsTimer:) userInfo:nil repeats:YES] retain];
            }
            [idleObjectArray addObject:inObject];

        }else{
            //Stop tracking the handle
            [idleObjectArray removeObject:inObject];
            if([idleObjectArray count] == 0){
                [idleObjectTimer invalidate]; [idleObjectTimer release]; idleObjectTimer = nil;
                [idleObjectArray release]; idleObjectArray = nil;
            }

        }

        //Set the correct idle value
        [self setIdleForObject:inObject delayed:delayed silent:silent];
    }

    return(nil);
}
        
//Updates the idle duration of all idle handles
- (void)updateIdleObjectsTimer:(NSTimer *)inTimer
{
    NSEnumerator	*enumerator;
    AIListObject	*object;

    enumerator = [idleObjectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        //should I really be muting here?  ?  (Does it matter either way?)
        [self setIdleForObject:object delayed:YES silent:YES]; //Update the contact's idle time
    }
}

//Give a contact its correct idle value
- (void)setIdleForObject:(AIListObject *)inObject delayed:(BOOL)delayed silent:(BOOL)silent
{
    NSDate	*idleSince = [[inObject statusArrayForKey:@"IdleSince"] earliestDate];
    
    if(idleSince){ //Set the handle's 'idle' value
        double	idle = -[idleSince timeIntervalSinceNow] / 60.0;
        [[inObject statusArrayForKey:@"Idle"] setObject:[NSNumber numberWithDouble:idle] withOwner:inObject];
        
    }else{ //Remove its idle value
        [[inObject statusArrayForKey:@"Idle"] setObject:nil withOwner:inObject];
    }

    //Let everyone know we changed it
    [[owner contactController] listObjectStatusChanged:inObject
                                    modifiedStatusKeys:[NSArray arrayWithObject:@"Idle"]
                                               delayed:delayed
                                                silent:silent];
}



//Tooltip entry ---------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    NSString	*entry = nil;
    
    if([inObject isKindOfClass:[AIListContact class]]){
        int idle = (int)[[(AIListContact *)inObject statusArrayForKey:@"Idle"] greatestDoubleValue];
        
        if(idle > 599400){ //Cap idle at 999 Hours (999*60*60 seconds)
            entry = @"Idle";
            
        }else if(idle != 0){
            entry = @"Idle Time";
        }
    }
    
    return(entry);
}

- (NSString *)entryForObject:(AIListObject *)inObject
{
    NSString	*entry = nil;

    if([inObject isKindOfClass:[AIListContact class]]){
        int idle = (int)[[(AIListContact *)inObject statusArrayForKey:@"Idle"] greatestDoubleValue];

        if(idle > 599400){ //Cap idle at 999 Hours (999*60*60 seconds)
            entry = @"Yes";
            
        }else if(idle != 0){
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
