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

#import "AIGroupedIdleAwaySortNoGroups.h"

int groupedIdleAwaySortNoGroups(id objectA, id objectB, void *context);

@implementation AIGroupedIdleAwaySortNoGroups

- (NSString *)description{
    return(@"Sorts contacts to the bottom by: Idle and Away, Idle, Away.  Groups are not sorted. (Adium 1.x style)");
}
- (NSString *)identifier{
    return(@"GroupedIdleAway_NoGroup");
}
- (NSString *)displayName{
    return(@"Idle to Bottom (Grouped by status) (Groups Not Sorted)");
}

- (BOOL)shouldSortForModifiedStatusKeys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"Idle"] || [inModifiedKeys containsObject:@"Away"]){
        return(YES);
    }else{
        return(NO);
    }
}

- (BOOL)shouldSortForModifiedAttributeKeys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"Hidden"] || [inModifiedKeys containsObject:@"Display Name"]){
        return(YES);
    }else{
        return(NO);
    }
}

- (void)sortListObjects:(NSMutableArray *)inObjects
{
    [inObjects sortUsingFunction:groupedIdleAwaySortNoGroups context:nil];
}

int groupedIdleAwaySortNoGroups(id objectA, id objectB, void *context)
{    
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    
    if(invisibleA && !invisibleB){
        return(NSOrderedDescending);
    }else if(!invisibleA && invisibleB){
        return(NSOrderedAscending);
    }else{
        BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
        BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];

        if(groupA && !groupB){
            return(NSOrderedAscending);
        }else if(!groupA && groupB){
            return(NSOrderedDescending);
        }else if(!groupA && !groupB){
            BOOL idleA = ([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] != 0);
            BOOL idleB = ([[objectB statusArrayForKey:@"Idle"] greatestDoubleValue] != 0);
            BOOL awayA = ([[objectA statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1]);
            BOOL awayB = ([[objectB statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1]);

	    int countA = 0;
	    int countB = 0;

	    if(idleA) countA++;
	    if(awayA) countA++;
	    if(idleB) countB++;
	    if(awayB) countB++;

	    if(countA > countB){
		return NSOrderedDescending;
	    }else if(countA < countB){
		return NSOrderedAscending;
	    }else{
		if([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] == [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue])
		{//If the idle times are equal do alphabetical sort (this makes the contact list less jumpy and adds familiarity to the list)
		    return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
		}
		if([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] > [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue]){
		    return NSOrderedDescending;
		}else{
		    return NSOrderedAscending;
		}
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
}

@end
