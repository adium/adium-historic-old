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

#import "SAContactOnlineForPlugin.h"
#import <AIUtilities/AIUtilities.h>

@implementation SAContactOnlineForPlugin

- (void)installPlugin
{
    //Install our tooltip entry
    [[owner interfaceController] registerContactListTooltipEntry:self secondaryEntry:NO];
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    if([inObject isKindOfClass:[AIListContact class]]){
        return(@"Online For");
    }

    return(nil);
}

- (NSString *)entryForObject:(AIListObject *)inObject
{
    if([inObject isKindOfClass:[AIListContact class]]){
        NSDate	*signonDate, *currentDate;

        currentDate = [NSDate date];
        signonDate = [[(AIListContact *)inObject statusArrayForKey:@"Signon Date"] earliestDate];
        
        if(signonDate){
            return([NSDateFormatter stringForTimeIntervalSinceDate:signonDate showingSeconds:NO abbreviated:NO]);
        }
    }

    return(nil);
}

@end
