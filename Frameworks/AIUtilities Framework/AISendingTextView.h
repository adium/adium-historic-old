//
//  AISendingTextView.h
//  Adium
//
//  Created by Adam Iser on Thu Mar 25 2004.
//

/*!
	@class AISendingTextView
	@abstract NSTextView which fixes issues with return and enter under high system load
	@discussion <p>When the system is busy and things slow down, characters are grouped, but keys are not.  This causes problems, since using the regular method of catching returns will not work.  The first return will come in, the current text will be sent, and then the other returns will come in (and nothing will happen since there's no text in the text view).  After the returns are processed, THEN the rest of the text will be inserted as a clump into the text view.  To the user this looks like their return was 'missed', since it gets inserted into the text view, and doesn't trigger a send.</p>
<p>This fix watches for returns in the insertText method.  However, since it's impossible to distinguish a return from an enter by the characters inserted (both insert /r, 10), it also watches and remembers the keys being pressed with interpretKeyEvents... When insertText sees a /r, it checks to see what key was pressed to generate that /r, and makes a decision to send or not.  Since the sending occurs from within insertText, the returns are processed in the correct order with the text, and the problem is illiminated.</p>
*/

@interface AISendingTextView : NSTextView {
    NSMutableArray	*returnArray;
    BOOL			insertingText;

    id				target;
    SEL				selector;
    BOOL			sendingEnabled;
	
    BOOL			sendOnEnter;
    BOOL			sendOnReturn;
	
	BOOL			nextIsReturn;
    BOOL			nextIsEnter;
    BOOL			optionPressedWithNext;
	
}

- (void)setSendingEnabled:(BOOL)inBool;
- (BOOL)isSendingEnabled;
- (void)setSendOnReturn:(BOOL)inBool;
- (void)setSendOnEnter:(BOOL)inBool;
- (void)setTarget:(id)inTarget action:(SEL)inSelector;

@end

@interface AISendingTextView (PRIVATE_AISendingTextViewAndSubclasses)
- (IBAction)sendContent:(id)sender;
@end