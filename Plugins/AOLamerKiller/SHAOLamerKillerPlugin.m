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

#import "SHAOLamerKillerPlugin.h"


@implementation SHAOLamerKillerPlugin

- (void)installPlugin
{
    [[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
    
    stringShitlist = [[NSArray alloc] initWithObjects:@" a/s/l",@" u",@" r",@" omg",@" pic",@" mby",@" 2nite",@" cos",@" coz",@" 2day",
                                                      @" waz",@" 4ever",@" B4",@" GR8",@" L8R",@" THX",@" THKS",@" lyk",
                                                      @" wut",@" asl",@" ic",@" pen0r",@" vagin0r",@" pr0n",@" fer",@" ffs",@" sif",
                                                      @" 2morrow",@" 2marro",@" k",@" OMGWTFBBQ",@" OMGHI2U",@" ur",@" NE1", @" "nil];
    killCount = 0;
}

- (void)uninstallPlugin
{
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    if(inAttributedString && [inAttributedString length]){
        NSString *localString = [inAttributedString string];
    
        NSEnumerator *enumerator = [stringShitlist objectEnumerator];
        NSString *killString;
        NSRange killRange;

        while(killString = [enumerator nextObject]){
            killRange = [[localString lowercaseString] rangeOfString:[killString lowercaseString]];
            if(NSNotFound != killRange.location){
                killCount++;
            }
        }
    }
    
    if(killCount <= 25){
        return inAttributedString;
    }else{
        return [NSAttributedString stringWithString:@"This user is too lame to type out whole words.  Please stop talking to this person, if you care about your intelligence."];
    }
}

- (float)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

@end
