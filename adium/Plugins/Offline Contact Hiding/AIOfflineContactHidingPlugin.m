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

#import "AIOfflineContactHidingPlugin.h"

@implementation AIOfflineContactHidingPlugin

- (void)installPlugin
{
    [[adium contactController] registerListObjectObserver:self];
}

- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
    if(inModifiedKeys == nil ||
	   [inModifiedKeys containsObject:@"Online"] ||
	   [inModifiedKeys containsObject:@"Signed Off"] ||
	   [inModifiedKeys containsObject:@"VisibleObjectCount"]){
		if([inObject isKindOfClass:[AIListContact class]]){
			int		online = [[inObject statusArrayForKey:@"Online"] greatestIntegerValue];
			int		justSignedOff = [[inObject statusArrayForKey:@"Signed Off"] containsAnyIntegerValueOf:1];
			
			//Insert an updated value
			if(!online && !justSignedOff){
				[inObject setVisible:NO]; //Hidden
			}else{
				[inObject setVisible:YES]; //Visible
			}
		}else if([inObject isKindOfClass:[AIListGroup class]]){
			int visibleCount = [(AIListGroup *)inObject visibleCount];
			
			[inObject setVisible:(visibleCount > 0)];
		}
	}
	
    return(nil);
}

@end
