/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContextMenuTextView.h"
#import "AIMenuController.h"
#import "AIObject.h"

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