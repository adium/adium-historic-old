//
//  ESContactAlert.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESContactAlert.h"

@interface ESContactAlert (PRIVATE)

@end

@implementation ESContactAlert

+ (id)contactAlertWithOwner:(id)inOwner
{
    return ([[[self alloc] initWithOwner:inOwner] autorelease]);   
}


- (id)initWithOwner:(id)inOwner
{
    owner = inOwner;
    
    NSString *nibName = [self nibName];
    if (nibName)
        [NSBundle loadNibNamed:nibName owner:self];
    
    [super init];
    return (self);
}

//pass nil to remove the key
- (void)setObject:(id)object forKey:(NSString *)key
{
    NSMutableArray * eventActionArray = [[owner contactAlertsController] eventActionArrayForContactAlert:self];
    int row = [[owner contactAlertsController] rowForContactAlert:self];
    NSMutableDictionary *currentDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    
    if (object)
        [currentDict setObject:object forKey:key];
    else
        [currentDict removeObjectForKey:key];
    
    [[[owner contactAlertsController] eventActionArrayForContactAlert:self] replaceObjectAtIndex:row withObject:currentDict];
}

- (void)saveEventActionArray
{
    [[owner contactAlertsController] saveEventActionArrayForContactAlert:self];
}

- (void)configureWithSubview:(NSView *)view
{
    [[owner contactAlertsController] configureWithSubview:view forContactAlert:self];
}
//overridden by subclasses
- (NSMenuItem *)alertMenuItem
{
    return nil;   
}
- (NSString *)nibName
{
    return nil;   
}

//Sorting function
int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context)
{
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1];
    BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
    BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];
    
    
    NSString  	*groupNameA = [[objectA containingGroup] displayName];
    NSString  	*groupNameB = [[objectB containingGroup] displayName];
    if(groupA && !groupB){
        return(NSOrderedAscending);
    }else if(!groupA && groupB){
        return(NSOrderedDescending);
    }
    else if ([groupNameA compare:groupNameB] == 0)
    {
        if(invisibleA && !invisibleB){
            return(NSOrderedDescending);
        }else if(!invisibleA && invisibleB){
            return(NSOrderedAscending);
        }else{
            return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
        }
    }
    else
        return([groupNameA caseInsensitiveCompare:groupNameB]);
}

@end
