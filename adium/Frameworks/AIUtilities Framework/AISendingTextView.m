//
//  AISendingTextView.m
//  Adium
//
//  Created by Adam Iser on Thu Mar 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AISendingTextView.h"

@implementation AISendingTextView

//What's going on in here?
//
//When the system is busy and things slow down, characters are grouped, but keys are not.  This causes problems,
//since using the regular method of catching returns will not work.  The first return will come in, the current
//text will be sent, and then the other returns will come in (and nothing will happen since there's no text in the
//text view).  After the returns are processed, THEN the rest of the text will be inserted as a clump into the text
//view.  To the user this looks like their return was 'missed', since it gets inserted into the text view, and doesn't
//trigger a send.
//
//This fix watches for returns in the insertText method.  However, since it's impossible to distinguish a return from
//an enter by the characters inserted (both insert /r, 10), it also watches and remembers the keys being pressed with
//interpretKeyEvents... When insertText sees a /r, it checks to see what key was pressed to generate that /r, and makes
//a decision to send or not.  Since the sending occurs from within insertText, the returns are processed in the correct
//order with the text, and the problem is illiminated.
//
//Init the text view
- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    returnArray = [[NSMutableArray alloc] init];
    sendOnReturn = YES;
	nextIsReturn = NO;
	sendOnEnter = YES;
	nextIsEnter = NO;
	optionPressedWithNext = NO;
    target = nil;
    selector = nil;
    sendingEnabled = YES;

    return(self);
}

//If true we will invoke selector on target when a send key is pressed
- (void)setSendingEnabled:(BOOL)inBool
{
    sendingEnabled = inBool;
}
- (BOOL)isSendingEnabled{
    return(sendingEnabled);
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
- (void)setTarget:(id)inTarget action:(SEL)inSelector
{
    target = inTarget;
    selector = inSelector;
}

//Send messages on a command-return
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	NSString *charactersIgnoringModifiers = [theEvent charactersIgnoringModifiers];
    if([charactersIgnoringModifiers length] && [charactersIgnoringModifiers characterAtIndex:0] == '\r'){
		if(sendingEnabled) [self sendContent:nil];
		return(YES);
	}else{
		return(NO);
	}
}

//Catch new lines as they're inserted
/*
- (void)insertText:(id)aString
{
    BOOL 		insertText = YES;
	NSString	*theString;
	
	if([aString isKindOfClass:[NSString class]]){
        theString = aString;
    }else if([aString isKindOfClass:[NSAttributedString class]]){
        theString = [aString string];
    }
	
    //Catch newlines as they're inserted
	NSLog(@"inserting \"%@\" (%i)",theString,[theString length]);
	int length = [theString length];
	if (length){
		if([theString characterAtIndex:0] == 10){
			NSLog(@"return with returnArray: %@",returnArray);
			if([returnArray count]){
				
				if([[returnArray objectAtIndex:0] boolValue]){ //if the return should send
					if(sendingEnabled) [self sendContent:nil]; //Send the content
					insertText = NO;
				}
				[returnArray removeObjectAtIndex:0]; //remove the return
			}
		}else if (length > 1){
			if([returnArray count]){
//				[returnArray removeObjectAtIndex:0]; //remove the return
				[returnArray removeAllObjects];
				NSLog(@"*** return array becomes: %@",returnArray);

			}
		}
	}

	if(insertText) [super insertText:aString];
}
*/

// special characters only work at the end of a string of input
- (void)insertText:(id)aString
{
	BOOL 		insertText = YES;
	NSString	*theString;
	
	if([aString isKindOfClass:[NSString class]]){
        theString = aString;
    }else if([aString isKindOfClass:[NSAttributedString class]]){
        theString = [aString string];
    }
	
	if([theString hasSuffix:@"\n"] && !optionPressedWithNext){
		if ((nextIsReturn && sendOnReturn) || (nextIsEnter && sendOnEnter)) {
			
			//Make sure we insert any applicable text first
			if ([theString length] > 1) {
				
				NSRange range = NSMakeRange(0,[theString length]-1);
				if([aString isKindOfClass:[NSString class]]){
					[super insertText:[aString substringWithRange:range]];
				}else if([aString isKindOfClass:[NSAttributedString class]]){
					[super insertText:[aString attributedSubstringFromRange:range]];
				}
			}
			
			//Now send
			if(sendingEnabled) [self sendContent:nil]; //Send the content
			insertText = NO;
		}
	}
	
	if(insertText) [super insertText:aString];
}


