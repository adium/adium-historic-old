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

//#define CIRCLE_SIZE 16

@interface AIStatusCircle (PRIVATE)
- (id)init;
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
    state = AICircleNormal;
    
    return(self);
}

- (void)dealloc
{
    [color release];
    [flashColor release];
    
    [super dealloc];
}

//Set the circle state
- (void)setState:(AICircleState)inState
{
    state = inState;
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
- (int)widthForHeight:(int)inHeight
{
    return(inHeight - 2);
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
    //Calculate
    insideWidth = 0;
    circleRadius = (inRect.size.height - 2) / 2.0;
    lineWidth = (circleRadius * (2.0/15.0));
    innerLeft = inRect.origin.x + circleRadius;
    innerRight = inRect.origin.x + insideWidth + circleRadius;
    innerTop = inRect.origin.y + 1 + circleRadius * 2;
    innerBottom = inRect.origin.y + 1;
    centerY = inRect.origin.y + 1 + circleRadius;

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

    //draw the dot (for unreplied messages)
    if(state == AICircleDot){
        NSRect		dotRect;
        NSBezierPath 	*dotPath;

        dotRect = NSMakeRect(inRect.origin.x + (circleRadius - (circleRadius*(1.0/6.0))),
                                inRect.origin.y + (circleRadius),
                                circleRadius*(1.0/3.0),		//1/3rd the width of the main circle
                                (circleRadius*(1.0/3.0)));		//1/3rd the width of the main circle

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
        [insideCircle appendBezierPathWithArcWithCenter: NSMakePoint(inRect.origin.x + circleRadius, inRect.origin.y + 1 + circleRadius) radius:(circleRadius/(2.0)) startAngle:90 endAngle:270 clockwise:YES];
        [insideCircle appendBezierPathWithArcWithCenter: NSMakePoint(inRect.origin.x + circleRadius, inRect.origin.y + 1 + circleRadius) radius:(circleRadius/(2.0)) startAngle:270 endAngle:90 clockwise:YES];

        //Draw
        [((state == AICircleFlashA) ? color : flashColor) set];
        [insideCircle fill];

        [insideCircle setLineWidth:lineWidth];
        [[NSColor blackColor] set];
        [insideCircle stroke];
    }

    //Draw the pill frame
    [((state == AICircleFlashA || state == AICircleFlashB) ? [NSColor blackColor] : [NSColor grayColor]) set];
    [pillPath stroke];

}


@end




/*    NSBezierPath 			*pillPath = [NSBezierPath bezierPath];
    float 				innerLeft, innerRight, innerTop, innerBottom, centerY;
    NSMutableAttributedString		*idleString = nil;
    float				pillInsideWidth = 0;  // distance between to caps of the pill
    float 				circleRadius;
    BOOL				flashStatus = NO;

    circleRadius = inRect.size.height;
    circleRadius -= 2.0;
    circleRadius /= 2.0;

    //---Get the idle string---
    if(idle && STATUS_SHOW_IDLE){ 
        int idleFontSize = 9;//[[AISettings sharedInstance] intForKey:KEY_BUDDYLIST_FONT_SIZE ]-2;
        
        //---get the idle time as a string---
        idleString = [[[NSMutableAttributedString alloc] initWithString:[self idleTimeString]] autorelease];
        
        [idleString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Times" size:idleFontSize] range:NSMakeRange(0,[idleString length])];
        [idleString setAlignment:NSCenterTextAlignment range:NSMakeRange(0,[idleString length])];        
    }

    //---determine the pill width---
    if(idle && STATUS_SHOW_IDLE){
        pillInsideWidth = [idleString size].width - circleRadius;//(we pretend our string is a little bit smaller to make it stick into the pill caps)
        pillInsideWidth++;
        if(pillInsideWidth < 0){
            pillInsideWidth = 0;//we do not want our pill to shrink any smaller than a perfect circle
        }
    }else{ //otherwise we make no room inside, resulting in a perfect circle
        pillInsideWidth = 0;
    }

    if(inRect.size.width != 0){
        //---set the path's line width---
        [pillPath setLineWidth:(circleRadius * 0.13333)];
    
        //---calculate the locations of our pill parts---
        innerLeft = inRect.origin.x + circleRadius;
        innerRight = inRect.origin.x + pillInsideWidth + circleRadius;// - 1;
        innerTop = inRect.origin.y + 1 + circleRadius * 2;
        innerBottom = inRect.origin.y + 1;
        centerY = inRect.origin.y + 1 + circleRadius;
    
        //--determine the current flash status--
        switch(location){
            case ICON_BUDDYLIST:
            case ICON_MESSAGETAB:
                flashStatus = ([self unViewedMessages] != 0 && [theBuddyList flashStatus]);
            break;
            case ICON_DOCK:
                flashStatus = [[AIDockIcon sharedInstance] flashStatus];
            break;
        }
        
        //---create the pill's bezier path---
            //top line (if our pill is not a circle)
            if(pillInsideWidth != 0){
                [pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
                [pillPath lineToPoint: NSMakePoint(innerRight, innerTop)];
            }
            //right cap
            [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:90 endAngle:270 clockwise:YES];
            //bottom line (if our pill is not a circle)
            if(pillInsideWidth != 0){
                [pillPath moveToPoint: NSMakePoint(innerRight, innerBottom)];
                [pillPath lineToPoint: NSMakePoint(innerLeft, innerBottom)];
            }
            //left cap
            [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius startAngle:270 endAngle:90 clockwise:YES];
    
        //---draw the backing---
            if(onlineStatus == OFFLINE || onlineStatus == JUST_OFF){ //offline
                [[AICache COLORS_SIGNED_OFF_ICON] set];
                [pillPath fill];
            }else if(onlineStatus == ONLINE){ //online
                if(idle != 0 && away != 0){ //idle + away
                    [[AICache COLORS_IDLE_AWAY_ICON] set];
                    [pillPath fill];
                }else if(idle == 0 && away != 0){ //away, and NOT idle
                    [[AICache COLORS_AWAY_ICON] set];
                    [pillPath fill];
                }else if(idle != 0 && away == 0){ //idle, and NOT away
                    [[AICache COLORS_IDLE_ICON] set];
                    [pillPath fill];
                }else if(idle == 0 && away == 0){ //NOT idle, or away
                    if(messageTab == nil){
                        [[AICache COLORS_NORMAL_ICON] set];
                    }else{
                        if(unViewedMessages != 0){
                            if(flashStatus){
                                [[AICache COLORS_OPEN_TAB_ICON] set];
                            }else{
                                [[AICache COLORS_UNVIEWED_ICON] set];
                            }
                        }else{
                            [[AICache COLORS_OPEN_TAB_ICON] set];
                        }
                    }
                    [pillPath fill];
                }
            }else if(onlineStatus == JUST_ON){ //signed on
                [[AICache COLORS_SIGNED_ON_ICON] set];
                [pillPath fill];
            }
    
        //---draw the contents---
        if(idle != 0 && STATUS_SHOW_IDLE){ //if the buddy is idle, we draw the # of minutes
            //---draw the number of minutes this buddy has been idle
            [idleString drawInRect:NSMakeRect(inRect.origin.x+1, inRect.origin.y + ((inRect.size.height - [idleString size].height) / 2.0), pillInsideWidth + (circleRadius*2), circleRadius*2)];

        }else{ //if the buddy is not idle, we draw something else
            if(unViewedMessages != 0){ //if there are unviewed messages, draw a !
                //---Draw a flashy circle thing---
                NSBezierPath *insideCircle = [NSBezierPath bezierPath];
                [insideCircle appendBezierPathWithArcWithCenter: NSMakePoint(inRect.origin.x + circleRadius, inRect.origin.y + 1 + circleRadius) radius:(circleRadius/(2.0)) startAngle:90 endAngle:270 clockwise:YES];
                [insideCircle appendBezierPathWithArcWithCenter: NSMakePoint(inRect.origin.x + circleRadius, inRect.origin.y + 1 + circleRadius) radius:(circleRadius/(2.0)) startAngle:270 endAngle:90 clockwise:YES];
                
                [insideCircle setLineWidth:(circleRadius * 0.13333)];
    
                if(flashStatus){
                    [[AICache COLORS_UNVIEWED_ICON] set];
                    [insideCircle fill];
                }else{
                    [[AICache COLORS_OPEN_TAB_ICON] set];
                    [insideCircle fill];
                }
                
                [[NSColor blackColor] set];
                [insideCircle stroke];
            }else if(unRepliedMessages != 0){ //if there are unreplied messages, draw a dot
                //---draw a dot in the center of the pill---
                NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(inRect.origin.x + (circleRadius - (circleRadius*(1.0/6.0))),inRect.origin.y + (circleRadius),circleRadius*(1.0/3.0),(circleRadius*(1.0/3.0)))];
    
                [dot setLineWidth:(circleRadius * 0.13333)];
                [[NSColor blackColor] set];
    
                [dot stroke];
            }else{ //draw nothing in the pill
            }
        }
    
        //---draw the pill frame---
        if(messageTab == nil){
            [[NSColor grayColor] set];
        }else{        
            [[NSColor blackColor] set];
        }
        [pillPath stroke];
    }
        
    //---return the size of our pill---
    return(pillInsideWidth + circleRadius * 2.0);

*/


