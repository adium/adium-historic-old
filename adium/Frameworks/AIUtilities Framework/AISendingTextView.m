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

#import "AISendingTextView.h"
#import "AIDictionaryAdditions.h"

#define MAX_HISTORY			25
#define ENTRY_TEXTVIEW_PADDING		6

@interface AISendingTextView (PRIVATE)
- (void)dealloc;
- (void)_sendContent;
- (void)_historyUp;
- (void)_historyDown;
- (void)_pushContent;
- (void)_popContent;
- (void)_setPushIndicatorVisible:(BOOL)visible;
- (void)_positionIndicator:(NSNotification *)notification;
@end

/*
    A text view that notifies it's target when return or enter is pressed.

    What's going on in here?
    
    When the system is busy and things slow down, characters are grouped, but keys are not.  This causes problems, since using the regular method of catching returns will not work.  The first return will come in, the current text will be sent, and then the other returns will come in (and nothing will happen since there's no text in the text view).  After the returns are processed, THEN the rest of the text will be inserted as a clump into the text view.  To the user this looks like their return was 'missed', since it gets inserted into the text view, and doesn't trigger a send.
    
    This fix watches for returns in the insertText method.  However, since it's impossible to distinguish a return from an enter by the characters inserted (both insert /r, 10), it also watches and remembers the keys being pressed with interpretKeyEvents... When insertText sees a /r, it checks to see what key was pressed to generate that /r, and makes a decision to send or not.  Since the sending occurs from within insertText, the returns are processed in the correct order with the text, and the problem is illiminiated.
*/

static NSImage *pushIndicatorImage = nil;

@implementation AISendingTextView

//Init the text view
- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    //
    adium = [AIObject sharedAdiumInstance];
    target = nil;
    selector = nil;
    chat = nil;
    indicator = nil;
    sendOnReturn = YES;
    sendOnEnter = YES;
	pushPop = YES;
    insertingText = NO;
    returnArray = [[NSMutableArray alloc] init];
    historyArray = [[NSMutableArray alloc] initWithObjects:@"",nil];
    pushArray = [[NSMutableArray alloc] init];
    availableForSending = YES;
    currentHistoryLocation = 0;
    [self setDrawsBackground:YES];
    _desiredSizeCached = NSMakeSize(0,0);

	//
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_PUSH_PREFS];

    //
    if(!pushIndicatorImage) pushIndicatorImage = [[AIImageUtilities imageNamed:@"stackImage" forClass:[self class]] retain];

    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:self];

    return(self);
}

//If true we will invoke selector on target when a send key is pressed
- (void)setAvailableForSending:(BOOL)inBool
{
    availableForSending = inBool;
}
- (BOOL)availableForSending{
    return(availableForSending);
}

//Configure the send keys
- (void)setSendOnReturn:(BOOL)inBool
{
    sendOnReturn = inBool;
}
- (void)setSendOnEnter:(BOOL)inBool
{
    sendOnEnter = inBool;
}

//Configure the push/pop behavior
- (void)setPushPop:(BOOL)inBool
{
	pushPop = inBool;
}

//Selector and target to invoke on send
- (void)setTarget:(id)inTarget action:(SEL)inSelector
{
    target = inTarget;
    selector = inSelector;
}

//Send messages on a command-return
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    BOOL result = NO;
	
    unichar theChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    //check for command-return to send the message
    switch (theChar)
    {
	case '\r':
	    if(availableForSending) [self _sendContent]; //Send the content
	    result = YES;
		break;
	case '\E':
	    //Reset entry
	    [self setString:@""];
		
	    if( [[prefDict objectForKey:KEY_AUTOPOP] boolValue] )
	     	[self _popContent];
			
	    result = YES;
	    break;
    }
    return(result);
}

//Catch new lines as they're inserted
- (void)insertText:(id)aString
{
    NSString 	*theString = nil;
    BOOL 	insertText = YES;

    if([aString isKindOfClass:[NSString class]]){
        theString = aString;
    }else if([aString isKindOfClass:[NSAttributedString class]]){
        theString = [aString string];
    }

    //Catch newlines as they're inserted
    if([theString length] && [theString characterAtIndex:0] == 10){
//        NSParameterAssert([returnArray count] != 0);
        if ([returnArray count]){
            
            if([[returnArray objectAtIndex:0] boolValue]){ //if the return should send
                if(availableForSending) [self _sendContent]; //Send the content
                insertText = NO;
            }
            
            [returnArray removeObjectAtIndex:0]; //remove the return
        }
    }

    if(insertText){
        insertingText = YES; //insertText will cause our text changed method to get posted.  In this case, we can avoid calling contentsChangedInTextEntryView, and call stringAdded:toTextEntryView instead.  To make this happen, our textDidChange method checks for the insertingText flag, and doesn't call contentsChanged if YES.
        [super insertText:aString];
        insertingText = NO;
    }

    //Let Adium know we've adding content
    [[adium contentController] stringAdded:theString toTextEntryView:self];
}

