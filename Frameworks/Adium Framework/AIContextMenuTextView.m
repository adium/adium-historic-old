//
//  AIContextMenuTextView.m
//  Adium
// (The AI is for AdIum) ;)
//
//  Created by Stephen Holt on Fri Apr 23 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIContextMenuTextView.h"

@implementation AIContextMenuTextView

+ (NSMenu *)defaultMenu
{
	NSMenu			*contextualMenu;
	
	NSArray			*itemsArray = nil;
	NSEnumerator    *enumerator;
	NSMenuItem		*menuItem;
	
	//Grab NSTextView's default menu, copying so we don't affect menus elsewhere
	contextualMenu = [[super defaultMenu] copy];
	
	//Retrieve the items which should be added to the bottom of the default menu
	NSMenu  *adiumMenu = [[[AIObject sharedAdiumInstance] menuController] contextualMenuWithLocations:[NSArray arrayWithObject:
		[NSNumber numberWithInt:Context_TextView_Edit]] forTextView:self];
	itemsArray = [adiumMenu itemArray];
	
	if([itemsArray count] > 0) {
		[contextualMenu addItem:[NSMenuItem separatorItem]];
		int i = [(NSMenu *)contextualMenu numberOfItems];
		enumerator = [itemsArray objectEnumerator];
		while((menuItem = [enumerator nextObject])){
//			[adiumMenu removeItem:menuItem];
			[contextualMenu insertItem:[[menuItem copy] autorelease] atIndex:i++];
		}
	}
	
	return([contextualMenu autorelease]);
}

- (void)textDidChange:(NSNotification *)notification
{
    if(([self selectedRange].location == 0) && ([self selectedRange].length == 0)){ //remove attributes if we're changing text at (0,0)
		NSDictionary		*currentTextAttribs = [self typingAttributes];
		
        if([currentTextAttribs objectForKey:NSLinkAttributeName]){ // but only if we currently have a link there.
			NSMutableDictionary *textAttribs;
			
			textAttribs = [[self typingAttributes] mutableCopy];

            [textAttribs removeObjectsForKeys:[NSArray arrayWithObjects:NSLinkAttributeName, //the link
                                                                        NSUnderlineStyleAttributeName, //the line
                                                                        NSForegroundColorAttributeName, //the blue
                                                                        nil]]; //the myth
            [self setTypingAttributes:textAttribs];

			[textAttribs release];
        }
    }
}

@end