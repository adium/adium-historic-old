//
//  AIContextMenuTextView.m
//  Adium
// (The AI is for AdIum) ;)
//
//  Created by Stephen Holt on Fri Apr 23 2004.

#import "AIContextMenuTextView.h"

@interface AIContextMenuTextView (PRIVATE)
- (NSMenu *)_menuItemsTop;
- (NSMenu *)_menuItemsBottom;
@end

@implementation AIContextMenuTextView

- (id)init;
{
    [super init];
    adium = [AIObject sharedAdiumInstance];
    
    //set up contextual menus
    [self setMenu:[self contextualMenuForAISendingTextView:self mergeWithMenu:[self menu]]];
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    adium = [AIObject sharedAdiumInstance];
        
    //set up contextual menus
    [self setMenu:[self contextualMenuForAISendingTextView:self mergeWithMenu:[self menu]]];
}

- (NSMenu *)contextualMenuForAISendingTextView:(NSTextView *)textView  mergeWithMenu:(NSMenu *)mergeMenu
{
    NSMenu          *oldMenu;
    NSMenu          *newMenuTop = [self _menuItemsTop];
    NSMenu          *newMenuBottom = [self _menuItemsBottom];
    NSArray         *menuItems;
    NSEnumerator    *enumerator;
    NSMenuItem      *itemForInsertion;
    
    if(newMenuTop) {
        [mergeMenu addItem:[NSMenuItem separatorItem]];
        menuItems = [[newMenuTop itemArray] retain];
        enumerator = [menuItems objectEnumerator];
            while((itemForInsertion = [enumerator nextObject])) {
                [newMenuTop removeItem:itemForInsertion];
                NSLog(@"Adding: %@",[itemForInsertion title]);
                [mergeMenu addItem:itemForInsertion];
        }
    }
    
    if(newMenuBottom){
        [mergeMenu addItem:[NSMenuItem separatorItem]];
        menuItems = [newMenuBottom itemArray];
        enumerator = [menuItems objectEnumerator];
            while((itemForInsertion = [enumerator nextObject])) {
                [newMenuBottom removeItem:itemForInsertion];
                NSLog(@"Adding: %@",[itemForInsertion title]);
                [mergeMenu addItem:itemForInsertion];
        }
    }
    return(mergeMenu);
}

- (NSMenu *)_menuItemsTop
{
    return([[adium menuController] contextualMenuWithLocations:[NSArray arrayWithObject:
                                                               [NSNumber numberWithInt:Context_TextView_EmoticonAction]]
                                                   forTextView:self]);
}

- (NSMenu *)_menuItemsBottom
{
    return([[adium menuController] contextualMenuWithLocations:[NSArray arrayWithObjects:
                                            [NSNumber numberWithInt:Context_TextView_LinkAction],
                                            [NSNumber numberWithInt:Context_TextView_General], nil]
                                   forTextView:self]);
}
@end
