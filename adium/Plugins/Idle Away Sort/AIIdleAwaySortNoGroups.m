//
//  AIIdleAwaySortNoGroups.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIIdleAwaySortNoGroups.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

int idleAwaySortNoGroups(id objectA, id objectB, void *context);

@implementation AIIdleAwaySortNoGroups

- (NSString *)description{
    return(@"Sorts idle and away to bottom.  Groups are not sorted");
}
- (NSString *)identifier{
    return(@"IdleAway_NoGroup");
}
- (NSString *)displayName{
    return(@"Idle and Away to Bottom (Groups Not Sorted)");
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
    [inObjects sortUsingFunction:idleAwaySortNoGroups context:nil];
}

int idleAwaySortNoGroups(id objectA, id objectB, void *context)
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
            }else{
                return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
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
