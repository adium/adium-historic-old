//
//  CBStatusMenuItemController.h
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

@interface CBStatusMenuItemController : AIObject <AccountMenuPlugin>
{
    NSStatusItem    *statusItem;
    NSMenu          *theMenu;
}

+ (CBStatusMenuItemController *)statusMenuItemController;
+ (CBStatusMenuItemController *)sharedInstance;

//AccountMenuPlugin
- (NSString *)identifier;
- (void)addAccountMenuItems:(NSArray *)menuItemArray;
- (void)removeAccountMenuItems:(NSArray *)menuItemArray;

@end
