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
	NSMutableArray			*openChatsArray;
    
    BOOL                    needsUpdate;
	
	SMI_Icon_State			iconState;
}

+ (CBStatusMenuItemController *)statusMenuItemController;

//Twiddle visibility
- (void)showStatusItem;
- (void)hideStatusItem;

@end
