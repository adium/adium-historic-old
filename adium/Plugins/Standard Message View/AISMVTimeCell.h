//
//  AISMVTimeCell.h
//  Adium
//
//  Created by Adam Iser on Sun Dec 22 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AISMVTimeCell : NSCell {
    NSAttributedString	*string;

    NSSize		cellSize;
    NSColor		*backgroundColor;
    
}

+ (AISMVTimeCell *)timeCellWithDate:(NSDate *)inDate format:(NSString *)inDateFormat textColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackColor font:(NSFont *)inFont;
- (NSSize)cellSize;
- (void)drawWithFrame:(NSRect)cellFrame showTime:(BOOL)showTime inView:(NSView *)controlView;
- (NSString *)timeString;

@end
