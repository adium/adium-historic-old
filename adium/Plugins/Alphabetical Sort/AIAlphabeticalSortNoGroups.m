//
//  AIAlphabeticalSortNoGroups.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAlphabeticalSortNoGroups.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

int alphabeticalSortNoGroups(id objectA, id objectB, void *context);

@implementation AIAlphabeticalSortNoGroups

- (NSString *)description{
    return(@"Sort contacts alphabetically.  Groups are not sorted.");
}
- (NSString *)identifier{
    return(@"Alphabetical_NoGroup");
}
- (NSString *)displayName{
    return(@"Alphabetical (Groups Not Sorted)");
}

- (BOOL)shouldSortForModifiedStatusKeys:(NSArray *)inModifiedKeys
{
    return(NO); //Ignore
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
    [inObjects sortUsingFunction:alphabeticalSortNoGroups context:nil];
}

int alphabeticalSortNoGroups(id objectA, id objectB, void *context)
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
            return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
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
