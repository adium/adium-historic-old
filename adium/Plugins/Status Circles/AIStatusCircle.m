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

@implementation AIStatusCircle

+ (id)statusCircleWithColor:(NSColor *)inColor
{
    return([[[self alloc] initWithColor:inColor] autorelease]);
}

- (id)initWithColor:(NSColor *)inColor
{
    [super init];

    color = [inColor retain];

    return(self);
}

- (void)dealloc
{
    [color release];

    [super dealloc];
}


- (int)widthForHeight:(int)inHeight
{
    return(inHeight - 2);
}

- (void)drawInRect:(NSRect)inRect
{
    NSBezierPath 		*pillPath;
    float 			innerLeft, innerRight, innerTop, innerBottom, centerY, insideWidth, circleRadius;

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


    [pillPath setLineWidth:(circleRadius * (2.0/15.0))]; // 2/15ths of the circle size

    //draw the contents
    [color set];
    [pillPath fill];
    
    //draw the pill frame
    [[NSColor grayColor] set];
    [pillPath stroke];





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






}









@end












