/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIToolbarUtilities.h"

/*!
 * @class AIToolbarUtilities
 * @brief Helpful methods for creating window toolbar items
 *
 * Methods for conveniently creating, storing, and retrieivng <tt>NSToolbarItem</tt> objects.
 */
@implementation AIToolbarUtilities

/*!
 * @brief Create an <tt>NSToolbarItem</tt> and add it to an <tt>NSDictionary</tt>
 *
 * Calls <tt>toolbarItemWithIdentifier:label:paletteLabel:toolTip:target:settingSelector:itemContent:action:menu:</tt> and adds the result to a dictionary.
 * @param theDict A dictionary in which to store the <tt>NSToolbarItem</tt>
 * @param identifier
 * @param label
 * @param paletteLabel
 * @param toolTip
 * @param target
 * @param action
 * @param settingSelector Selector to call on the <tt>NSToolbarItem</tt> after it is created.  It should take a single object, which will be <tt>itemContent</tt>.  May be nil.
 * @param itemContent Object for <tt>settingSelector</tt>.  May be nil.
 * @param menu	A menu to set on the NSToolbarItem.  It will be automatically encapsulated by an NSMenuItem as NSToolbarItem requires.
 */
+ (void)addToolbarItemToDictionary:(NSMutableDictionary *)theDict withIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target settingSelector:(SEL)settingSelector itemContent:(id)itemContent action:(SEL)action menu:(NSMenu *)menu
{
    NSToolbarItem   *item = [self toolbarItemWithIdentifier:identifier label:label paletteLabel:paletteLabel toolTip:toolTip target:target settingSelector:settingSelector itemContent:itemContent action:action menu:menu];

    [theDict setObject:item forKey:identifier];
}

/*!
 * @brief Convenience method for creating an <tt>NSToolbarItem</tt>
 *
 * Parameters not discussed below are simply set using the <tt>NSToolbarItem</tt> setters; see its documentation for details.
 * @param identifier
 * @param label
 * @param paletteLabel
 * @param toolTip
 * @param target
 * @param action
 * @param settingSelector Selector to call on the <tt>NSToolbarItem</tt> after it is created.  It should take a single object, which will be <tt>itemContent</tt>.  May be nil.
 * @param itemContent Object for <tt>settingSelector</tt>.  May be nil.
 * @param menu	A menu to set on the NSToolbarItem.  It will be automatically encapsulated by an NSMenuItem as NSToolbarItem requires.
 */
+ (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target settingSelector:(SEL)settingSelector itemContent:(id)itemContent action:(SEL)action menu:(NSMenu *)menu
{
    NSToolbarItem 	*item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    NSMenuItem 		*mItem;

    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
	[item setToolTip:toolTip];

	if (target) {
		[item setTarget:target];
	}

    /* The settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
     * one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
     * (in the itemContent parameter).  Then this next line will do the right thing automatically.
	 */
    if (settingSelector && itemContent) {
        [item performSelector:settingSelector withObject:itemContent];
    }
	if (action) {
		[item setAction:action];
	}
	
    /* If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
     * we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
     * so we create a dummy NSMenuItem that has our real menu as a submenu.
	 */
    if (menu != NULL) {
        //We actually need an NSMenuItem here, so we construct one
        mItem = [[[NSMenuItem alloc] init] autorelease];
        [mItem setSubmenu: menu];
        [mItem setTitle: [menu title]];
        [item setMenuFormRepresentation:mItem];
    }
    
    return item;
}

/*!
 * @brief Retrieve a new NSToolbarItem instance based on a dictionary's entry
 *
 * Retrieves a new copy of the NSToolbarItem stored in <tt>theDict</tt> with the <tt>itemIdentifier</tt> identifier.  This should be used rather than simply copying the existing NSToolbarItem so custom copying behaviors to maintain custom view, image, and menu settings are utilized.
 * @param theDict The source <tt>NSDictionary</tt>
 * @param itemIdentifier The identifier of the NSToolbarItem previous stored with <tt>addToolbarItemToDictionary:withIdentifier:label:paletteLabel:toolTip:target:settingSelector:itemContent:action:menu:</tt>
 * @return The retrieved NSToolbarItem
 */
+ (NSToolbarItem *)toolbarItemFromDictionary:(NSDictionary *)theDict withIdentifier:(NSString *)itemIdentifier
{
    /* We create and autorelease a new NSToolbarItem (or a subclass of one, hence [item class])
	 * and then go through the process of setting up its attributes from the master toolbar item matching that identifier
	 * in our dictionary of items.
	 */
    NSToolbarItem *item;
	NSToolbarItem *newItem;
	
	item = [theDict objectForKey:itemIdentifier];
	newItem = [[[[item class] alloc] initWithItemIdentifier:itemIdentifier] autorelease];

    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view] != NULL) {
		//For a toolbar only used in one window at a time, it's alright for a view to not allow copying
		if ([[item view] respondsToSelector:@selector(copyWithZone:)]) {
			[newItem setView:[[[item view] copy] autorelease]];
		} else {
			[newItem setView:[item view]];
		}
    } else {
        [newItem setImage:[item image]];
    }
	
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
	
    //If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    //view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view] != NULL) {
        [newItem setMinSize:[item minSize]];
        [newItem setMaxSize:[item maxSize]];
		
		if ([[newItem view] respondsToSelector:@selector(setToolbarItem:)]) {
			[[newItem view] setToolbarItem:newItem];
		}
    }

    return newItem;
}

@end
