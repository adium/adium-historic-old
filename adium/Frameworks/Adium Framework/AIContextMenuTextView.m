//
//  AIContextMenuTextView.m
//  Adium
// (The AI is for AdIum) ;)
//
//  Created by Stephen Holt on Fri Apr 23 2004.

#ifdef USE_TEXTVIEW_CONTEXTMENUS
#import "AIContextMenuTextView.h"

@implementation AIContextMenuTextView

+ (NSMenu *)defaultMenu
{
    NSMenu          *superClassMenu = [NSTextView defaultMenu];
    NSMutableArray  *topItemsArray = nil;
    NSMutableArray  *bottomItemsArray = nil;
    NSEnumerator    *enumerator;
    NSArray         *menuItemArray;
        
    if(nil == topItemsArray){ //get the link editor and general actions menu items
        NSMenu  *topItems = [[[AIObject sharedAdiumInstance] menuController] contextualMenuWithLocations:[NSArray arrayWithObjects:
                                        [NSNumber numberWithInt:Context_TextView_LinkAction],
                                        [NSNumber numberWithInt:Context_TextView_General], nil]
                                forTextView:self];
        topItemsArray = [NSMutableArray arrayWithArray:[topItems itemArray]];
        [topItems removeAllItems];
    }
    
    if(nil == bottomItemsArray){ // get the emoticon menues last, so they're always in a constant location
        NSMenu  *bottomItems = [[[AIObject sharedAdiumInstance] menuController] contextualMenuWithLocations:[NSArray arrayWithObjects:
                                        [NSNumber numberWithInt:Context_TextView_EmoticonAction], nil]
                                forTextView:self];
        bottomItemsArray = [NSMutableArray arrayWithArray:[bottomItems itemArray]];
        [bottomItems removeAllItems];
    }
        
    [superClassMenu addItem:[NSMenuItem separatorItem]];
    
    if([topItemsArray count] > 0) { //add items to menu
        NSMenuItem *menuItem;
        enumerator = [topItemsArray objectEnumerator];
        while((menuItem = [enumerator nextObject])){
            [superClassMenu addItem:[menuItem copy]];
        }
    }
    
    if([bottomItemsArray count] > 0){ //add emoticon menu to menu
        NSMenuItem *menuItem;
        enumerator = [bottomItemsArray objectEnumerator];
        while((menuItem = [enumerator nextObject])){
            [superClassMenu addItem:[menuItem copy]];
        }
    }
    return [superClassMenu copy]; //return a copy of the menu
}

- (void)dealloc
{
    [[self menu] removeAllItems];
    [super dealloc];
}
@end
#endif