//
//  AIIdleSortNoGroups.m
//  Adium
//
//  Created by Arno Hautala on Mon May 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIIdleSortNoGroups.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

int idleSortNoGroups(id objectA, id objectB, void *context);

@implementation AIIdleSortNoGroups

- (NSString *)description{
    return(@"Sorts contacts by status and then idle time.  Groups are not sorted.");
}
- (NSString *)identifier{
    return(@"Idle_NoGroup");
}
- (NSString *)displayName{
    return(@"Most Idle to Bottom (Groups Not Sorted)");
}

- (BOOL)shouldSortForModifiedStatusKeys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"Idle"]){
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
    [inObjects sortUsingFunction:idleSortNoGroups context:nil];
}

int idleSortNoGroups(id objectA, id objectB, void *context)
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

            if(idleA && !idleB){
                return(NSOrderedDescending);
            }else if(!idleA && idleB){
                return(NSOrderedAscending);
            }else if(!idleA && !idleB){
		if(awayA && !awayB){
		    return(NSOrderedDescending);
		}else if(!awayA && awayB){
		    return(NSOrderedAscending);
		}else{
		    return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
		}
	    }else{
		if ([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] < [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue]){
		    return(NSOrderedAscending);
		}else if ([[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] > [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue]){
		    return(NSOrderedDescending);
		}else{
		    return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
		}
            }
        }else{
            AIListGroup	*group = [objectA containingGroup];

            //Keep groups in manual order
            if([group indexOfObject:objectA] > [group indexOfObject:objectB]){
                return(NSOrderedDescending);
            }else{
                return(NSOrderedAscending);
            }
        }
    }
}

@end
