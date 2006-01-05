//
//  RAFBlockEditorPlugin.h
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIPlugin.h>
#import "AIMenuController.h"
#import "RAFBlockEditorWindowController.h"
#import <Cocoa/Cocoa.h>

@interface RAFBlockEditorPlugin : AIPlugin {
	NSMenuItem  *blockEditorMenuItem;
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
- (IBAction)showEditor:(id)sender;

@end
