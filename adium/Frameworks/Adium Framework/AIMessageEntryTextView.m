/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIMessageEntryTextView.h"
#import "AIDictionaryAdditions.h"

#define MAX_HISTORY					25		//Number of messages to remember in history
#define ENTRY_TEXTVIEW_PADDING		6		//Padding for auto-sizing

@interface AIMessageEntryTextView (PRIVATE)
- (void)_setPushIndicatorVisible:(BOOL)visible;
- (void)_positionIndicator:(NSNotification *)notification;
- (void)_resetCacheAndPostSizeChanged;
@end

static NSImage *pushIndicatorImage = nil;

@implementation AIMessageEntryTextView

//Init the text view
- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    //
    adium = [AIObject sharedAdiumInstance];
	associatedView = nil;
    chat = nil;
    indicator = nil;
	pushPopEnabled = YES;
	clearOnEscape = NO;
    insertingText = NO;
	defaultTypingAttributes = nil;
    historyArray = [[NSMutableArray alloc] initWithObjects:@"",nil];
    pushArray = [[NSMutableArray alloc] init];
    currentHistoryLocation = 0;
    [self setDrawsBackground:YES];
    _desiredSizeCached = NSMakeSize(0,0);

    [self setAllowsUndo:YES];
        

    //
    if(!pushIndicatorImage) pushIndicatorImage = [[NSImage imageNamed:@"stackImage" forClass:[self class]] retain];

    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:self];
	
    return(self);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [chat release];
    [associatedView release];
    [defaultTypingAttributes release];
    [returnArray release]; returnArray = nil;
    [historyArray release]; historyArray = nil;
    [pushArray release]; pushArray = nil;
    [super dealloc];
}

//
- (void)keyDown:(NSEvent *)inEvent
{
	NSString *charactersIgnoringModifiers = [inEvent charactersIgnoringModifiers];
	
	if([charactersIgnoringModifiers length]) {
		unichar		 inChar = [charactersIgnoringModifiers characterAtIndex:0];
		unsigned int flags = [inEvent modifierFlags];
		
		//We have to test ctrl before option, because otherwise we'd miss ctrl-option-* events
		if(flags & NSControlKeyMask){
			if(inChar == NSUpArrowFunctionKey){
				[self popContent];
			}else if(inChar == NSDownArrowFunctionKey){
				[self pushContent];
			}else if(inChar == 's'){
				[self swapContent];
			}else{
				[super keyDown:inEvent];
			}
			
		}else if(flags & NSAlternateKeyMask){
			if(inChar == NSUpArrowFunctionKey){
				[self historyUp];
			}else if(inChar == NSDownArrowFunctionKey){
				[self historyDown];
			}else{
				[super keyDown:inEvent];
			}
			
		}else if(flags & NSCommandKeyMask){
			if(inChar == NSUpArrowFunctionKey || inChar == NSDownArrowFunctionKey){
				//Pass the associatedView a keyDown event equivalent equal to inEvent except without the modifier flags
				[associatedView keyDown:[NSEvent keyEventWithType:[inEvent type]
														 location:[inEvent locationInWindow]
													modifierFlags:nil
														timestamp:[inEvent timestamp]
													 windowNumber:[inEvent windowNumber]
														  context:[inEvent context]
													   characters:[inEvent characters]
									  charactersIgnoringModifiers:charactersIgnoringModifiers
														isARepeat:[inEvent isARepeat]
														  keyCode:[inEvent keyCode]]];
			}else{
				[super keyDown:inEvent];
			}
			
		}else if((inChar == '\E') && clearOnEscape){
			[self setString:@""];
			
		}else if(inChar == NSPageUpFunctionKey || inChar == NSPageDownFunctionKey || 
				 inChar == NSHomeFunctionKey || inChar == NSEndFunctionKey){
			[associatedView keyDown:inEvent];
			
		}else{
			[super keyDown:inEvent];
			
		}
	}else{
		[super keyDown:inEvent];
	}
}

