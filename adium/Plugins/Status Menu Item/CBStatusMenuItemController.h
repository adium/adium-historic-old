//
//  CBStatusMenuItemController.h
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

@interface CBStatusMenuItemController : AIObject
{
    NSStatusItem    *statusItem;
    NSMenu          *theMenu;
}

+ (CBStatusMenuItemController *)statusMenuItemController;

@end
