//
//  ESTextViewWithPlaceholder.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Dec 26 2003.

/*!
	@class ESTextViewWithPlaceholder
	@abstract TextView with placeholder support in 10.2 and above
	@discussion <tt>NSTextView</tt> sublcass which supports placeholders, text which is displayed but greyed out when the text view is empty and unselected, even on 10.2; this is a feature which was added in 10.3.
*/

@interface ESTextViewWithPlaceholder : NSTextView {
    NSString *placeholder;
}

/*
	@method setPlaceholder:
	@abstract Set the placeholder string
	@discussion Set the placeholder string, which is text which is displayed but greyed out when the text view is empty and unselected.
	@param inPlaceholder An <tt>NSString</tt> to display as the placeholder
*/
-(void)setPlaceholder:(NSString *)inPlaceholder;

/*
	@method placeholder
	@abstract Returns the current placeholder string
	@discussion Returns the current placeholder string
	@result An <tt>NSString</tt>
*/
-(NSString *)placeholder;

@end
