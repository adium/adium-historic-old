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

@interface NSMenu (ItemCreationAdditions)

- (id <NSMenuItem>)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode;
- (id <NSMenuItem>)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode representedObject:(id)object;
- (void)removeAllItems;
- (void)removeAllItemsButFirst;

@end

@interface NSMenu (AIMenuAdditions)

- (void)setAllMenuItemsToState:(int)state;

//Swap two menu items
+ (void)swapMenuItem:(NSMenuItem *)existingItem with:(NSMenuItem *)newItem;

//Recollapse an alternate menu item
+ (void)updateAlternateMenuItem:(NSMenuItem *)alternateItem;
@end

@interface NSMenuItem (ItemCreationAdditions)

- (id)initWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode;
- (id)initWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector keyEquivalent:(NSString *)charCode keyMask:(unsigned int)keyMask;

@end

//Note: AdditionsFromCarbonMenuManager require the menu item already be added to a menu. 
@interface NSMenuItem (AdditionsFromCarbonMenuManager)
- (void)setDynamic:(BOOL)dynamic;
- (BOOL)isDynamic;
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
@end
