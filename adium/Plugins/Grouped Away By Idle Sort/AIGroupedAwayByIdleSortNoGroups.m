//
//  AIGroupedAwayByIdleSortPlugin.m
//  Adium
//
//  Created by Benjamin Grabkowitz on Mon Sep 15 2003.
//

#import "AIGroupedAwayByIdleSortNoGroups.h"

int groupedAwayByIdleSortNoGroups(id objectA, id objectB, BOOL groups);

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

int groupedAwayByIdleSortNoGroups(id objectA, id objectB, BOOL groups)
{    
	if(!groups){
		BOOL awayA = ([objectA integerStatusObjectForKey:@"Away"]);
		BOOL awayB = ([objectB integerStatusObjectForKey:@"Away"]);
		
		if(awayA && !awayB){
			return(NSOrderedDescending);
		}else if(!awayA && awayB){
			return(NSOrderedAscending);
		}else{//both are away or both are not away
			if(!awayA){//neither are away
				return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
			}else if([objectA doubleStatusObjectForKey:@"Idle"] == [objectB doubleStatusObjectForKey:@"Idle"]){//both are away and have the same idle time (probably not idle)
				return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
			}else{//both are away and have different idle times
				if([objectA doubleStatusObjectForKey:@"Idle"] > [objectB doubleStatusObjectForKey:@"Idle"]){
					return(NSOrderedDescending);
				}else{
					return(NSOrderedAscending);
				}
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

@end
