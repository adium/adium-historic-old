//
//  ESContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//

#import "ESContactAlert.h"

@interface ESContactAlert (PRIVATE)

@end

@implementation ESContactAlert

+ (id)contactAlert
{
    return ([[[self alloc] init] autorelease]);   
}


- (id)init
{    
    NSString *nibName = [self nibName];
    if (nibName)
        [NSBundle loadNibNamed:nibName owner:self];
    
    [super init];
    return (self);
}

//pass nil to remove the key
- (void)setObject:(id)object forKey:(NSString *)key
{
    NSMutableArray * eventActionArray = [[adium contactAlertsController] eventActionArrayForContactAlert:self];
    int row = [[adium contactAlertsController] rowForContactAlert:self];
    NSLog(@"eventActionArray is %@, row is %i",eventActionArray,row);
    NSMutableDictionary *currentDict = [[eventActionArray objectAtIndex:row] mutableCopy];
    
    if (object)
        [currentDict setObject:object forKey:key];
    else
        [currentDict removeObjectForKey:key];
    
    [[[adium contactAlertsController] eventActionArrayForContactAlert:self] replaceObjectAtIndex:row withObject:currentDict];
}

- (void)saveEventActionArray
{
    [[adium contactAlertsController] saveEventActionArrayForContactAlert:self];
}

- (void)configureWithSubview:(NSView *)view
{
    [[adium contactAlertsController] configureWithSubview:view forContactAlert:self];
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
#warning This can not work as expected. Furthmore, why is it in two places?

int alphabeticalGroupOfflineSort(id objectA, id objectB, void *context)
{
    BOOL	invisibleA = [[objectA displayArrayForKey:@"Hidden"] intValue];
    BOOL	invisibleB = [[objectB displayArrayForKey:@"Hidden"] intValue];
    BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
    BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];
    
    
 //   NSString  	*groupNameA = [[objectA containingGroup] displayName];
 //   NSString  	*groupNameB = [[objectB containingGroup] displayName];
    if(groupA && !groupB){
        return(NSOrderedAscending);
    }else if(!groupA && groupB){
        return(NSOrderedDescending);
    }
 //   else if ([groupNameA compare:groupNameB] == 0)
  //  {
    else
        if(invisibleA && !invisibleB){
            return(NSOrderedDescending);
        }else if(!invisibleA && invisibleB){
            return(NSOrderedAscending);
        }else{
            return([[objectA displayName] caseInsensitiveCompare:[objectB displayName]]);
        }
//    }
 //   else
  //      return([groupNameA caseInsensitiveCompare:groupNameB]);
}

@end
