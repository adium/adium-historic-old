//
//  AIAlphabeticalSortPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jan 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAlphabeticalSortPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

int alphabeticalSort(id objectA, id objectB, void *context);

@implementation AIAlphabeticalSortPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactSortController:self];
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
        return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
    }
}

@end
