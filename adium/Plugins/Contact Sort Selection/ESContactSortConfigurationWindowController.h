//
//  ESContactSortConfigurationWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.

@interface ESContactSortConfigurationWindowController : AIWindowController {
	IBOutlet	NSView  *view_main;
}

+ (id)showSortConfigurationWindowForController:(AISortController *)controller;
- (void)configureForController:(AISortController *)controller;

@end
