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
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define MAX_HISTORY	25

@interface AISendingTextView (PRIVATE)
- (void)dealloc;
- (void)_sendContent;
- (void)_historyUp;
- (void)_historyDown;
@end

/*
    A text view that notifies it's target when return or enter is pressed.

    What's going on in here?
    
    When the system is busy and things slow down, characters are grouped, but keys are not.  This causes problems, since using the regular method of catching returns will not work.  The first return will come in, the current text will be sent, and then the other returns will come in (and nothing will happen since there's no text in the text view).  After the returns are processed, THEN the rest of the text will be inserted as a clump into the text view.  To the user this looks like their return was 'missed', since it gets inserted into the text view, and doesn't trigger a send.
    
    This fix watches for returns in the insertText method.  However, since it's impossible to distinguish a return from an enter by the characters inserted (both insert /r, 10), it also watches and remembers the keys being pressed with interpretKeyEvents... When insertText sees a /r, it checks to see what key was pressed to generate that /r, and makes a decision to send or not.  Since the sending occurs from within insertText, the returns are processed in the correct order with the text, and the problem is illiminiated.
*/

@implementation AISendingTextView

//Init the text view
- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    //
    target = nil;
    selector = nil;
    owner = nil;
    chat = nil;
    sendOnReturn = YES;
    sendOnEnter = YES;
    returnArray = [[NSMutableArray alloc] init];
    historyArray = [[NSMutableArray alloc] initWithObjects:@"",nil];
    pushArray = [[NSMutableArray alloc] init];
    availableForSending = YES;
    currentHistoryLocation = 0;
    [self setDrawsBackground:YES];
    _desiredSizeCached = NSMakeSize(0,0);

    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:self];

    return(self);
}

//
- (void)setOwner:(id)inOwner
{
    if(owner != inOwner){
        [owner release];
        owner = [inOwner retain];
    }
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
	    [self setString:@""];
	    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
	    result = YES;
	    break;
    }
    if([theEvent modifierFlags] & NSCommandKeyMask) { //option is being held
        switch(theChar){
            case NSUpArrowFunctionKey:
                [self _historyUp];
                result = YES;
            break;

            case NSDownArrowFunctionKey:
                [self _historyDown];
                result = YES;
	    break;
	}
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

    //Let Adium know we're adding content
    [[owner contentController] stringAdded:theString toTextEntryView:self];

    //Catch newlines as they're inserted
    if([theString length] && [theString characterAtIndex:0] == 10){
        NSParameterAssert([returnArray count] != 0);

        if([[returnArray objectAtIndex:0] boolValue]){ //if the return should send
            if(availableForSending) [self _sendContent]; //Send the content
            insertText = NO;
        }

        [returnArray removeObjectAtIndex:0]; //remove the return
    }

    if(insertText){
        [super insertText:aString];
    }
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
            if([theEvent modifierFlags] & NSAlternateKeyMask){ //if option is pressed as well, the return always goes through
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
    [historyArray insertObject:[[self textStorage] copy] atIndex:1];
    if([historyArray count] > MAX_HISTORY){
        [historyArray removeLastObject];
    }
    currentHistoryLocation = 0; //Move back to bottom of history

    //notify target
    [target performSelector:selector];

    //Pop from the push array
    if([pushArray count]){
        [[self textStorage] setAttributedString:[pushArray lastObject]];
        [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
        [self setSelectedRange:NSMakeRange([[self textStorage] length], 0)]; //selection to end
        [pushArray removeLastObject];
    }
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

    //
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];

    }else{
        //Push message
        if([[self textStorage] length] != 0){
            [pushArray addObject:[[self textStorage] copy]];
            [self setAttributedString:[[[NSAttributedString alloc] initWithString:@"" attributes:[self typingAttributes]] autorelease]];
        }
    }
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


//Auto Sizing --------------------------------------------------------------------------
//Returns our desired size
- (NSSize)desiredSize
{
    if(_desiredSizeCached.width == 0){
        float 		textHeight;

        if([[self textStorage] length] != 0){
            //If there is text in this view, let the container tell us its height
            textHeight = [[self layoutManager] usedRectForTextContainer:[self textContainer]].size.height;

        }else{
            NSAttributedString	*attrString;

            //Otherwise, we use the current typing attributes to guess what the height of a line should be
            attrString = [[[NSAttributedString alloc] initWithString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[self typingAttributes]] autorelease];
            textHeight = [attrString heightWithWidth:1e7];

        }

        _desiredSizeCached = NSMakeSize([self frame].size.width, textHeight);
    }

    return(_desiredSizeCached);
}

//Post a size changed notification (if necessary)
- (void)textDidChange:(NSNotification *)notification
{
    //Reset cache
    _desiredSizeCached = NSMakeSize(0,0); 

    //Post notification if size changed
    if(!NSEqualSizes([self desiredSize], lastPostedSize)){
        [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self];
        lastPostedSize = [self desiredSize];
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
