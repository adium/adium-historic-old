/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIStatusCircle.h"
#import <AIUtilities/AIUtilities.h>

#define CIRCLE_SIZE_OFFSET	(-2)
#define CIRCLE_Y_OFFSET		(1)

@interface AIStatusCircle (PRIVATE)
- (id)init;
- (NSAttributedString *)attributedString:(NSString *)inString forHeight:(float)height;
- (void)_flushDrawingCache;
@end

@implementation AIStatusCircle

+ (id)statusCircle
{
    return([[[self alloc] init] autorelease]);
}

- (id)init
{
    [super init];

    color = nil;
    flashColor = nil;
    string = nil;
    state = AICircleNormal;

    attributedString = nil;
    attributedStringSize = NSMakeSize(0,0);
    maxWidth = 0;
    cachedHeight = 0;
    
    return(self);
}

- (void)dealloc
{
    [color release];
    [flashColor release];
    [string release];
    
    [super dealloc];
}

//Set the circle state
- (void)setState:(AICircleState)inState
{
    state = inState;
}

- (void)setStringContent:(NSString *)inString
{
    if(string != inString){
        [string release];
        string = [inString retain];
        [self _flushDrawingCache];
    }
}

//Set the circle color
- (void)setColor:(NSColor *)inColor
{
    if(color != inColor){
        [color release];
        color = [inColor retain];
    }
}

//Set the alternate/flash color
- (void)setFlashColor:(NSColor *)inColor
{
    if(flashColor != inColor){
        [flashColor release];
        flashColor = [inColor retain];
    }
}


//Returns our desired width
- (float)widthForHeight:(int)inHeight
{
    if(cachedHeight != inHeight){
        [self _flushDrawingCache];
    }
    
    if(!maxWidth){
        maxWidth = [[self attributedString:@"8:88" forHeight:(inHeight + CIRCLE_SIZE_OFFSET)] size].width;
    }
    
/*    if(string){
        NSSize	stringSize = 
        
        return(stringSize.width + (inHeight + CIRCLE_SIZE_OFFSET) / 2.0);
    }else{
        return(inHeight + CIRCLE_SIZE_OFFSET);
    }*/
    return(maxWidth);
}

