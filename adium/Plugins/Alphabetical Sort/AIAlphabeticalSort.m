//
//  AIAlphabeticalSort.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAlphabeticalSort.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

int alphabeticalSort(id objectA, id objectB, void *context);

@implementation AIAlphabeticalSort

- (NSString *)description{
    return(@"Sort contacts and groups alphabetically.");
}
- (NSString *)identifier{
    return(@"Alphabetical");
}
- (NSString *)displayName{
    return(@"Alphabetical");
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

- (void)sortContactObjects:(NSMutableArray *)inObjects
{
    [inObjects sortUsingFunction:alphabeticalSort context:nil];
}

int alphabeticalSort(id objectA, id objectB, void *context)
{
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];

    if(invisibleA && !invisibleB){
        return(NSOrderedDescending);
    }else if(!invisibleA && invisibleB){
        return(NSOrderedAscending);
    }else{
        BOOL	groupA = [objectA isKindOfClass:[AIContactGroup class]];
        BOOL	groupB = [objectB isKindOfClass:[AIContactGroup class]];

        if(groupA && !groupB){
            return(NSOrderedAscending);
        }else if(!groupA && groupB){
            return(NSOrderedDescending);
        }else{
            return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
        }
    }
}

@end
