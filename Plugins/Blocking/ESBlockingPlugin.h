//
//  ESBlockingPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface ESBlockingPlugin : AIPlugin {
	NSMenuItem  *blockContactMenuItem;
	NSMenuItem  *blockContactContextualMenuItem;
}

- (IBAction)blockContact:(id)sender;
@end
