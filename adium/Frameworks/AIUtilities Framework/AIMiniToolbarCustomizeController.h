//
//  AIMiniToolbarCustomizeController.h
//  Adium
//
//  Created by Adam Iser on Mon Dec 23 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIMiniToolbarTableView, AIMiniToolbar;

@interface AIMiniToolbarCustomizeController : NSWindowController {
    IBOutlet	AIMiniToolbarTableView	*tableView_items;
    
    NSMutableArray		*itemImageArray;
    NSMutableArray		*itemArray;

    AIMiniToolbar		*toolbar;
    
}

+ (void)showCustomizationWindowForToolbar:(AIMiniToolbar *)inToolbar;

@end
