//
//  AIToolbarTabView.h
//  Adium
//
//  Created by Adam Iser on Sat May 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AIToolbarTabView : NSTabView {
    NSMutableDictionary *toolbarItems;
	int					oldHeight;
}

@end

@interface NSObject(NSToolbarTabViewDelegate)
- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem;
- (int)tabView:(NSTabView *)tabView heightForTabViewItem:(NSTabViewItem *)tabViewItem;
@end
