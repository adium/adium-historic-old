/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIStatusCirclesPlugin.h"
#import "AIStatusCircle.h"
#import "AIAdium.h"

@implementation AIStatusCirclesPlugin

- (void)installPlugin
{
    //Create the status circles
    circleAway = [[AIStatusCircle statusCircleWithColor:[NSColor colorWithCalibratedRed:(229.0/255.0) green:(229.0/255.0) blue:(102.0/255.0) alpha:1.0]] retain];
    circleIdle = [[AIStatusCircle statusCircleWithColor:[NSColor colorWithCalibratedRed:(204.0/255.0) green:(204.0/255.0) blue:(204.0/255.0) alpha:1.0]] retain];
    circleIdleAway = [[AIStatusCircle statusCircleWithColor:[NSColor colorWithCalibratedRed:(229.0/255.0) green:(229.0/255.0) blue:(153.0/255.0) alpha:1.0]] retain];
    circleOffline = [[AIStatusCircle statusCircleWithColor:[NSColor colorWithCalibratedRed:(178.0/255.0) green:(0.0/255.0) blue:(0.0/255.0) alpha:1.0]] retain];
    circleEmpty = [[AIStatusCircle statusCircleWithColor:[NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:1.0]] retain];

    [[owner contactController] registerHandleObserver:self];
}

- (void)dealloc
{
    [circleAway release];
    [circleIdle release];
    [circleIdleAway release];
    [circleOffline release];
    [circleEmpty release];

    [super dealloc];
}

- (BOOL)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    BOOL	handleChanged = NO;

    if(	inModifiedKeys == nil || 
        [inModifiedKeys containsObject:@"Away"] || 
        [inModifiedKeys containsObject:@"Idle"] || 
        [inModifiedKeys containsObject:@"Warning"] ||
        [inModifiedKeys containsObject:@"Online"]){

        AIMutableOwnerArray	*iconArray = [inHandle displayArrayForKey:@"Left View"];
        int			away, idle, warning, online;

        //Get all the values
        away = [[inHandle statusArrayForKey:@"Away"] greatestIntegerValue];
        idle = [[inHandle statusArrayForKey:@"Idle"] greatestIntegerValue];
        warning = [[inHandle statusArrayForKey:@"Warning"] greatestIntegerValue];
        online = [[inHandle statusArrayForKey:@"Online"] greatestIntegerValue];

        //Remove our current ailments
        [iconArray removeObjectsWithOwner:self];

        if(!online){
            [iconArray addObject:circleOffline withOwner:self];
        }else if(idle && away){
            [iconArray addObject:circleIdleAway withOwner:self];
        }else if(idle){
            [iconArray addObject:circleIdle withOwner:self];
        }else if(away){
            [iconArray addObject:circleAway withOwner:self];
        }else{
            [iconArray addObject:circleEmpty withOwner:self];
        }
 
        handleChanged = YES;
    }

    return(handleChanged);
}

@end
