//
//  AIIdleAwayManualSort.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Jun 12 2003.
//  Based on AIIdleAwaySortNoGroups and AIManualSort by Adam Iser
//

#import "AIIdleAwayManualSort.h"

int idleAwayManualSort(id objectA, id objectB, BOOL groups);

@implementation AIIdleAwayManualSort

- (NSString *)description{
    return(@"Sorts idle and away to bottom. Groups are not sorted. Manual ordering is respected.");
}
- (NSString *)identifier{
    return(@"IdleAway_Manual");
}
- (NSString *)displayName{
    return(@"Idle and Away to Bottom (Manual Ordering Respected)");
}
- (NSArray *)statusKeysRequiringResort{
	return([NSArray arrayWithObjects:@"Idle", @"Away", nil]);
}
- (NSArray *)attributeKeysRequiringResort{
	return([NSArray arrayWithObject:@"Display Name"]);
}
- (sortfunc)sortFunction{
	return(&idleAwayManualSort);
}

- (BOOL)alwaysSortGroupsToTop
{
	return(NO);
}

int idleAwayManualSort(id objectA, id objectB, BOOL groups)
{
	//Groups to the bottom
	BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
	BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];
	
	if(groupA && !groupB){
		return(NSOrderedDescending);
	}else if(!groupA && groupB){
		return(NSOrderedAscending);
	}else{
		//Idle and Away grouped below others
		if(!groups){
			BOOL idleAwayA = ([[objectA statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1] || [[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] != 0);
			BOOL idleAwayB = ([[objectB statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1] || [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue] != 0);
			
			if(idleAwayA && !idleAwayB){
				return(NSOrderedDescending);
			}else if(!idleAwayA && idleAwayB){
				return(NSOrderedAscending);
			}
		}
		
		//Manual order
		if([objectA orderIndex] > [objectB orderIndex]){
			return(NSOrderedDescending);
		}else{
			return(NSOrderedAscending);
		}
	}
}

@end
