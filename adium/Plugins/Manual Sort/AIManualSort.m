//
//  AIManualSort.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIManualSort.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

int manualSort(id objectA, id objectB, void *context);

@implementation AIManualSort

- (NSString *)description{
    return(@"Perform no sorting.");
}
- (NSString *)identifier{
    return(@"ManualSort");
}
- (NSString *)displayName{
    return(@"Manually");
}

- (BOOL)shouldSortForModifiedStatusKeys:(NSArray *)inModifiedKeys
{
    return(NO); //Ignore
}

- (BOOL)shouldSortForModifiedAttributeKeys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"Hidden"]){
        return(YES);
    }else{
        return(NO);
    }
}

- (void)sortListObjects:(NSMutableArray *)inObjects
{
    [inObjects sortUsingFunction:manualSort context:nil];
}

int manualSort(id objectA, id objectB, void *context)
{
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];

    if(invisibleA && !invisibleB){ //Invisible to the bottom
        return(NSOrderedDescending);
    }else if(!invisibleA && invisibleB){ //Invisible to the bottom
        return(NSOrderedAscending);
    }else{
        BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
        BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];

        if(groupA && !groupB){ //Groups to the bottom
            return(NSOrderedAscending);
        }else if(!groupA && groupB){ //Groups to the bottom
            return(NSOrderedDescending);
        }else if(!groupA && !groupB){ //Contacts in manual order
            if([(AIListContact *)objectA index] > [(AIListContact *)objectB index]){
                return(NSOrderedDescending);
            }else{
                return(NSOrderedAscending);
            }

        }else{ //Groups in manual order
            AIListGroup	*group = [objectA containingGroup];

            if([group indexOfObject:objectA] > [group indexOfObject:objectB]){
                return(NSOrderedDescending);
            }else{
                return(NSOrderedAscending);
            }
        }
    }
}

@end
