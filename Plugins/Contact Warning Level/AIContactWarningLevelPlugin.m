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

#import "AIContactWarningLevelPlugin.h"
#import "AIInterfaceController.h"
#import <Adium/AIListObject.h>

@implementation AIContactWarningLevelPlugin

- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    return(@"Warning Level");
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    int 		warningLevel;
    NSAttributedString	*entry = nil;

    //Get the away state
    warningLevel = [inObject integerStatusObjectForKey:@"Warning"];
    
    //Return the correct string
    if(warningLevel != 0){
	entry = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d%%", warningLevel]];
    }

    return([entry autorelease]);
}


@end
