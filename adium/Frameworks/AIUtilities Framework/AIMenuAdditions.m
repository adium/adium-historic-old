/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
    while([self numberOfItems] != 1){
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

@end
