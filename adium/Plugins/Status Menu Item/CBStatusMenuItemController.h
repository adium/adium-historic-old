//
//  CBStatusMenuItemController.h
//  Adium XCode
//
//  Created by Colin Barrett on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@interface CBStatusMenuItemController : NSObject 
{
    NSStatusItem    *statusItem;
    NSMenu          *theMenu;
    
    NSMutableArray  *accountsMenuItems;
    //NSMutableArray  *groupsMenuItems;
    
    AIAdium         *owner;
}

+ (CBStatusMenuItemController *)statusMenuItemControllerForOwner:(id)inOwner;

@end
