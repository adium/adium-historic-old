/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*!
@class AIToolbarUtilities
@abstract Helpful methods for creating window toolbar items
@discussion Methods for conveniently creating, storing, and retrieivng <tt>NSToolbarItem</tt> objects.
*/
@interface AIToolbarUtilities : NSObject {

}

/*!
	@method addToolbarItemToDictionary:withIdentifier:label:paletteLabel:toolTip:target:settingSelector:itemContent:action:menu:
	@abstract Adds a toolbar item to a dictionary
	@discussion Calls <tt>toolbarItemWithIdentifier:label:paletteLabel:toolTip:target:settingSelector:itemContent:action:menu:</tt> and adds the result to a dictionary.
	@param theDict A dictionary in which to store the <tt>NSToolbarItem</tt>
 */
+ (void)addToolbarItemToDictionary:(NSMutableDictionary *)theDict withIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target settingSelector:(SEL)settingSelector itemContent:(id)itemContent action:(SEL)action menu:(NSMenu *)menu;

/*!
	@method toolbarItemToDictionary:withIdentifier:label:paletteLabel:toolTip:target:settingSelector:itemContent:action:menu:
	@abstract Creates an <tt>NSToolbarItem</tt>
	@discussion Parameters not discussed below are simply set using the <tt>NSToolbarItem</tt> setters; see its documentation for details.
	@param settingSelector Selector to call on the <tt>NSToolbarItem</tt> after it is created.  It should take a single object, which will be <tt>itemContent</tt>.  May be nil.
	@param itemContent Object for <tt>settingSelector</tt>.  May be nil.
	@param menu	A menu to set on the NSToolbarItem.  It will be automatically encapsulated by an NSMenuItem as NSToolbarItem requires.
*/
+ (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier label:(NSString *)label paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip target:(id)target settingSelector:(SEL)settingSelector itemContent:(id)itemContent action:(SEL)action menu:(NSMenu *)menu;

/*!
	@method toolbarItemFromDictionary:withIdentifier:
	@abstract Retrieves a new copy of the NSToolbarItem stored in <tt>theDict</tt> with the <tt>itemIdentifier</tt> identifier. 
	@discussion Retrieves a new copy of the NSToolbarItem stored in <tt>theDict</tt> with the <tt>itemIdentifier</tt> identifier.  This should be used rather than simply copying the existing NSToolbarItem so custom copying behaviors to maintain custom view, image, and menu settings are utilized.
	@param theDict The source <tt>NSDictionary</tt>
	@param itemIdentifier The identifier of the NSToolbarItem previous stored with <tt>addToolbarItemToDictionary:withIdentifier:label:paletteLabel:toolTip:target:settingSelector:itemContent:action:menu:</tt>
	@result The retrieved NSToolbarItem
*/
+ (NSToolbarItem *)toolbarItemFromDictionary:(NSDictionary *)theDict withIdentifier:(NSString *)itemIdentifier;

@end

@interface NSObject (AIToolbarUtilitiesAdditions)
- (void)setToolbarItem:(NSToolbarItem *)item;
@end

