//
//  AIAccountSelectionToolbarItem.m
//  Adium
//
//  Created by Adam Iser on Sun Jul 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAccountSelectionToolbarItem.h"


@implementation AIAccountSelectionToolbarItem
/*
- (id)initWithItemIdentifier:(NSString *)itemIdentifier delegate:(id <AIAccountSelectionViewDelegate>)inDelegate owner:(id)inOwner
{
    [super initWithItemIdentifier:itemIdentifier];

    [item setLabel:@"From: resI madA"];
    [item setPaletteLabel:@""];
    [item setToolTip:@""];
    [item setTarget:target];
    

    
}

//--Create and setup an NSToolbarItem--
NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
[item setLabel:label];
[item setPaletteLabel:paletteLabel];
[item setToolTip:toolTip];
[item setTarget:target];
// the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
// one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
// (in the itemContent parameter).  Then this next line will do the right thing automatically.
if(settingSelector && itemContent){
    [item performSelector:settingSelector withObject:itemContent];
}
[item setAction:action];
// If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
// we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
// so we create a dummy NSMenuItem that has our real menu as a submenu.
if (menu!=NULL)
{
    // we actually need an NSMenuItem here, so we construct one
    mItem=[[[NSMenuItem alloc] init] autorelease];
    [mItem setSubmenu: menu];
    [mItem setTitle: [menu title]];
    [item setMenuFormRepresentation:mItem];
}
*/
@end
