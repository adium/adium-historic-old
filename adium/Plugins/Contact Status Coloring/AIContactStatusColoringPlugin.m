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
#import "AIContactStatusColoringPlugin.h"
#import "AIAdium.h"

@implementation AIContactStatusColoringPlugin

- (void)installPlugin
{
    [[owner contactController] registerHandleObserver:self];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (NSArray *)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    NSArray		*modifiedAttributes = nil;

    if(	inModifiedKeys == nil || 
        [inModifiedKeys containsObject:@"Away"] || 
        [inModifiedKeys containsObject:@"Idle"] || 
        [inModifiedKeys containsObject:@"Warning"] ||
        [inModifiedKeys containsObject:@"Online"]){

        AIMutableOwnerArray	*colorArray = [inHandle displayArrayForKey:@"Text Color"];
        int			away, idle, warning, online;

        //Get all the values
        away = [[inHandle statusArrayForKey:@"Away"] greatestIntegerValue];
        idle = [[inHandle statusArrayForKey:@"Idle"] greatestIntegerValue];
        warning = [[inHandle statusArrayForKey:@"Warning"] greatestIntegerValue];
        online = [[inHandle statusArrayForKey:@"Online"] greatestIntegerValue];

        //Remove our current ailments
        [colorArray removeObjectsWithOwner:self];

        if(!online){
            [colorArray addObject:[NSColor colorWithCalibratedRed:(68.0/255.0) green:(0.0/255.0) blue:(1.0/255.0) alpha:1.0] withOwner:self];
        }else if(idle && away){
            [colorArray addObject:[NSColor colorWithCalibratedRed:(89.0/255.0) green:(89.0/255.0) blue:(59.0/255.0) alpha:1.0] withOwner:self];            
        }else if(idle){
            [colorArray addObject:[NSColor colorWithCalibratedRed:(67.0/255.0) green:(67.0/255.0) blue:(67.0/255.0) alpha:1.0] withOwner:self];
        }else if(away){
            [colorArray addObject:[NSColor colorWithCalibratedRed:(66.0/255.0) green:(66.0/255.0) blue:(0.0/255.0) alpha:1.0] withOwner:self];
        }

        modifiedAttributes = [NSArray arrayWithObject:@"Text Color"];
    }

    return(modifiedAttributes);

}

@end