//Catch returns and enters as they're pressed
- (void)interpretKeyEvents:(NSArray *)eventArray
{
    int 	index = 0;
    BOOL 	send;
    
    while(index < [eventArray count]){
        NSEvent		*theEvent = [eventArray objectAtIndex:index];
        unsigned short 	keyCode = [theEvent keyCode];
        
        if(keyCode == 36 || keyCode == 76 || keyCode == 52){ //if return or enter is pressed
            if([theEvent optionKey]){ //if option is pressed as well, the return always goes through
                [returnArray addObject:[NSNumber numberWithBool:NO]];
        
            }else{
                send = ((keyCode == 36 && sendOnReturn) || ((keyCode == 76 || keyCode == 52) && sendOnEnter));
                
                [returnArray addObject:[NSNumber numberWithBool:send]];
            }
        }
        
        index++;
    }

    [super interpretKeyEvents:eventArray];
}

//Notify our target that our content should be sent
- (void)_sendContent
{
    //Add to history
    [historyArray insertObject:[[[self textStorage] copy] autorelease] atIndex:1];
    if([historyArray count] > MAX_HISTORY){
        [historyArray removeLastObject];
    }
    currentHistoryLocation = 0; //Move back to bottom of history

    //notify target
    [target performSelector:selector];
	
	if( [[prefDict objectForKey:KEY_AUTOPOP] boolValue] )
		[self _popContent];

}

// Required protocol methods --------------------------------------------------------
//
- (NSAttributedString *)attributedString
{
    return([self textStorage]);
}

