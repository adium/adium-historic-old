//
//  CBStatusMenuItemController.h
//  Adium
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//

typedef enum {
	OFFLINE	= 0,
	ONLINE = 1,
	UNVIEWED = 2
} SMI_Icon_State;

@interface CBStatusMenuItemController : AIObject <AccountMenuPlugin, AIChatObserver>
{
    NSStatusItem            *statusItem;
    NSMenu                  *theMenu;
    
    NSMutableArray          *accountMenuItemsArray;
    NSMutableArray          *unviewedObjectsArray;
    
    BOOL                    needsUpdate;
	
	SMI_Icon_State			iconState;
}

+ (CBStatusMenuItemController *)statusMenuItemController;

//Icon State
- (void)setIconState:(SMI_Icon_State)state;

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
