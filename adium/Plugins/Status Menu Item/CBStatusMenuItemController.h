//
//  CBStatusMenuItemController.h
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

@interface CBStatusMenuItemController : AIObject <AccountMenuPlugin, AIChatObserver>
{
    NSStatusItem            *statusItem;
    NSMenu                  *theMenu;
    
    NSMutableArray          *accountMenuItemsArray;
    NSMutableArray          *unviewedObjectsArray;
    BOOL                    unviewedState;
    
    BOOL                    needsUpdate;
}

+ (CBStatusMenuItemController *)statusMenuItemController;

//AccountMenuPlugin
- (NSString *)identifier;
- (void)addAccountMenuItems:(NSArray *)menuItemArray;
- (void)removeAccountMenuItems:(NSArray *)menuItemArray;

//Twiddle visibility
- (void)showStatusItem;
- (void)hideStatusItem;

//Chat Observer
- (NSArray *)updateChat:(AIChat *)inChat keys:(NSArray *)inModifiedKeys silent:(BOOL)silent;
@end
