//
//  AISearchFieldCell.h
//  Adium
//
//  Created by Evan Schoenberg on 5/1/08.
//

#import <Cocoa/Cocoa.h>

@interface AISearchFieldCell : NSSearchFieldCell {
	NSColor *textColor;
	NSColor *backgroundColor;
}

- (void)setTextColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackgroundColor;

@end
