/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
- (NSAttributedString *)_attributedString:(NSString *)inString forHeight:(float)height;
- (NSAttributedString *)attributedStringForHeight:(float)height;
- (NSSize)attributedStringSizeForHeight:(float)height;
- (float)maxWidthForHeight:(float)height;
- (void)_flushDrawingCache;
- (float)_circleRadiusForHeight:(float)height;
- (int)_circleWidthForHeight:(float)height;
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
    bezeled = NO;
    flashColorUnique = YES;

    _attributedString = nil;
    _attributedStringSize = NSMakeSize(0,0);
    _maxWidth = 0;
    cachedHeight = 0;
    
/*    statusSquare = [[AIImageUtilities 
imageNamed:@"PlasticButtonNormal_Caps" forClass:[self class]] retain];
    [statusSquare setFlipped:YES]; */

    
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

- (void)setBezeled:(BOOL)inBezeled
{
    bezeled = inBezeled;
}

//Set the circle color
- (void)setColor:(NSColor *)inColor
{
    if(color != inColor){
        [color release];
        color = [inColor retain];

        flashColorUnique = ![color isEqual:flashColor];
    }
}

//Set the alternate/flash color
- (void)setFlashColor:(NSColor *)inColor
{
    if(flashColor != inColor){
        [flashColor release];
        flashColor = [inColor retain];

        flashColorUnique = ![color isEqual:flashColor];
    }
}

//Returns our desired width
- (float)widthForHeight:(int)inHeight computeMax:(BOOL)computeMax
{
    //If our height has changed, flush the string/rect cache
//    if(cachedHeight != inHeight + CIRCLE_SIZE_OFFSET) [self _flushDrawingCache];

    //Return the requested width
    if(computeMax){
        return([self maxWidthForHeight:inHeight]);
    }else{
        return([self _circleWidthForHeight:inHeight]);
    }    
}

//Draw
- (void)drawInRect:(NSRect)inRect
{
/*    //set up the border
    float rad = inRect.size.height * 0.5;
    NSBezierPath *aRect = [[[NSBezierPath alloc] init] autorelease];
    [aRect appendBezierPathWithArcWithCenter:NSMakePoint(inRect.origin.x + rad, inRect.origin.y + rad) radius:rad startAngle:180 endAngle:270];
    [aRect appendBezierPathWithArcWithCenter:NSMakePoint(inRect.origin.x + (inRect.size.width - rad), inRect.origin.y + rad) radius:rad startAngle:270 endAngle:0];
    [aRect appendBezierPathWithArcWithCenter:NSMakePoint(inRect.origin.x + (inRect.size.width - rad), inRect.origin.y + (inRect.size.height - rad)) radius:rad startAngle:0 endAngle:90];
    [aRect appendBezierPathWithArcWithCenter:NSMakePoint(inRect.origin.x + rad, inRect.origin.y + (inRect.size.height - rad)) radius:rad startAngle:90 endAngle:180];
    [aRect closePath];
    
    //draw bg color
    [((state == AICircleFlashA) ? flashColor : color) set];
    [aRect fill];
    
    //draw text
    NSAttributedString	*attrString = [self attributedStringForHeight:inRect.size.height];
    NSSize		stringSize = [self attributedStringSizeForHeight:inRect.size.height];
    [attrString drawInRect:NSMakeRect(inRect.origin.x, inRect.origin.y + (inRect.size.height - stringSize.height)/2, inRect.size.width, stringSize.height)];
    
   */ /* //create the background rect
    NSBezierPath *bRect = [NSBezierPath bezierPathWithRect:inRect];
    [bRect appendBezierPath:aRect];
    [bRect setWindingRule:NSEvenOddWindingRule];
    [[NSColor whiteColor] set];
    [bRect fill]; */ /*
    
    //mmmm, plastic-y
    //[statusSquare drawInRect:[aRect bounds] fromRect:NSMakeRect(2, 3, [statusSquare size].width-4, [statusSquare size].height-6) operation:NSCompositePlusDarker fraction:1.0];
    
  */ /* //create the background rect
    NSBezierPath *bRect = [NSBezierPath bezierPathWithRect:inRect];
    [bRect appendBezierPath:aRect];
    [bRect setWindingRule:NSEvenOddWindingRule];
    [[NSColor whiteColor] set];
    [bRect fill]; */ /*
    
     //pretty border
    [[[NSColor darkGrayColor] colorWithAlphaComponent:0.4] set];
    [aRect setLineWidth:(inRect.size.height * 0.25 * (2.0/15.0))];
    [aRect stroke]; */

    NSBezierPath 		*pillPath;
    float			circleRadius, circleWidth, lineWidth;
    float 			innerLeft, innerRight, innerTop, innerBottom, centerY;

    //Calculate Circle Dimensions
    circleRadius = [self _circleRadiusForHeight:inRect.size.height];
    circleWidth = [self _circleWidthForHeight:inRect.size.height];
    lineWidth = (circleRadius * (2.0/15.0));

    //Right align our circle
    inRect.origin.x += inRect.size.width - circleWidth;
    inRect.size.width = circleWidth;

    //Pre-calculate some key points
    innerLeft = inRect.origin.x + circleRadius;
    innerRight = inRect.origin.x + circleWidth - circleRadius;
    innerTop = inRect.origin.y + CIRCLE_Y_OFFSET + (circleRadius * 2.0);
    innerBottom = inRect.origin.y + CIRCLE_Y_OFFSET;
    centerY = inRect.origin.y + CIRCLE_Y_OFFSET + circleRadius;

    //Create the circle path
    pillPath = [NSBezierPath bezierPath];
        //top line (if our pill is not a circle)
        if((innerRight - innerLeft) != 0){
            [pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
            [pillPath lineToPoint: NSMakePoint(innerRight, innerTop)];
        }
        //right cap
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:90 endAngle:0 clockwise:YES];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:0 endAngle:270 clockwise:YES];
        //right cap
        //bottom line (if our pill is not a circle)
        if((innerRight - innerLeft) != 0){
            [pillPath moveToPoint: NSMakePoint(innerRight, innerBottom)];
            [pillPath lineToPoint: NSMakePoint(innerLeft, innerBottom)];
        }
        //left cap
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius startAngle:270 endAngle:180 clockwise:YES];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius startAngle:180 endAngle:90 clockwise:YES];

        
    //draw the contents
    [((state == AICircleFlashA) ? flashColor : color) set];
    [pillPath setLineWidth:lineWidth];
    [pillPath fill];

    if(string){
        NSAttributedString	*attrString = [self attributedStringForHeight:inRect.size.height];
        NSSize			stringSize = [self attributedStringSizeForHeight:inRect.size.height];
        
        //Draw the string content
        [attrString drawInRect:NSMakeRect(innerLeft - circleRadius + 1, //The string is already centered horizontally
                                          inRect.origin.y - 1 + CIRCLE_Y_OFFSET + (inRect.size.height - stringSize.height) / 2.0, //Center vertically
                                          innerRight - innerLeft + circleRadius * 2,
                                          stringSize.height)];
        
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
        if(flashColorUnique && (state == AICircleFlashA || state == AICircleFlashB || state == AICirclePreFlash)){
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

    if(bezeled){
        //Draw the pill frame
        pillPath = [NSBezierPath bezierPath];
        [pillPath moveToPoint: NSMakePoint(innerLeft - circleRadius, centerY)];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius startAngle:180 endAngle:90 clockwise:YES];

        //top line (if our pill is not a circle)
        if((innerRight - innerLeft) != 0){
            [pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
            [pillPath lineToPoint: NSMakePoint(innerRight, innerTop)];
        }
        //right cap
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:90 endAngle:0 clockwise:YES];

        [[NSColor colorWithCalibratedWhite:0.8 alpha:0.6] set];
        [pillPath stroke];


        
        pillPath = [NSBezierPath bezierPath];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:0 endAngle:270 clockwise:YES];
        //right cap
        //bottom line (if our pill is not a circle)
        if((innerRight - innerLeft) != 0){
            [pillPath moveToPoint: NSMakePoint(innerRight, innerBottom)];
            [pillPath lineToPoint: NSMakePoint(innerLeft, innerBottom)];
        }
        //left cap
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius startAngle:270 endAngle:180 clockwise:YES];
        [[NSColor colorWithCalibratedWhite:0.2 alpha:0.6] set];
        [pillPath stroke];

    }else{
        [[NSColor colorWithCalibratedWhite:0.6 alpha:0.8] set];
        [pillPath stroke];

    }

}

