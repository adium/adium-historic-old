//
//  AIEnterAwayWindowController.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class	AIAdium;

@interface AIEnterAwayWindowController : NSWindowController {
    AIAdium	*owner;
    
}

+ (AIEnterAwayWindowController *)enterAwayWindowControllerForOwner:(id)inOwner;
- (IBAction)closeWindow:(id)sender;

@end
