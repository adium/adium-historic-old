//
//  AISearchFieldCell.m
//  Adium
//
//  Created by Evan Schoenberg on 5/1/08.
//

#import "AISearchFieldCell.h"

@interface NSSearchFieldCell (SecretsIKnow)
- (void)_getTextColor:(NSColor **)outTextColor backgroundColor:(NSColor **)outBackgroundColor;
@end

@implementation AISearchFieldCell

- (void)_getTextColor:(NSColor **)outTextColor backgroundColor:(NSColor **)outBackgroundColor
{
	[super _getTextColor:outTextColor backgroundColor:outBackgroundColor];

	if (textColor)
		*outTextColor = [[textColor retain] autorelease];

	if (backgroundColor)
		*outBackgroundColor = [[backgroundColor retain] autorelease];
}

- (void)setTextColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackgroundColor
{
	if (textColor != inTextColor) {
		[textColor release];
		textColor = [inTextColor retain];
	}

	if (backgroundColor != inBackgroundColor) {
		[backgroundColor release];
		backgroundColor = [inBackgroundColor retain];
	}
	
	/* Toggle the responder chain while maintaining our selection and/or text insertion position
	 * to force the display to update. Simply calling display won't work.
	 */
	NSSearchField	*searchField = (NSSearchField *)[self controlView];
	NSText			*fieldEditor = [[searchField window] fieldEditor:NO forObject:searchField];
	NSRange			selectedRange = [fieldEditor selectedRange];

	[[searchField window] makeFirstResponder:nil];
	[[searchField window] makeFirstResponder:searchField];
	[fieldEditor setSelectedRange:selectedRange];
}

@end
