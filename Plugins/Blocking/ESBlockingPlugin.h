//
//  ESBlockingPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface ESBlockingPlugin : AIPlugin {
	NSMenuItem  *blockContactMenuItem;
	NSMenuItem  *unblockContactMenuItem;
	NSMenuItem  *blockContactContextualMenuItem;
	NSMenuItem  *unblockContactContextualMenuItem;
}

- (IBAction)blockContact:(id)sender;
- (IBAction)unblockContact:(id)sender;
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
@end