//Text changed
- (void)textDidChange:(NSNotification *)notification
{
    //Let observers know our text changed (unless it was changed by text insertion, which they'll already have known about)
    if(!insertingText){ 
        [[adium contentController] contentsChangedInTextEntryView:self];
    }
    
    //Reset cache and resize
	[self _resetCacheAndPostSizeChanged];
}


//Configure ------------------------------------------------------------------------------------------------------------
#pragma mark Configure
//Set clears entered text on escape
- (void)setClearOnEscape:(BOOL)inBool
{
	clearOnEscape = inBool;
}

//Associate a view with this text view for key forwarding
- (void)setAssociatedView:(NSView *)inView
{
	if(inView != associatedView){
		[associatedView release];
		associatedView = [inView retain];
	}
}
- (NSView *)associatedView{
	return(associatedView);
}


//Adium Text Entry -----------------------------------------------------------------------------------------------------
#pragma mark Adium Text Entry
//Return our current string
- (NSAttributedString *)attributedString
{
    return([self textStorage]);
}

//Are we available for sending
- (BOOL)availableForSending
{
	return([self isSendingEnabled]);
}

//Set our string, preserving the selected range
- (void)setAttributedString:(NSAttributedString *)inAttributedString
{
    int			length = [inAttributedString length];
    NSRange 	oldRange = [self selectedRange];

    //Change our string
    [[self textStorage] setAttributedString:inAttributedString];

    //Restore the old selected range
    if(oldRange.location < length){
        if(oldRange.location + oldRange.length <= length){
            [self setSelectedRange:oldRange];
        }else{
            [self setSelectedRange:NSMakeRange(oldRange.location, length - oldRange.location)];       
        }
    }

    //Notify everyone that our text changed
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
    [[adium contentController] contentsChangedInTextEntryView:self];
}

//Set our string (plain text)
- (void)setString:(NSString *)string
{
    [super setString:string];

    //Notify everyone that our text changed
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
    [[adium contentController] contentsChangedInTextEntryView:self];
}

//Set our typing format
- (void)setTypingAttributes:(NSDictionary *)attrs
{
    NSColor	*backgroundColor;

    [super setTypingAttributes:attrs];

    //Correctly set our background color
    backgroundColor = [attrs objectForKey:AIBodyColorAttributeName];
    if(backgroundColor){
        [self setBackgroundColor:backgroundColor];
    }else{
        [self setBackgroundColor:[NSColor whiteColor]];
    }
}

//Paste as rich text without altering our typing attributes
- (void)pasteAsRichText:(id)sender
{
	NSDictionary	*attributes = [[[self typingAttributes] copy] autorelease];
	[super pasteAsRichText:sender];
	if(attributes) [self setTypingAttributes:attributes];
}

//Let adium know as text is inserted
- (void)insertText:(id)aString
{
    NSString 	*theString = nil;

	//We set the insertingText flag to YES to prevent out 'textDidChange' method from notifying Adium
	//about this change, since we will notify Adium in a more efficient way from this method.
	insertingText = YES;
	[super insertText:aString];
	insertingText = NO; 
	
    //Let Adium know we've adding content
    if([aString isKindOfClass:[NSString class]]){
        theString = aString;
    }else if([aString isKindOfClass:[NSAttributedString class]]){
        theString = [aString string];
    }

	[[adium contentController] stringAdded:theString toTextEntryView:self];
}


//Contact menu ---------------------------------------------------------------------------------------------------------
#pragma mark Contact menu
//Set and return the selected chat (to auto-configure the contact menu)
- (void)setChat:(AIChat *)inChat
{
    if(chat != inChat){
        [chat release];
        chat = [inChat retain];
    }
}
- (AIChat *)chat{
    return(chat);
}

//Return the selected list object (to auto-configure the contact menu)
- (AIListObject *)listObject
{
	return([chat listObject]);
}


