/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactController.h"
#import "AIContactIdlePlugin.h"
#import "AIInterfaceController.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <Adium/AIListObject.h>

#define IDLE_UPDATE_INTERVAL	60.0

@interface AIContactIdlePlugin (PRIVATE)
- (void)setIdleForObject:(AIListObject *)inObject silent:(BOOL)silent;
- (void)updateIdleObjectsTimer:(NSTimer *)inTimer;
@end

@implementation AIContactIdlePlugin

DeclareString(IdleSince);
DeclareString(Idle);

- (void)installPlugin
{
	InitString(IdleSince,@"IdleSince");
	InitString(Idle,@"Idle");
	
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

	ReleaseString(IdleSince);
	ReleaseString(Idle);
}

//Called when a handle's status changes
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if(	inModifiedKeys == nil || [inModifiedKeys containsObject:IdleSince]){

        if([inObject statusObjectForKey:IdleSince] != nil){
            //Track the handle
            if(!idleObjectArray){
                idleObjectArray = [[NSMutableArray alloc] init];
                idleObjectTimer = [[NSTimer scheduledTimerWithTimeInterval:IDLE_UPDATE_INTERVAL
																	target:self 
																  selector:@selector(updateIdleObjectsTimer:)
																  userInfo:nil 
																   repeats:YES] retain];
            }
            [idleObjectArray addObject:inObject];
			
			//Set the correct idle value
			[self setIdleForObject:inObject silent:silent];

        }else{
			if ([idleObjectArray containsObjectIdenticalTo:inObject]){
				//Stop tracking the handle
				[idleObjectArray removeObject:inObject];
				if([idleObjectArray count] == 0){
					[idleObjectTimer invalidate]; [idleObjectTimer release]; idleObjectTimer = nil;
					[idleObjectArray release]; idleObjectArray = nil;
				}
				
				//Set the correct idle value
				[self setIdleForObject:inObject silent:silent];
			}
        }
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
	//of course, smart sorting controllers should be watching IdleSince, not Idle, since that's the important bit
	[[adium contactController] delayListObjectNotifications];

	//Update everyone's idle time
    enumerator = [idleObjectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        [self setIdleForObject:object silent:YES];
    }
	
	[[adium contactController] endListObjectNotificationsDelay];
}

//Give a contact its correct idle value
- (void)setIdleForObject:(AIListObject *)inObject silent:(BOOL)silent
{
    NSDate	*idleSince = [inObject statusObjectForKey:IdleSince];

    if(idleSince){ //Set the handle's 'idle' value
        int	idle = -[idleSince timeIntervalSinceNow] / 60.0;
		
		/* They are idle; a non-zero idle time is needed.  We'll treat them as generically idle until this updates */
		if (idle == 0){
			idle = -1;
		}

		[inObject setStatusObject:[NSNumber numberWithInt:idle]
						   forKey:Idle
						   notify:NO];
        
    }else{ //Remove its idle value
		[inObject setStatusObject:nil
						   forKey:Idle
						   notify:NO];
    }

	//Apply the change
	[inObject notifyOfChangedStatusSilently:silent];
}


//Tooltip entry ---------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    int 		idle = [inObject integerStatusObjectForKey:Idle];
    NSString	*entry = nil;

    if((idle > 599400) || (idle == -1)){ //Cap idle at 999 Hours (999*60*60 seconds)
		entry = @"Idle";
    }else if(idle != 0){
		entry = @"Idle Time";
    }

    return(entry);
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    int 				idle = [inObject integerStatusObjectForKey:Idle];
    NSAttributedString	*entry = nil;
	
    if((idle > 599400) || (idle == -1)){ //Cap idle at 999 Hours (999*60*60 seconds)
		entry = [[NSAttributedString alloc] initWithString:@"Yes"];
		
    }else if(idle != 0){
		int	hours = (int)(idle / 60);
		int	minutes = (int)((int)idle % 60);
		
		if(hours){
			entry = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i hour%@, %i minute%@", hours, (hours == 1 ? @"": @"s"), minutes, (minutes == 1 ? @"": @"s")]];
		}else{
			entry = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i minute%@", minutes, (minutes == 1 ? @"": @"s")]];
		}
    }
	
    return([entry autorelease]);
}

@end
