//
//  CBContactCountingDisplayPlugin.m
//  Adium XCode
//
//  Created by Colin Barrett on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBContactCountingDisplayPlugin.h"

@implementation CBContactCountingDisplayPlugin

- (void)installPlugin
{
    //install our observers
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactsChanged:) name:ListObject_StatusChanged object:nil];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    
}

- (void)contactsChanged:(NSNotification *)notification
{
    /* some important keys:
        @"VisibleObjectCount" - ListGroup status object (NSNumber)
        @"Right Text" - ListObject display array (AIMutableOwnerArray)
    */
        
    AIListObject *listObject = [notification object];
    NSArray *groups = [listObject containingGroups];
    NSString *addString;
    
    if(groups)
    {        
        NSEnumerator *numer = [groups objectEnumerator];
        AIListGroup *group;
        while(group = [numer nextObject])
        {
            addString = [NSString stringWithFormat:@" (%i/%i)", [[group statusObjectForKey:@"VisibleObjectCount"] intValue], [group count]];
            
            //Shouldn't really have to use primary object.
            [[group displayArrayForKey:@"Right Text"] setPrimaryObject:addString withOwner:self];
        }
    }
}

- (void)uninstallPlugin
{
    //we are no longer an observer
    [[adium notificationCenter] removeObserver:self];
}

@end
