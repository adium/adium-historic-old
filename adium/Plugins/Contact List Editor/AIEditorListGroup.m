//
//  AIEditorListGroup.m
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEditorListGroup.h"

int alphabeticalSort(id objectA, id objectB, void *context);

@implementation AIEditorListGroup

- (id)initWithUID:(NSString *)inUID temporary:(BOOL)inTemporary
{
    [super initWithUID:inUID temporary:inTemporary];

    contents = [[NSMutableArray alloc] init];
    expanded = YES;
    
    return(self);
}

- (void)addObject:(AIEditorListObject *)inObject
{
    [contents addObject:inObject];
    [inObject setContainingGroup:self];

    [self sort]; //resort
}

- (void)removeObject:(AIEditorListObject *)inObject
{
    [contents removeObject:inObject];
    [inObject setContainingGroup:nil];

    [self sort]; //resort
}

- (AIEditorListObject *)objectAtIndex:(unsigned)index
{
    return([contents objectAtIndex:index]);
}

- (NSEnumerator *)objectEnumerator
{
    return([contents objectEnumerator]);
}

- (unsigned)count
{
    return([contents count]);
}

- (void)setExpanded:(BOOL)inExpanded
{
    expanded = inExpanded;
}
- (BOOL)isExpanded{
    return(expanded);
}

- (void)sort
{
    [contents sortUsingFunction:alphabeticalSort context:nil];
}

int alphabeticalSort(id objectA, id objectB, void *context)
{
    BOOL	groupA = [objectA isKindOfClass:[AIEditorListGroup class]];
    BOOL	groupB = [objectB isKindOfClass:[AIEditorListGroup class]];

    if(groupA && !groupB){
        return(NSOrderedAscending);
    }else if(!groupA && groupB){
        return(NSOrderedDescending);
    }else{
        return([[objectA UID] caseInsensitiveCompare:[objectB UID]]);
    }
}


@end