- (float)_circleRadiusForHeight:(float)height
{
    return( (height + CIRCLE_SIZE_OFFSET) / 2.0 );
}

- (int)_circleWidthForHeight:(float)height
{
    float	circleRadius = [self _circleRadiusForHeight:height];
    float	insideWidth;

    //Calculate Circle Dimensions
    if(string){
        //The string is inset 1/4 into each endcap
        insideWidth = ([self attributedStringSizeForHeight:height].width - circleRadius) + 1.0;

        //Prevent the pill from shrinking any smaller than a perfect circle
        if(insideWidth < 0) insideWidth = 0;

    }else{
        insideWidth = 0;
    }

    return(insideWidth + circleRadius * 2);
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
- (float)maxWidthForHeight:(float)height
{
    //If our height has changed, flush the string/rect cache
    if(cachedHeight != height + CIRCLE_SIZE_OFFSET) [self _flushDrawingCache];

    //
    if(!_maxWidth){
        _maxWidth = [[self _attributedString:@"8:88" forHeight:height + CIRCLE_SIZE_OFFSET] size].width + [self _circleRadiusForHeight:height] + 1.0;
        cachedHeight = height + CIRCLE_SIZE_OFFSET;
    }

    return(_maxWidth);
}

//Flush the cached strings and sizes
- (void)_flushDrawingCache
{
    [_attributedString release]; _attributedString = nil;
    _attributedStringSize = NSMakeSize(0,0);
    _maxWidth = 0;
}



//Private ---------------------------------------------------------------------------
//Returns the correct attributed string for our view
- (NSAttributedString *)_attributedString:(NSString *)inString forHeight:(float)height
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
    }else if(height <= 15){
        fontSize = 10;
    }else if(height <= 17){
        fontSize = 11;
    }else if(height <= 18){
        fontSize = 12;
    }else{
        fontSize = 13;
    }
    
    //Create the attributed string
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor blackColor], NSForegroundColorAttributeName,
        [NSFont cachedFontWithName:@"Lucida Grande" size:fontSize], NSFontAttributeName,
        paragraphStyle, NSParagraphStyleAttributeName, nil];

    return([[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease]);
}

@end


