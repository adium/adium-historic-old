//
//  AIGroupedAwayByIdleSortPlugin.m
//  Adium
//
//  Created by Benjamin Grabkowitz on Mon Sep 15 2003.
//

#import "AIGroupedAwayByIdleSortNoGroups.h"

int groupedAwayByIdleSortNoGroups(id objectA, id objectB, AIListGroup *containingGroup, BOOL groups);

@implementation AIGroupedAwayByIdleSortNoGroups

- (NSString *)description{
    return(@"Sorts contacts to the bottom by: Idle & Away, Away, Everyone Else.  Groups are not sorted.");
}
- (NSString *)identifier{
    return(@"GroupedAwayByIdle_NoGroup");
}
- (NSString *)displayName{
    return(@"Away to Bottom (Groups Not Sorted)");
}
- (NSArray *)statusKeysRequiringResort{
	return([NSArray arrayWithObjects:@"Idle", @"Away", nil]);
}
- (NSArray *)attributeKeysRequiringResort{
	return([NSArray arrayWithObject:@"Display Name"]);
}
- (sortfunc)sortFunction{
	return(&groupedAwayByIdleSortNoGroups);
}

int groupedAwayByIdleSortNoGroups(id objectA, id objectB, AIListGroup *containingGroup, BOOL groups)
{    
	if(!groups){
		BOOL awayA = ([[objectA statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1]);
		BOOL awayB = ([[objectB statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1]);
		
		if(awayA && !awayB){
			return(NSOrderedDescending);
		}else if(!awayA && awayB){
			return(NSOrderedAscending);
		}else{//both are away or both are not away
			if(!awayA){//neither are away
				return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
			}else if([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] == [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue]){//both are away and have the same idle time (probably not idle)
				return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
			}else{//both are away and have different idle times
				if([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] > [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue]){
					return(NSOrderedDescending);
				}else{
					return(NSOrderedAscending);
				}
			}
		}
	}else{
		//Keep groups in manual order
		if([objectA orderIndexForGroup:containingGroup] > [objectB orderIndexForGroup:containingGroup]){
			return(NSOrderedDescending);
		}else{
			return(NSOrderedAscending);
		}
	}
}

@end
