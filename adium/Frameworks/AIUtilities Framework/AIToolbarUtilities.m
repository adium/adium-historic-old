/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

/*
    Helpful methods to create items for a window toolbar
*/

#import "AIToolbarUtilities.h"

@interface AIToolbarUtilities (PRIVATE)

@end

@implementation AIToolbarUtilities

//-------------------
//  Public Methods
//-----------------------
+ (void)addToolbarItemToDictionary:(NSMutableDictionary *)theDict withIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target settingSelector:(SEL)settingSelector itemContent:(id)itemContent action:(SEL)action menu:(NSMenu *)menu
{
    NSMenuItem *mItem;

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
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}

+ (NSToolbarItem *)toolbarItemFromDictionary:(NSDictionary *)theDict withIdentifier:(NSString *)itemIdentifier
{
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    NSToolbarItem *item=[theDict objectForKey:itemIdentifier];

    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=NULL)
    {
        [newItem setView:[item view]];
    }
    else
    {
        [newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=NULL)
    {
        [newItem setMinSize:[[item view] bounds].size];
        [newItem setMaxSize:[[item view] bounds].size];
    }

    return newItem;
}


//-------------------
//  Hidden Methods
//-----------------------

//-------------------
//  Private Methods
//-----------------------


@end
