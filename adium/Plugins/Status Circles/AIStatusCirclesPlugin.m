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
    [[owner contactController] registerHandleObserver:self];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (void)dealloc
{
    [super dealloc];
}

- (NSArray *)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    NSArray		*modifiedAttributes = nil;
    
    if(	inModifiedKeys == nil || 
        [inModifiedKeys containsObject:@"Away"] || 
        [inModifiedKeys containsObject:@"Idle"] || 
        [inModifiedKeys containsObject:@"Warning"] ||
        [inModifiedKeys containsObject:@"Online"] ||
        [inModifiedKeys containsObject:@"UnviewedContent"] ||
        [inModifiedKeys containsObject:@"UnrespondedContent"]){

        AIStatusCircle		*statusCircle;
        NSColor			*circleColor;
        AIMutableOwnerArray	*iconArray = [inHandle displayArrayForKey:@"Left View"];
        int			away, idle, warning, online;
        int			unviewedContent, unrespondedContent;

        //Get all the values
        away = [[inHandle statusArrayForKey:@"Away"] greatestIntegerValue];
        idle = [[inHandle statusArrayForKey:@"Idle"] greatestIntegerValue];
        warning = [[inHandle statusArrayForKey:@"Warning"] greatestIntegerValue];
        online = [[inHandle statusArrayForKey:@"Online"] greatestIntegerValue];
        unviewedContent = [[inHandle statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
        unrespondedContent = [[inHandle statusArrayForKey:@"UnrespondedContent"] greatestIntegerValue];
        
        //Remove our current ailments
        [iconArray removeObjectsWithOwner:self];

        //Get the circle color
        if(unviewedContent){
            circleColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(178.0/255.0) blue:(0.0/255.0) alpha:1.0];
        }else if(!online){
            circleColor = [NSColor colorWithCalibratedRed:(178.0/255.0) green:(0.0/255.0) blue:(0.0/255.0) alpha:1.0];
        }else if(idle && away){
            circleColor = [NSColor colorWithCalibratedRed:(229.0/255.0) green:(229.0/255.0) blue:(153.0/255.0) alpha:1.0];
        }else if(idle){
            circleColor = [NSColor colorWithCalibratedRed:(204.0/255.0) green:(204.0/255.0) blue:(204.0/255.0) alpha:1.0];
        }else if(away){
            circleColor = [NSColor colorWithCalibratedRed:(229.0/255.0) green:(229.0/255.0) blue:(102.0/255.0) alpha:1.0];
        }else{
            circleColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:1.0];
        }
        
        //Create and set the circle
        statusCircle = [AIStatusCircle statusCircleWithColor:circleColor
                                                         dot:(BOOL)unrespondedContent];
        [iconArray addObject:statusCircle withOwner:self];
        modifiedAttributes = [NSArray arrayWithObject:@"Left View"];
    }

    return(modifiedAttributes);
}

@end
