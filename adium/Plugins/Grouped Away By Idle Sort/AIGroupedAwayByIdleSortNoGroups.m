//
//  AIGroupedAwayByIdleSortPlugin.m
//  Adium
//
//  Created by Benjamin Grabkowitz on Mon Sep 15 2003.
//

#import "AIGroupedAwayByIdleSortNoGroups.h"

int groupedAwayByIdleSortNoGroups(id objectA, id objectB, void *context);

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
    [inObjects sortUsingFunction:groupedAwayByIdleSortNoGroups context:nil];
}

int groupedAwayByIdleSortNoGroups(id objectA, id objectB, void *context)
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
            BOOL awayA = ([[objectA statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1]);
            BOOL awayB = ([[objectB statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1]);
    
	    if((awayA) && (!awayB))
	    {
		return NSOrderedDescending;
	    }
	    else if((!awayA) && (awayB))
	    {
		return NSOrderedAscending;
	    }
	    else
	    {//both are away or both are not away
		if(!awayA)
		{//neither are away
		    return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
		}
		else if([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] == [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue])
		{//both are away and have the same idle time (probably not idle)
		    return([[objectA longDisplayName] caseInsensitiveCompare:[objectB longDisplayName]]);
		}
		else
		{//both are away and have different idle times
		    if([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] > [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue])
		    {
			return NSOrderedDescending;
		    }
		    else
		    {
			return NSOrderedAscending;
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
}

@end