//Draw
- (void)drawInRect:(NSRect)inRect
{
    NSBezierPath 		*pillPath;
    float 			innerLeft, innerRight, innerTop, innerBottom, centerY, insideWidth, circleRadius, lineWidth;

/*
  innerLeft     innerRight
       |           |
       |           |
      ** ********* **      - innerTop
    **               **
   *                   *   - centerY
    **               **
      ** ********* **      - innerBottom
       |----   ----|
        insideWidth
*/

    if(cachedHeight != inRect.size.height){
        [self _flushDrawingCache];
    }

    //Calculate
    circleRadius = (inRect.size.height + CIRCLE_SIZE_OFFSET) / 2.0;    

    //Circle width
    if(string){
        //Get our attributed string and its dimensions
        if(!attributedString){
            attributedString = [[self attributedString:string forHeight:(inRect.size.height + CIRCLE_SIZE_OFFSET)] retain];
            attributedStringSize = [attributedString size];
        }
        
        //The string is inset 1/4 into each endcap
        insideWidth = (attributedStringSize.width - circleRadius) + 1.0;

        //Prevent the pill from shrinking any smaller than a perfect circle
        if(insideWidth < 0){
            insideWidth = 0;
        }
    }else{
        insideWidth = 0;
    }

    lineWidth = (circleRadius * (2.0/15.0));
    innerLeft = inRect.origin.x + inRect.size.width - circleRadius - insideWidth;
    innerRight = inRect.origin.x + inRect.size.width - circleRadius;
    innerTop = inRect.origin.y + CIRCLE_Y_OFFSET + circleRadius * 2;
    innerBottom = inRect.origin.y + CIRCLE_Y_OFFSET;
    centerY = inRect.origin.y + CIRCLE_Y_OFFSET + circleRadius;

    //Create the circle path
    pillPath = [NSBezierPath bezierPath];
        //top line (if our pill is not a circle)
        if(insideWidth != 0){
            [pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
            [pillPath lineToPoint: NSMakePoint(innerRight, innerTop)];
        }
        //right cap
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:90 endAngle:270 clockwise:YES];
        //bottom line (if our pill is not a circle)
        if(insideWidth != 0){
            [pillPath moveToPoint: NSMakePoint(innerRight, innerBottom)];
            [pillPath lineToPoint: NSMakePoint(innerLeft, innerBottom)];
        }
        //left cap
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius startAngle:270 endAngle:90 clockwise:YES];

    //draw the contents
    [((state == AICircleFlashA) ? flashColor : color) set];
    [pillPath setLineWidth:lineWidth];
    [pillPath fill];

    if(string){
        //Draw the string content
        [attributedString drawInRect:NSMakeRect(innerLeft - circleRadius + 1, //The string is already centered horizontally
                                                inRect.origin.y - 1 + CIRCLE_Y_OFFSET + (inRect.size.height - attributedStringSize.height) / 2.0, //Center vertically
                                                innerRight - innerLeft + circleRadius * 2,
                                                attributedStringSize.height)];
        
    }else{
        //draw the dot (for unreplied messages)
        if(state == AICircleDot){
            NSRect		dotRect;
            NSBezierPath 	*dotPath;
    
            dotRect = NSMakeRect(innerRight - (circleRadius*(1.0/6.0)),
                                    inRect.origin.y + (circleRadius),
                                    circleRadius*(1.0/3.0),		//1/3rd the width of the main circle
                                    circleRadius*(1.0/3.0));		//1/3rd the width of the main circle
    
            dotPath = [NSBezierPath bezierPathWithOvalInRect:dotRect];
            [dotPath setLineWidth:lineWidth];
            [[NSColor blackColor] set];
            [dotPath stroke];
        }
    
        //Draw the inner circle (for unviewed messages)
        if(state == AICircleFlashA || state == AICircleFlashB){
            NSBezierPath *insideCircle;
    
            //Create the circle path
            insideCircle = [NSBezierPath bezierPath];
            [insideCircle appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, inRect.origin.y + 1 + circleRadius) radius:(circleRadius/(2.0)) startAngle:90 endAngle:270 clockwise:YES];
            [insideCircle appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, inRect.origin.y + 1 + circleRadius) radius:(circleRadius/(2.0)) startAngle:270 endAngle:90 clockwise:YES];
    
            //Draw
            [((state == AICircleFlashA) ? color : flashColor) set];
            [insideCircle fill];
    
            [insideCircle setLineWidth:lineWidth];
            [[NSColor blackColor] set];
            [insideCircle stroke];
        }
    }

    //Draw the pill frame
    [((state == AICircleFlashA || state == AICircleFlashB) ? [NSColor blackColor] : [NSColor grayColor]) set];
    [pillPath stroke];

}

- (void)_flushDrawingCache
{
    [attributedString release]; attributedString = nil;
    attributedStringSize = NSMakeSize(0,0);
    maxWidth = 0;
}

//
- (NSAttributedString *)attributedString:(NSString *)inString forHeight:(float)height
{
    NSMutableParagraphStyle	*paragraphStyle;
    NSDictionary		*attributes;
    int				fontSize;
    
    //Create a paragraph style with the correct alignment
    paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setAlignment:NSCenterTextAlignment];

    if(height <= 9){
        fontSize = 7;
    }else if(height <= 11){
        fontSize = 8;
    }else if(height <= 13){
        fontSize = 9;
    }else{
        fontSize = 10;
    }
    
    //Create the attributed string
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor blackColor], NSForegroundColorAttributeName,
        [NSFont cachedFontWithName:@"Lucida Grande" size:fontSize], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName, nil];

    return([[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease]);
}

@end


