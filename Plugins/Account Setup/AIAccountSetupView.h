//
//  AIAccountSetupView.h
//  Adium
//
//  Created by Adam Iser on 12/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAccountSetupWindowController;

@interface AIAccountSetupView : NSView {
	IBOutlet	AIAccountSetupWindowController	*controller;

	AIAdium 			*adium;
}

- (void)viewDidLoad;
- (void)viewWillClose;
- (NSSize)desiredSize;

@end
