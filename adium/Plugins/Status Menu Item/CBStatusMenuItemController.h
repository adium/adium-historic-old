//
//  CBStatusMenuItemController.h
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

@interface CBStatusMenuItemController : AIObject <AccountMenuPlugin, AIListObjectObserver>
{
    NSStatusItem    *statusItem;
    NSMenu          *theMenu;
    
    NSMutableArray  *accountMenuItemsArray;
    NSMutableArray  *unviewedObjectsArray;
    BOOL			unviewedState;
    
    BOOL            needsUpdate;

}

+ (CBStatusMenuItemController *)statusMenuItemController;

//AccountMenuPlugin
- (NSString *)identifier;
- (void)addAccountMenuItems:(NSArray *)menuItemArray;
- (void)removeAccountMenuItems:(NSArray *)menuItemArray;

//Twiddle visibility
- (void)showStatusItem;
- (void)hideStatusItem;

//Contact Observer
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
@end
