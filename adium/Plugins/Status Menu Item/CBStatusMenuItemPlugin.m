//
//  CBStatusMenuItemPlugin.m
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

#import "CBStatusMenuItemPlugin.h"

@implementation CBStatusMenuItemPlugin

- (void)installPlugin
{
    [self createStatusItem];
}

- (void)createStatusItem
{
    itemController = [CBStatusMenuItemController statusMenuItemController];
}

- (void)destroyStatusItem
{
    if(itemController){
        [itemController release];
        itemController = nil;
    }
}

- (void)uninstallPlugin
{
    [self destroyStatusItem];
}

@end
