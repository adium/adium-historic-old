//
//  AISendingTextView.h
//  Adium
//
//  Created by Adam Iser on Thu Mar 25 2004.
//

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
- (IBAction)sendContent:(id)sender;

@end
