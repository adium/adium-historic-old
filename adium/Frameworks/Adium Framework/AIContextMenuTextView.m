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
                NSArray                 *itemsArray = nil;
                NSEnumerator    *enumerator;
                NSMenuItem              *menuItem;
                
                //Grab NSTextView's default menu, copying so we don't mess effect menus elsewhere
                contextualMenu = [[super defaultMenu] copy];
                
                //Retrieve the items which should be added to the bottom of the default menu
                NSMenu  *adiumMenu = [[[AIObject sharedAdiumInstance] menuController] contextualMenuWithLocations:[NSArray arrayWithObjects:
                        [NSNumber numberWithInt:Context_TextView_LinkAction],
                        [NSNumber numberWithInt:Context_TextView_General],
                        [NSNumber numberWithInt:Context_TextView_EmoticonAction], nil]
                                                                                                                                                                                          forTextView:self];
                itemsArray = [adiumMenu itemArray];
                
                if([itemsArray count] > 0) {
                        [contextualMenu addItem:[NSMenuItem separatorItem]];
                        int i = [(NSMenu *)contextualMenu numberOfItems];
                        enumerator = [itemsArray objectEnumerator];
                        while((menuItem = [enumerator nextObject])){
                                //[contextualMenu addItem:[[menuItem copy] autorelease]];
                                [adiumMenu removeItem:menuItem];
                                [(NSMenu *)contextualMenu insertItem:[[menuItem copy] autorelease] atIndex:i++];
                        }
                }
        }
        
    return contextualMenu; //return the menu
}

- (void)textDidChange:(NSNotification *)notification
{
    if((0 == [self selectedRange].location) && (0 == [self selectedRange].length)){ //remove attributes if we're changing text at (0,0)
        NSMutableDictionary *textAttribs = [[[NSMutableDictionary alloc] initWithDictionary:[self typingAttributes]] autorelease];
        if([textAttribs objectForKey:NSLinkAttributeName]){ // but only if we currently have a link there.
            [textAttribs removeObjectsForKeys:[NSArray arrayWithObjects:NSLinkAttributeName, //the link
                                                                        NSUnderlineStyleAttributeName, //the line
                                                                        NSForegroundColorAttributeName, //the blue
                                                                        nil]]; //the myth
            [self setTypingAttributes:textAttribs];
        }
    }
}

/*
- (void)dealloc
{
    [[self menu] removeAllItems];
    [super dealloc];
}
*/
@end