//
//  AIAutoScrollView.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIAutoScrollView : NSScrollView {
    NSRect	oldDocumentFrame;
    
    BOOL	autoScrollToBottom;
    BOOL	autoHideScrollBar;
}

- (void)setAutoHideScrollBar:(BOOL)inValue;
- (void)setAutoScrollToBottom:(BOOL)inValue;
- (void)scrollToBottom;
- (void)setCorrectScrollbarVisibility;

@end
