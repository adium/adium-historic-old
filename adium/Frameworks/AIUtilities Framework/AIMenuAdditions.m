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

#import "AIMenuAdditions.h"
#import <Carbon/Carbon.h>

@implementation NSMenu (ItemCreationAdditions)

- (id <NSMenuItem>)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode
{
    NSMenuItem	*theMenuItem = [[NSMenuItem alloc] initWithTitle:aString action:aSelector keyEquivalent:charCode];
    [theMenuItem setTarget:target];

    [self addItem:theMenuItem];
    
    return([theMenuItem autorelease]);
}

- (id <NSMenuItem>)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode representedObject:(id)object
{
    NSMenuItem	*theMenuItem = [[NSMenuItem alloc] initWithTitle:aString action:aSelector keyEquivalent:charCode];
    [theMenuItem setTarget:target];
    [theMenuItem setRepresentedObject:object];

    [self addItem:theMenuItem];
    
    return([theMenuItem autorelease]);
}


- (void)removeAllItems
{
    while([self numberOfItems] != 0){
        [self removeItemAtIndex:0];
    }
}

- (void)removeAllItemsButFirst
{
    while([self numberOfItems] > 1){
        [self removeItemAtIndex:1];
    }
}

@end

@implementation NSMenuItem (ItemCreationAdditions)

- (id)initWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode
{
    if(!aString) aString = @"";
    [self initWithTitle:aString action:aSelector keyEquivalent:charCode];

    [self setTarget:target];
    
    return(self);
}

- (id)initWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode keyMask:(unsigned int)keyMask
{
    if (!aString) aString = @"";
    [self initWithTitle:aString action:aSelector keyEquivalent:charCode];

    [self setTarget:target];
    [self setKeyEquivalentModifierMask:keyMask];
    
    return self;
}

@end

//Note: AdditionsFromCarbonMenuManager require the menu item already be added to a menu. 
@interface NSMenuItem (AdditionsFromCarbonMenuManagerPRIVATE)
- (void)_setCarbonMenuItemAttributes:(MenuItemAttributes)attributes enabled:(BOOL)enabled;
- (BOOL)_hasCarbonMenuItemAttributes:(MenuItemAttributes)inAttributes;
@end

@implementation NSMenuItem (AdditionsFromCarbonMenuManager)

extern MenuRef _NSGetCarbonMenu(NSMenu *);

// Must be called after NSApp delegate's applicationDidFinishLaunching and after the menuItem is added to a menu
- (void)setDynamic:(BOOL)dynamic
{	
	[self _setCarbonMenuItemAttributes:kMenuItemAttrDynamic enabled:dynamic];
}
- (BOOL)isDynamic
{
    return ([self _hasCarbonMenuItemAttributes:kMenuItemAttrDynamic]);
}

// Must be called after NSApp delegate's applicationDidFinishLaunching and after the menuItem is added to a menu
- (void)setHidden:(BOOL)hidden
{
	[self _setCarbonMenuItemAttributes:kMenuItemAttrHidden enabled:hidden];
}
- (BOOL)isHidden
{
    return ([self _hasCarbonMenuItemAttributes:kMenuItemAttrHidden]);	
}

- (void)_setCarbonMenuItemAttributes:(MenuItemAttributes)attributes enabled:(BOOL)enabled
{
	MenuRef 	carbonMenu;
    int			itemIndex;
	
    //Get the carbon menu
    carbonMenu = _NSGetCarbonMenu([self menu]);
    itemIndex = [[self menu] indexOfItem:self] + 1;
	
    //Set its attributes
    if(enabled){
        ChangeMenuItemAttributes(carbonMenu, itemIndex, attributes, 0);
    }else{
        ChangeMenuItemAttributes(carbonMenu, itemIndex, 0, attributes);
    }
}
- (BOOL)_hasCarbonMenuItemAttributes:(MenuItemAttributes)inAttributes
{
    MenuItemAttributes 	menuItemAttributes;
    int					itemIndex;
	
    //Get the attributes
    itemIndex = [[self menu] indexOfItem:self] + 1;
    GetMenuItemAttributes(_NSGetCarbonMenu([self menu]), itemIndex, &menuItemAttributes);
	
    //	
	return (menuItemAttributes & inAttributes);
}
@end

@implementation NSMenu (AIMenuAdditions)

//Swap two menu items
+ (void)swapMenuItem:(NSMenuItem *)existingItem with:(NSMenuItem *)newItem
{
    NSMenu	*containingMenu = [existingItem menu];
    int		menuItemIndex = [containingMenu indexOfItem:existingItem];
    
    [containingMenu removeItem:existingItem];
    [containingMenu insertItem:newItem atIndex:menuItemIndex];
}

//Alternate menu items are supposed to 'collapse into' their primary item, showing only one menu item
//However, when the menu updates, they uncollapse; removing and readding both the primary and the alternate items
//makes them recollapse.
+ (void)updateAlternateMenuItem:(NSMenuItem *)alternateItem
{
    NSMenu		*containingMenu = [alternateItem menu];
    int			menuItemIndex = [containingMenu indexOfItem:alternateItem];
    NSMenuItem  *primaryItem = [containingMenu itemAtIndex:(menuItemIndex-1)];
	
	//Remove the primary item and readd it
	[primaryItem retain];
	[containingMenu removeItemAtIndex:(menuItemIndex-1)];
	[containingMenu insertItem:primaryItem atIndex:(menuItemIndex-1)];
	[primaryItem release];
	
	//Remove the alternate item and readd it
	[alternateItem retain];
    [containingMenu removeItemAtIndex:menuItemIndex];
    [containingMenu insertItem:alternateItem atIndex:menuItemIndex];
	[alternateItem release];
}

@end
