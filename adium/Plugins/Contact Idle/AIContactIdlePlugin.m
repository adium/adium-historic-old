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
- (void)setIdleForObject:(AIListObject *)inObject silent:(BOOL)silent;
- (void)updateIdleObjectsTimer:(NSTimer *)inTimer;
@end

@implementation AIContactIdlePlugin

- (void)installPlugin
{
    //
    idleObjectArray = nil;

    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];

    //
    [[adium contactController] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
    //Stop tracking all idle handles
    [idleObjectTimer invalidate]; [idleObjectTimer release]; idleObjectTimer = nil;
    [idleObjectArray release]; idleObjectArray = nil;
}

//Called when a handle's status changes
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if(	inModifiedKeys == nil || [inModifiedKeys containsObject:@"IdleSince"]){

        if([[inObject statusArrayForKey:@"IdleSince"] objectValue] != nil){
            //Track the handle
            if(!idleObjectArray){
                idleObjectArray = [[NSMutableArray alloc] init];
                idleObjectTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0 
																	target:self 
																  selector:@selector(updateIdleObjectsTimer:)
																  userInfo:nil 
																   repeats:YES] retain];
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
        [self setIdleForObject:inObject silent:silent];
    }

    return(nil);
}
        
//Updates the idle duration of all idle handles
- (void)updateIdleObjectsTimer:(NSTimer *)inTimer
{
    NSEnumerator	*enumerator;
    AIListObject	*object;

	//There's actually no reason to re-sort in response to these status changes, but there is no way for us to
	//let the Adium core know that.  The best we can do is delay updates so only a single sort occurs
	[[adium contactController] delayListObjectNotifications];

	//Update everyone's idle time
    enumerator = [idleObjectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        [self setIdleForObject:object silent:YES];
    }
	
}

//Give a contact its correct idle value
- (void)setIdleForObject:(AIListObject *)inObject silent:(BOOL)silent
{
    NSDate	*idleSince = [[inObject statusArrayForKey:@"IdleSince"] objectValue];
    
    if(idleSince){ //Set the handle's 'idle' value
        double	idle = -[idleSince timeIntervalSinceNow] / 60.0;
		[inObject setStatusObject:[NSNumber numberWithDouble:idle]
						   forKey:@"Idle"
						   notify:NO];
        
    }else{ //Remove its idle value
		[inObject setStatusObject:nil
						   forKey:@"Idle"
						   notify:NO];
    }

	//Apply the change
	[inObject notifyOfChangedStatusSilently:silent];
}


//Tooltip entry ---------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    int 	idle = (int)[[inObject statusArrayForKey:@"Idle"] doubleValue];
    NSString	*entry = nil;
	
    if(idle > 599400){ //Cap idle at 999 Hours (999*60*60 seconds)
		entry = @"Idle";
    }else if(idle != 0){
		entry = @"Idle Time";
    }
    
    return(entry);
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    int 		idle = (int)[[inObject statusArrayForKey:@"Idle"] doubleValue];
    NSAttributedString	*entry = nil;
	
    if(idle > 599400){ //Cap idle at 999 Hours (999*60*60 seconds)
		entry = [[NSAttributedString alloc] initWithString:@"Yes"];
		
    }else if(idle != 0){
		int	hours = (int)(idle / 60);
		int	minutes = (int)(idle % 60);
		
		if(hours){
			entry = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i hour%@, %i minute%@", hours, (hours == 1 ? @"": @"s"), minutes, (minutes == 1 ? @"": @"s")]];
		}else{
			entry = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i minute%@", minutes, (minutes == 1 ? @"": @"s")]];
		}
    }
	
    return([entry autorelease]);
}

@end
