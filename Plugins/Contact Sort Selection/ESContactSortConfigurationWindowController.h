//
//  ESContactSortConfigurationWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface ESContactSortConfigurationWindowController : AIWindowController {
	IBOutlet	NSView  *view_main;
}

+ (id)showSortConfigurationWindowForController:(AISortController *)controller;
- (void)configureForController:(AISortController *)controller;

@end