//Auto Sizing ----------------------------------------------------------------------------------------------------------
#pragma mark Auto-sizing
//Returns our desired size
- (NSSize)desiredSize
{
    if(_desiredSizeCached.width == 0){
        float 		textHeight;

        if([[self textStorage] length] != 0){
            //If there is text in this view, let the container tell us its height
			//Force glyph generation.  We must do this or usedRectForTextContainer might only return a rect for a
			//portion of our text.
            [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];
            textHeight = [[self layoutManager] usedRectForTextContainer:[self textContainer]].size.height;

        }else{
            NSAttributedString	*attrString;

            //Otherwise, we use the current typing attributes to guess what the height of a line should be
            attrString = [[[NSAttributedString alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[self typingAttributes]] autorelease];
            textHeight = [attrString heightWithWidth:1e7];

        }

        _desiredSizeCached = NSMakeSize([self frame].size.width, textHeight + ENTRY_TEXTVIEW_PADDING);
    }

    return(_desiredSizeCached);
}

//Reset the desired size cache when our frame changes
- (void)frameDidChange:(NSNotification *)notification
{
	[self _resetCacheAndPostSizeChanged];
}

//Reset the desired size cache and post a size changed notification.  Call after the text's dimensions change
- (void)_resetCacheAndPostSizeChanged
{
	//Reset the size cache
    _desiredSizeCached = NSMakeSize(0,0);

    //Post notification if size changed
    if(!NSEqualSizes([self desiredSize], lastPostedSize)){
        [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self];
        lastPostedSize = [self desiredSize];
    }
}


//Paging ---------------------------------------------------------------------------------------------------------------
#pragma mark Paging
//Page up or down in the message view
- (void)scrollPageUp:(id)sender
{
    if([associatedView respondsToSelector:@selector(pageUp:)]){
		[associatedView pageUp:nil];
    }
}
- (void)scrollPageDown:(id)sender
{
    if([associatedView respondsToSelector:@selector(pageDown:)]){
		[associatedView pageDown:nil];
    }
}


//History --------------------------------------------------------------------------------------------------------------
#pragma mark History
//Move up through the history
- (void)historyUp
{
    if(currentHistoryLocation == 0){
		//Store current message
        [historyArray replaceObjectAtIndex:0 withObject:[[[self textStorage] copy] autorelease]];
    }
	
    if(currentHistoryLocation < [historyArray count]-1){
        //Move up
        currentHistoryLocation++;
		
        //Display history
        [self setAttributedString:[historyArray objectAtIndex:currentHistoryLocation]];
    }
}

//Move down through history
- (void)historyDown
{
    if(currentHistoryLocation > 0){
        //Move down
        currentHistoryLocation--;
		
        //Display history
        [self setAttributedString:[historyArray objectAtIndex:currentHistoryLocation]];
	}
}

//Update history when content is sent
- (IBAction)sendContent:(id)sender
{
	//Add to history
    [historyArray insertObject:[[[self textStorage] copy] autorelease] atIndex:1];
    if([historyArray count] > MAX_HISTORY){
        [historyArray removeLastObject];
    }
    currentHistoryLocation = 0; //Move back to bottom of history
	
	//Send the content
	[super sendContent:sender];
	
	//Clear the undo/redo stack as it makes no sense to carry between sends (the history is for that)
	[[self undoManager] removeAllActions];
        
	//Remove the link attribute (If present) so it doesn't bleed
	if([[self typingAttributes] objectForKey:NSLinkAttributeName]){
		NSMutableDictionary	*typingAttributes = [[[self typingAttributes] mutableCopy] autorelease];
		[typingAttributes removeObjectForKey:NSLinkAttributeName];
		[self setTypingAttributes:typingAttributes];
	}
}


//Push and Pop ---------------------------------------------------------------------------------------------------------
#pragma mark Push and Pop
//Enable/Disable push-pop
- (void)setPushPopEnabled:(BOOL)inBool
{
	pushPopEnabled = inBool;
}

//Push out of the message entry field
- (void)pushContent
{
	if([[self textStorage] length] != 0 && pushPopEnabled){
		[pushArray addObject:[[[self textStorage] copy] autorelease]];
		[self setString:@""];
		[self _setPushIndicatorVisible:YES];
	}
}

//Pop into the message entry field
- (void)popContent
{
    if([pushArray count] && pushPopEnabled){
        [self setAttributedString:[pushArray lastObject]];
        [self setSelectedRange:NSMakeRange([[self textStorage] length], 0)]; //selection to end
        [pushArray removeLastObject];
        if([pushArray count] == 0){
            [self _setPushIndicatorVisible:NO];
        }
    }
}

//Swap current content
- (void)swapContent
{
	if(pushPopEnabled){
		NSAttributedString *tempMessage = [[[self textStorage] copy] autorelease];
				
		if([pushArray count]){
			[self popContent];
		}else{
			[self setString:@""];
		}
		
		if(tempMessage && [tempMessage length] != 0){
			[pushArray addObject:tempMessage];
			[self _setPushIndicatorVisible:YES];
		}
	}
}

//Push indicator
- (void)_setPushIndicatorVisible:(BOOL)visible
{
    if(visible && !pushIndicatorVisible){
        pushIndicatorVisible = visible;
		
        //Push text over to make room for indicator
        NSSize size = [self frame].size;
        size.width -= [pushIndicatorImage size].width;
        [self setFrameSize:size];
		
		// Make the indicator and set its action. It is a button with no border.
		indicator = [[NSButton alloc] initWithFrame:
            NSMakeRect(0, 0, [pushIndicatorImage size].width, [pushIndicatorImage size].height)]; 
		[indicator setButtonType:NSMomentaryPushButton];
        [indicator setAutoresizingMask:(NSViewMinXMargin)];
        [indicator setImage:[NSImage imageNamed:@"stackImage" forClass:[self class]]];
        [indicator setImagePosition:NSImageOnly];
		[indicator setBezelStyle:NSRegularSquareBezelStyle];
		[indicator setBordered:NO];
        [[self superview] addSubview:indicator];
		[indicator setTarget:self];
		[indicator setAction:@selector(popContent)];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_positionIndicator:) name:NSViewBoundsDidChangeNotification object:[self superview]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_positionIndicator:) name:NSViewFrameDidChangeNotification object:[self superview]];
		
        [self _positionIndicator:nil]; //Set the indicators initial position
		
    }else if(!visible && pushIndicatorVisible){
        pushIndicatorVisible = visible;
		
        //Push text back
        NSSize size = [self frame].size;
        size.width += [pushIndicatorImage size].width;
        [self setFrameSize:size];
		
        //Remove indicator
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[self superview]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self superview]];
        [indicator removeFromSuperview];
        [indicator release]; indicator = nil;
    }
}

//Reposition indicator into lower right corner
- (void)_positionIndicator:(NSNotification *)notification
{
    NSRect visRect = [[self enclosingScrollView] documentVisibleRect];
    NSRect indFrame = [indicator frame];
    
    [indicator setFrameOrigin:NSMakePoint(NSMaxX(visRect) - indFrame.size.width, NSMaxY(visRect) - indFrame.size.height)];
    [[self enclosingScrollView] setNeedsDisplay:YES];
}

#pragma mark Contextual Menus

+ (NSMenu *)defaultMenu
{
	static NSMenu *contextualMenu = nil;

	if (!contextualMenu){
		NSArray			*itemsArray = nil;
		NSEnumerator	*enumerator;
		NSMenuItem		*menuItem;
		
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
                                [(NSMenu *)contextualMenu insertItem:menuItem atIndex:i++];
			}
		}
	}
	
    return contextualMenu; //return the menu
}
@end
