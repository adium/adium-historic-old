//
//  AIContextMenuTextView.h
//  Adium
// (The AI is for AdIum) ;)
//
//  Created by Stephen Holt on Fri Apr 23 2004.



@interface AIContextMenuTextView : NSTextView {
    AIAdium     *adium;
}

- (id)init;
- (id)initWithFrame:(NSRect)frameRect;
- (NSMenu *)contextualMenuForAISendingTextView:(NSTextView *)textView  mergeWithMenu:(NSMenu *)mergeMenu;
@end