//
- (void)setAttributedString:(NSAttributedString *)inAttributedString
{
    int		length = [inAttributedString length];
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

//
- (void)setString:(NSString *)string
{
    [super setString:string];

    //Notify everyone that our text changed
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
    [[adium contentController] contentsChangedInTextEntryView:self];
}

//
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


//History --------------------------------------------------------------------
//Move up through the history
- (void)_historyUp
{
    if(currentHistoryLocation == 0){ //Store current message
        [historyArray replaceObjectAtIndex:0 withObject:[[self textStorage] copy]];
    }

    if(currentHistoryLocation < [historyArray count]-1){
        //Move up
        currentHistoryLocation++;

        //Display history
        [self setAttributedString:[historyArray objectAtIndex:currentHistoryLocation]];
    }
}

//Move down through history
- (void)_historyDown
{
    if(currentHistoryLocation > 0){
        //Move down
        currentHistoryLocation--;

        //Display history
        [self setAttributedString:[historyArray objectAtIndex:currentHistoryLocation]];
	}
}

//Push and Pop -----------------------------------------------------------------

// Pop into the message entry field
- (void)_popContent
{
	if([pushArray count] && pushPop){
        [self setAttributedString:[pushArray lastObject]];
		[self setSelectedRange:NSMakeRange([[self textStorage] length], 0)]; //selection to end
        [pushArray removeLastObject];
        if([pushArray count] == 0){
            [self _setPushIndicatorVisible:NO];
        }
    }
	
}

// Push out of the message entry field
- (void)_pushContent
{
	if([[self textStorage] length] != 0 && pushPop){
		[pushArray addObject:[[self textStorage] copy]];
		[self setString:@""];
		[self _setPushIndicatorVisible:YES];
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
        [indicator setImage:[AIImageUtilities imageNamed:@"stackImage" forClass:[self class]]];
        [indicator setImagePosition:NSImageOnly];
		[indicator setBezelStyle:NSRegularSquareBezelStyle];
		[indicator setBordered:NO];
        [[self superview] addSubview:indicator];
		[indicator setTarget:self];
		[indicator setAction:@selector(_popContent)];
		
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



//Contact menu ---------------------------------------------------------------
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


//Auto Sizing --------------------------------------------------------------------------
//Returns our desired size
- (NSSize)desiredSize
{
    if(_desiredSizeCached.width == 0){
        float 		textHeight;

        if([[self textStorage] length] != 0){
            //If there is text in this view, let the container tell us its height
            [[self layoutManager] glyphRangeForTextContainer:[self textContainer]]; //Force glyph generation.  We must do this or usedRectForTextContainer might only return a rect for a portion of our text.
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

//Post a size changed notification (if necessary)
- (void)textDidChange:(NSNotification *)notification
{
    //Let observers know our text changed (unless it was changed by text insertion, which they'll already have known about)
    if(!insertingText){ 
        [[adium contentController] contentsChangedInTextEntryView:self];
    }

    
    //Reset cache
    _desiredSizeCached = NSMakeSize(0,0); 

    //Post notification if size changed
    if(!NSEqualSizes([self desiredSize], lastPostedSize)){
        [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self];
        lastPostedSize = [self desiredSize];
    }
}


//Keyboard navigation ------------------------------------------------------------------------
//Page up or down in the message view
- (void)scrollPageUp:(id)sender
{
    if([messageScrollView respondsToSelector:@selector(pageUp:)]){
		[messageScrollView pageUp:nil];
    }
}
- (void)scrollPageDown:(id)sender
{
    if([messageScrollView respondsToSelector:@selector(pageDown:)]){
		[messageScrollView pageDown:nil];
    }
}

- (void)keyDown: (NSEvent*) inEvent
{
	unichar inChar; // eevyl: fix to prevent crash when entering accented chars
	if ([[inEvent charactersIgnoringModifiers] isEqualToString:@""]) {
		[super keyDown:inEvent];
	} else {
		inChar = [[inEvent charactersIgnoringModifiers] characterAtIndex:0];
	
		unsigned int flags = [inEvent modifierFlags];
		//We have to test ctrl before option, because otherwise we'd miss ctrl-option-* events
		if(flags & NSControlKeyMask)
		{
			if(inChar == NSUpArrowFunctionKey)
				[self _popContent];
			else if(inChar == NSDownArrowFunctionKey)
				[self _pushContent];
			else if(inChar == 's')
			{
				if( pushPop ) {
					// Is there text?
					NSAttributedString *tempMessage = nil;
					NSAttributedString *tempPush = nil;
					
					if( [[self textStorage] length] != 0 ){
						tempMessage = [[self textStorage] copy];
					}
					
					if( [pushArray count] )
						[self _popContent];
					else
						[self setString:@""];
					
					if( tempMessage ) {
						[pushArray addObject:tempMessage];
						[self _setPushIndicatorVisible:YES];
					}
				}
			}
			else
				[super keyDown:inEvent];
		}
		else if(flags & NSAlternateKeyMask)
		{
			if(inChar == NSUpArrowFunctionKey)
				[self _historyUp];
			else if(inChar == NSDownArrowFunctionKey)
				[self _historyDown];
			else
				[super keyDown:inEvent];
		}
		else if(flags & NSCommandKeyMask)
		{
			if(inChar == NSUpArrowFunctionKey)
			{
				NSRect visibleRect = [messageScrollView documentVisibleRect];
				visibleRect.origin.y -= [messageScrollView verticalLineScroll]*2;
				[[messageScrollView documentView] scrollRectToVisible:visibleRect]; 
			}
			else if(inChar == NSDownArrowFunctionKey)
			{
				NSRect visibleRect = [messageScrollView documentVisibleRect];
				visibleRect.origin.y += [messageScrollView verticalLineScroll]*2;
				[[messageScrollView documentView] scrollRectToVisible:visibleRect]; 
			}
			else
				[super keyDown:inEvent];
		}
		else if(inChar == NSHomeFunctionKey)
		{
			NSRect visibleRect = [messageScrollView documentVisibleRect];
			visibleRect.origin.y = 0;
			[[messageScrollView documentView] scrollRectToVisible:visibleRect]; 
		}
		else if(inChar == NSEndFunctionKey)
		{
			NSRect frame = [[messageScrollView documentView] frame];
			frame.origin.y = frame.size.height;
			frame.size.height = 0;
			[[messageScrollView documentView] scrollRectToVisible:frame];
		}
		else [super keyDown:inEvent];
	}
}



//Private ------------------------------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [chat release];
    [returnArray release]; returnArray = nil;
    [historyArray release]; historyArray = nil;
    [pushArray release]; pushArray = nil;
    [super dealloc];
}

@end
