//
//  AIIdleAwayManualSort.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Jun 12 2003.
//  Based on AIIdleAwaySortNoGroups and AIManualSort by Adam Iser
//

#import "AIIdleAwayManualSort.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

int idleAwayManualSort(id objectA, id objectB, void *context);

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
    [inObjects sortUsingFunction:idleAwayManualSort context:nil];
}

int idleAwayManualSort(id objectA, id objectB, void *context)
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
            BOOL idleAwayA = ([[objectA statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1] || [[objectA statusArrayForKey:@"Idle"] greatestDoubleValue] != 0);
            BOOL idleAwayB = ([[objectB statusArrayForKey:@"Away"] containsAnyIntegerValueOf:1] || [[objectB statusArrayForKey:@"Idle"] greatestDoubleValue] != 0);

            if(idleAwayA && !idleAwayB){
                return(NSOrderedDescending);
            }else if(!idleAwayA && idleAwayB){
                return(NSOrderedAscending);
            }
        }
        //Keep groups in manual order
        if([objectA orderIndex] > [objectB orderIndex]){
            return(NSOrderedDescending);
        }else{
            return(NSOrderedAscending);
        }
    }
}
@end
