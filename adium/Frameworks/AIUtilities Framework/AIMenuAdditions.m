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

extern MenuRef _NSGetCarbonMenu(NSMenu *);

// Must be called after NSApp delegate's applicationDidFinishLaunching.
- (void)setDynamic:(BOOL)dynamic
{
    MenuRef 	carbonMenu;
    int 	itemIndex;

    //Get the carbon menu
    carbonMenu = _NSGetCarbonMenu([self menu]);
    itemIndex = [[self menu] indexOfItem:self] + 1;

    //Set its attributes
    if(dynamic){
        ChangeMenuItemAttributes(carbonMenu, itemIndex, kMenuItemAttrDynamic, 0);
    }else{
        ChangeMenuItemAttributes(carbonMenu, itemIndex, 0, kMenuItemAttrDynamic);
    }
}

- (BOOL)isDynamic
{
    MenuItemAttributes 	attributes;
    int 		itemIndex;

    //Get the attributes
    itemIndex = [[self menu] indexOfItem:self] + 1;
    GetMenuItemAttributes(_NSGetCarbonMenu([self menu]), itemIndex, &attributes);

    //
    return(attributes & kMenuItemAttrDynamic);
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
@end
