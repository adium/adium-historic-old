//
//  CBStatusMenuItemController.h
//  Adium XCode
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
//  Changed :  2003-12-28
//  Author  :  Sean Gilbertson (prell)
//  Summary :  - Displays online (and not away/idle) contacts in the status menu,
//             in the order the user prefers.  Users can click each contact to
//             send an IM to that contact.
//  Issues  :  - Does not re-sort contacts when the sort changes (as far as I know).
//             - "Show Contact List" menu item does nothing.
//

#import "AIContactStatusEventsPlugin.h"


@interface CBStatusMenuItemController : AIObject <AIListObjectObserver>
{
    NSStatusItem    *statusItem;
    NSMenu          *theMenu;
    
    NSMutableArray  *accountsMenuItems;
    //NSMutableArray  *groupsMenuItems;

    NSMutableArray* contactListItems;
}

+ (CBStatusMenuItemController *)statusMenuItemController;

@end
