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
//order with the text, and the problem is illiminiated.
//
//Init the text view
- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    returnArray = [[NSMutableArray alloc] init];
    sendOnReturn = YES;
    sendOnEnter = YES;
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
    if([theString length] && [theString characterAtIndex:0] == 10){
        if([returnArray count]){
            if([[returnArray objectAtIndex:0] boolValue]){ //if the return should send
                if(sendingEnabled) [self sendContent:nil]; //Send the content
                insertText = NO;
            }
            [returnArray removeObjectAtIndex:0]; //remove the return
        }
    }
	
    if(insertText) [super insertText:aString];
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

//'Send' our content
- (IBAction)sendContent:(id)sender
{
    //Notify our target
    [target performSelector:selector];
}

@end
