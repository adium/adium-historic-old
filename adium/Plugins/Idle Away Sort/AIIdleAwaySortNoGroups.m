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

#import "AIIdleAwaySortNoGroups.h"

int idleAwaySortNoGroups(id objectA, id objectB, BOOL groups);

@implementation AIIdleAwaySortNoGroups

- (NSString *)description{
    return(@"Sorts idle and away to bottom.  Groups are not sorted.");
}
- (NSString *)identifier{
    return(@"IdleAway_NoGroup");
}
- (NSString *)displayName{
    return(@"Idle and Away to Bottom (Groups Not Sorted)");
}
- (NSArray *)statusKeysRequiringResort{
	return([NSArray arrayWithObjects:@"Idle", @"Away", nil]);
}
- (NSArray *)attributeKeysRequiringResort{
	return([NSArray arrayWithObject:@"Display Name"]);
}
- (sortfunc)sortFunction{
	return(&idleAwaySortNoGroups);
}

int idleAwaySortNoGroups(id objectA, id objectB, BOOL groups)
{    
	if(!groups){
		BOOL idleAwayA = ([objectA integerStatusObjectForKey:@"Away"] || [objectA doubleStatusObjectForKey:@"Idle"] != 0);
		BOOL idleAwayB = ([objectB integerStatusObjectForKey:@"Away"] || [objectB doubleStatusObjectForKey:@"Idle"] != 0);
		
		if(idleAwayA && !idleAwayB){
			return(NSOrderedDescending);
		}else if(!idleAwayA && idleAwayB){
			return(NSOrderedAscending);
		}else{
			return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
		}
	}else{
		//Keep groups in manual order
		if([objectA orderIndex] > [objectB orderIndex]){
			return(NSOrderedDescending);
		}else{
			return(NSOrderedAscending);
		}
	}
}

@end
