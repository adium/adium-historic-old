//
//  AIContextMenuTextView.m
//  Adium
// (The AI is for AdIum) ;)
//
//  Created by Stephen Holt on Fri Apr 23 2004.

#import "AIContextMenuTextView.h"

@implementation AIContextMenuTextView

static NSMenu *contextualMenu = nil;

+ (NSMenu *)defaultMenu
{
	if (!contextualMenu){
		NSArray			*itemsArray = nil;
		NSEnumerator    *enumerator;
		NSMenuItem		*menuItem;
		
		//Grab NSTextView's default menu, copying so we don't mess effect menus elsewhere
		contextualMenu = [[NSTextView defaultMenu] copy];
		
		//Retrieve the items which should be added to the bottom of the default menu
		NSMenu  *adiumMenu = [[[AIObject sharedAdiumInstance] menuController] contextualMenuWithLocations:[NSArray arrayWithObjects:
			[NSNumber numberWithInt:Context_TextView_LinkAction],
			[NSNumber numberWithInt:Context_TextView_General],
			[NSNumber numberWithInt:Context_TextView_EmoticonAction], nil]
																							  forTextView:self];
		itemsArray = [adiumMenu itemArray];
		
		if([itemsArray count] > 0) {
			[contextualMenu addItem:[NSMenuItem separatorItem]];
			
			enumerator = [itemsArray objectEnumerator];
			while((menuItem = [enumerator nextObject])){
				[contextualMenu addItem:menuItem];
			}
		}
	}
	
    return contextualMenu; //return the menu
}

/*
- (void)dealloc
{
    [[self menu] removeAllItems];
    [super dealloc];
}
*/
@end