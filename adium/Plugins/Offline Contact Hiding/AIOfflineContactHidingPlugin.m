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
#import "AIOfflineContactHidingPlugin.h"
#import "AIAdium.h"

@implementation AIOfflineContactHidingPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactObserver:self];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    NSArray		*modifiedAttributes = nil;
    
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"Online"] || [inModifiedKeys containsObject:@"Signed Off"]){
        AIMutableOwnerArray	*hiddenArray = [inContact displayArrayForKey:@"Hidden"];
        int			online = [[inContact statusArrayForKey:@"Online"] greatestIntegerValue];
        int			justSignedOff = [[inContact statusArrayForKey:@"Signed Off"] containsAnyIntegerValueOf:1];
        
        //Insert an updated value
        if(!online && !justSignedOff){
            [hiddenArray setObject:[NSNumber numberWithInt:YES] withOwner:self]; //Hidden
        }else{
            [hiddenArray setObject:nil withOwner:self]; //Remove any 'hidden' value we've previously inserted
        }

        modifiedAttributes = [NSArray arrayWithObject:@"Hidden"];
    }

    return(modifiedAttributes);
}

@end
