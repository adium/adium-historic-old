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

#import "AIContactAwayPlugin.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIContactAwayPlugin

- (void)installPlugin
{
    //Install our tooltip entry
    [[owner interfaceController] registerContactListTooltipEntry:self];
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)label
{
    return(@"Away");
}

- (NSString *)entryForObject:(AIListObject *)inObject
{
    NSString	*entry = nil;

    if([inObject isKindOfClass:[AIListContact class]]){
        BOOL 			away;
        NSAttributedString 	*statusMessage = nil;
        AIMutableOwnerArray	*ownerArray;

        //Get the away state
        away = [[(AIListContact *)inObject statusArrayForKey:@"Away"] greatestIntegerValue];

        //Get the status message
        ownerArray = [(AIListContact *)inObject statusArrayForKey:@"StatusMessage"];
        if([ownerArray count] != 0){
            statusMessage = [ownerArray objectAtIndex:0];
        }

        //Return the correct string
        if(statusMessage != nil && [statusMessage length] != 0){
            entry = [statusMessage string];
        }else if(away){
            entry = @"Yes";
        }
    }

    return(entry);
}


@end
