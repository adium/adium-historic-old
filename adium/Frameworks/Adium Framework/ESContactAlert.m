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

- (void)setObject:(id)object forKey:(NSString *)key
{
    NSMutableArray * eventActionArray = [[owner contactAlertsController] eventActionArrayForContactAlert:self];
    int row = [[owner contactAlertsController] rowForContactAlert:self];
    NSMutableDictionary *currentDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    
    [currentDict setObject:object forKey:key];
    
    [[[owner contactAlertsController] eventActionArrayForContactAlert:self] replaceObjectAtIndex:row withObject:currentDict];
}

- (void)saveEventActionArray
{
    [[owner contactAlertsController] saveEventActionArrayForContactAlert:self];
}

//overridden by subclasses
- (NSMenuItem *)alertMenuItem
{
    return nil;   
}
@end