/*
//Catch returns and enters as they're pressed
- (void)interpretKeyEvents:(NSArray *)eventArray
{
    int 	index = 0;
    BOOL 	send;
    if ([eventArray count] > 1) NSLog(@"Got %i events:",[eventArray count]);
    while(index < [eventArray count]){
        NSEvent		*theEvent = [eventArray objectAtIndex:index];
        unsigned short 	keyCode = [theEvent keyCode];

		NSString *charactersIgnoringModifiers = [theEvent charactersIgnoringModifiers];
		NSString *characters = [theEvent characters];
		
		if([charactersIgnoringModifiers length]) {
			
//			unichar key = [charactersIgnoringModifiers characterAtIndex:0];
			unichar key = [characters characterAtIndex:0];      
			// get flags and strip the lower 16 (device dependant) bits
			unsigned int flags = ( [theEvent modifierFlags] & 0x00FF );
			
			switch (key){
				case NSParagraphSeparatorCharacter:
					NSLog(@"NSParagraphSeparatorCharacter");
					break;
				case NSLineSeparatorCharacter:
					NSLog(@"NSLineSeparatorCharacter");
					break;
				case NSFormFeedCharacter:
					NSLog(@"NSFormFeedCharacter");
					break;
				case NSNewlineCharacter:
					NSLog(@"NSNewlineCharacter");
					break;
				case NSCarriageReturnCharacter:
					NSLog(@"NSCarriageReturnCharacter");
					break;	
					
				case NSEnterCharacter:
					NSLog(@"NSEnterCharacter");
					break;	
			}
			
			NSLog(@"keyCode is %i (%i)",keyCode,(keyCode == 36 || keyCode == 76 || keyCode == 52));
			// NSEnterCharacter - enter
			// NSCarriageReturnCharacter - return
			//NSLog(@"delay 'em? %i",[[NSInputManager currentInputManager] wantsToDelayTextChangeNotifications]);
			if(keyCode == 36 || keyCode == 76 || keyCode == 52){ //if return or enter is pressed
				if([theEvent optionKey]){ //if option is pressed as well, the return always goes through
					[returnArray addObject:[NSNumber numberWithBool:NO]];
				}else{
					send = ((keyCode == 36 && sendOnReturn) || ((keyCode == 76 || keyCode == 52) && sendOnEnter));
					[returnArray addObject:[NSNumber numberWithBool:send]];
				}
			}
		}
		index++;
	}
	
	[super interpretKeyEvents:eventArray];
}
*/


- (void)interpretKeyEvents:(NSArray *)eventArray
{
	int 	index = 0;
		
    while(index < [eventArray count]){

		NSEvent		*theEvent = [eventArray objectAtIndex:index];
		
        if ([theEvent type] == NSKeyDown) {
            unichar lastChar = [[theEvent charactersIgnoringModifiers]
                                characterAtIndex:[[theEvent charactersIgnoringModifiers] length]-1];
            if (lastChar == NSCarriageReturnCharacter) {
                nextIsEnter = NO;
				nextIsReturn = YES;
/*
                if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
                    _sendNextRet=YES;
                } else {
                    _sendNextRet=NO;
                }
*/				
				optionPressedWithNext = ([theEvent modifierFlags] & NSAlternateKeyMask);

            } else if (lastChar == NSEnterCharacter) {
                nextIsReturn = NO;
                nextIsEnter = YES;
				
                optionPressedWithNext = ([theEvent modifierFlags] & NSAlternateKeyMask);
            }
        }
		
		index++;
    }
	
    [super interpretKeyEvents:eventArray];
}

//'Send' our content
- (IBAction)sendContent:(id)sender
{
    //Notify our target
    [target performSelector:selector];
}

@end
