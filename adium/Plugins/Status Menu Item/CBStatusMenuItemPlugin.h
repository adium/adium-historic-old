//
//  CBStatusMenuItemPlugin.h
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

#import "CBStatusMenuItemController.h"

@interface CBStatusMenuItemPlugin : AIPlugin 
{
    CBStatusMenuItemController  *itemController;
}

//Used when toggling the status item on and off
- (void)createStatusItem;
- (void)destroyStatusItem;
@end
