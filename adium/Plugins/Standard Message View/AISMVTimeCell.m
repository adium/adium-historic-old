//
//  AISMVTimeCell.m
//  Adium
//
//  Created by Adam Iser on Sun Dec 22 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AISMVTimeCell.h"
#import <AIUtilities/AIUtilities.h>

#define TIME_PADDING_L 1
#define TIME_PADDING_R 1
#define STRING_ROUNDOFF_PADDING 1


@interface AISMVTimeCell (PRIVATE)
- (AISMVTimeCell *)initTimeCellWithDate:(NSDate *)inDate format:(NSString *)inDateFormat textColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackColor font:(NSFont *)inFont;
@end

@implementation AISMVTimeCell

//Create a new cell
+ (AISMVTimeCell *)timeCellWithDate:(NSDate *)inDate format:(NSString *)inDateFormat textColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackColor font:(NSFont *)inFont
{
    return([[[self alloc] initTimeCellWithDate:inDate format:inDateFormat textColor:inTextColor backgroundColor:inBackColor font:inFont] autorelease]);
}

//Returns the last calculated cellSize (so, the last value returned by cellSizeForBounds)
- (NSSize)cellSize{
    return(cellSize);
}

//Draws this cell in the requested view and rect
- (void)drawWithFrame:(NSRect)cellFrame showTime:(BOOL)showTime inView:(NSView *)controlView
{
    //Draw our background
    if(backgroundColor){
        [backgroundColor set];
    }else{
        [[NSColor whiteColor] set];
    }
    [NSBezierPath fillRect:cellFrame];

    //Draw the time stamp
    if(showTime){
        cellFrame.size.width -= TIME_PADDING_L + TIME_PADDING_R;
        cellFrame.origin.x += TIME_PADDING_L;

        [string drawInRect:cellFrame];
    }
}

- (NSString *)timeString
{
    return([string string]);
}

//Private --------------------------------------------------------------------------------
- (AISMVTimeCell *)initTimeCellWithDate:(NSDate *)inDate format:(NSString *)inDateFormat textColor:(NSColor *)inTextColor backgroundColor:(NSColor *)inBackColor font:(NSFont *)inFont
{
    NSDateFormatter		*dateFormatter;
    NSMutableParagraphStyle	*paragraphStyle;
    NSDictionary		*attributes;
    NSSize			stringSize;

    //init
    [super init];
    backgroundColor = [inBackColor retain];

    //Create a string representation of the date
    dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:inDateFormat allowNaturalLanguage:NO] autorelease];

    paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setAlignment:NSRightTextAlignment];
    
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        inTextColor, NSForegroundColorAttributeName,
        inFont, NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName,
        nil];
    
    string = [[NSAttributedString alloc] initWithString:[dateFormatter stringForObjectValue:inDate] attributes:attributes];

    //Precalc our cell size
    stringSize = [string size];
    cellSize = NSMakeSize((int)stringSize.width + TIME_PADDING_L + TIME_PADDING_R + STRING_ROUNDOFF_PADDING, stringSize.height);
    
    return(self);
}

- (void)dealloc
{
    [backgroundColor release];
    [string release];

    [super dealloc];
}

@end
