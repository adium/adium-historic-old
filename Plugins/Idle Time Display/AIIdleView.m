/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIIdleView.h"

#define CIRCLE_SIZE_OFFSET	(-2)
#define CIRCLE_Y_OFFSET		(1)

@interface AIIdleView (PRIVATE)
- (id)init;
- (NSAttributedString *)_attributedString:(NSString *)inString forHeight:(float)height;
- (NSAttributedString *)attributedStringForHeight:(float)height;
- (NSSize)attributedStringSizeForHeight:(float)height;
- (void)_flushDrawingCache;
@end

@implementation AIIdleView

+ (id)idleView
{
    return([[[self alloc] init] autorelease]);
}

- (id)init
{
    [super init];

    string = nil;
    textColor = nil;

    _attributedString = nil;
    _attributedStringSize = NSMakeSize(0,0);
    cachedHeight = 0;

    
    return(self);
}

- (void)dealloc
{
    [string release];
    [textColor release];
    [_attributedString release];
    
    [super dealloc];
}

- (void)setColor:(NSColor *)inColor
{
    if(textColor != inColor){
        [textColor release];
        textColor = [inColor retain];
    }    
}

//
- (void)setStringContent:(NSString *)inString
{
    if(string != inString){
        [string release];
        string = [inString retain];
        [self _flushDrawingCache];
    }
}

//Returns our desired width
- (float)widthForHeight:(int)inHeight
{
    return([self attributedStringSizeForHeight:inHeight].width + 1.0);
}

//Draw
- (void)drawInRect:(NSRect)inRect
{
    //Draw our string
    [[self attributedStringForHeight:inRect.size.height] drawInRect:inRect];
}


//(inRect.size.height + CIRCLE_SIZE_OFFSET) ((inHeight + CIRCLE_SIZE_OFFSET))
//Cached ------------------------------------------------------------------------
//Returns our content attributed string (Cached)
- (NSAttributedString *)attributedStringForHeight:(float)height
{
    //Adjust the height
    height += CIRCLE_SIZE_OFFSET;
    
    //If our height has changed, flush the string/rect cache
    if(cachedHeight != height) [self _flushDrawingCache];

    //Get our attributed string and its dimensions
    if(!_attributedString){
        _attributedString = [[self _attributedString:string forHeight:height] retain];
        cachedHeight = height;
    }

    return(_attributedString);
}

//Return our content string's size (Cached)
- (NSSize)attributedStringSizeForHeight:(float)height
{
    //If our height has changed, flush the string/rect cache
    if(cachedHeight != height + CIRCLE_SIZE_OFFSET) [self _flushDrawingCache];

    //
    if(!_attributedStringSize.width || !_attributedStringSize.height){
        _attributedStringSize = [[self attributedStringForHeight:height] size];
    }

    return(_attributedStringSize);
}

//Return our max width (Cached)
/*- (float)maxWidthForHeight:(float)height
{
    //If our height has changed, flush the string/rect cache
    if(cachedHeight != height + CIRCLE_SIZE_OFFSET) [self _flushDrawingCache];

    //
    if(!_maxWidth){
        _maxWidth = [[self _attributedString:@"8:88" forHeight:height + CIRCLE_SIZE_OFFSET] size].width;
        cachedHeight = height + CIRCLE_SIZE_OFFSET;
    }

    return(_maxWidth);
}*/

//Flush the cached strings and sizes
- (void)_flushDrawingCache
{
    [_attributedString release]; _attributedString = nil;
    _attributedStringSize = NSMakeSize(0,0);
}



//Private ---------------------------------------------------------------------------
//Returns the correct attributed string for our view
- (NSAttributedString *)_attributedString:(NSString *)inString forHeight:(float)height
{
    NSDictionary		*attributes;
    int				fontSize;
    
    //Create a paragraph style with the correct alignment
    if(height <= 9){
        fontSize = 8;
    }else if(height <= 11){
        fontSize = 9;
    }else if(height <= 13){
        fontSize = 10;
    }else if(height <= 15){
        fontSize = 11;
    }else if(height <= 17){
        fontSize = 12;
    }else if(height <= 18){
        fontSize = 13;
    }else{
        fontSize = 14;
    }
    
    //Create the attributed string
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        textColor, NSForegroundColorAttributeName,
        [NSFont cachedFontWithName:@"Lucida Grande" size:fontSize], NSFontAttributeName,
        [NSParagraphStyle styleWithAlignment:NSRightTextAlignment], NSParagraphStyleAttributeName, nil];

    return([[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease]);
}

@end


