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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AISCLCell.h"
#import "AISCLOutlineView.h"

#define LEFT_MARGIN		12
#define RIGHT_MARGIN		8
#define GROUP_PADDING		3
#define LEFT_VIEW_PADDING	3
#define RIGHT_VIEW_PADDING	3
#define INDENTATION_OFFSET	-7
#define CELL_SIZE_ADJUST_X	20	//Adjustment for the flippy triangles, and add some padding
#define BACK_CELL_INDENT	2

@implementation AISCLCell

- (void)setContact:(AIListObject *)inObject
{
    listObject = inObject;
    isGroup = [listObject isKindOfClass:[AIListGroup class]];
}

- (NSSize)cellSizeForBounds:(NSRect)aRect inView:(NSView *)controlView
{
    NSFont		*font;
    NSAttributedString	*displayName;
    NSSize		displayNameSize;
    //AIMutableOwnerArray	*leftViewArray, *rightViewArray;
    //int			loop;
    NSSize		cellSize = NSMakeSize(CELL_SIZE_ADJUST_X, 0);
    
    if(isGroup){ //move text away from flippy triangle
        cellSize.width += GROUP_PADDING;
    }else{ //Negate indentation
        cellSize.width += INDENTATION_OFFSET;
    }

    //Pad the right side of our view
    cellSize.width += RIGHT_MARGIN;

    //Display all 'Left Views'
/*    leftViewArray = [listObject displayArrayForKey:@"Left View"];
    if(leftViewArray && [leftViewArray count]){
        //Indent into the margin to save space
        cellSize.width -= LEFT_MARGIN;

        //Left aligned icon
        for(loop = 0;loop < [leftViewArray count];loop++){
            id <AIListObjectLeftView>	handler = [leftViewArray objectAtIndex:loop];

            cellSize.width += ([handler widthForHeight:aRect.size.height computeMax:YES] + LEFT_VIEW_PADDING);
        }
    }

    //Display all right views
    rightViewArray = [listObject displayArrayForKey:@"Right View"];
    if(rightViewArray && [rightViewArray count]){//Right aligned icon(s)
        for(loop = 0;loop < [rightViewArray count];loop++){
            id <AIListObjectLeftView>	handler = [rightViewArray objectAtIndex:loop];

            cellSize.width += ([handler widthForHeight:aRect.size.height computeMax:YES] + RIGHT_VIEW_PADDING);
        }
    }*/

    //Text Font
    font = [(AISCLOutlineView *)controlView font];

    //Add Bold for Groups
    if(isGroup){
	font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    }

    
    //string
    NSMutableString 	*displayString = [NSMutableString stringWithString:@""];
    AIMutableOwnerArray *leftTextArray = [listObject displayArrayForKey:@"Left Text"];
    AIMutableOwnerArray *rightTextArray = [listObject displayArrayForKey:@"Right Text"];
    NSString *leftText = [leftTextArray count] > 0 ? [leftTextArray objectAtIndex:0] : nil;
    NSString *rightText = [rightTextArray count] > 0 ? [rightTextArray objectAtIndex:0] : nil;
    
    if(leftText)
    {
    	[displayString appendString:leftText];
    }
    
    [displayString appendString:[listObject longDisplayName]];
    
    if(rightText)
    {
    	[displayString appendString:rightText];
    }
    
    //Name
    displayName = [[NSAttributedString alloc] initWithString:(NSString *)displayString
                                                  attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]];
    displayNameSize = [displayName size];
    cellSize.width += displayNameSize.width;
    cellSize.height += displayNameSize.height;

    return(cellSize);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSFont			*font;
    NSAttributedString		*displayName;
    NSMutableString 		*displayString;
    NSString			*rightText, *leftText;
    NSColor			*textColor, *backgroundColor = nil;
    AIMutableOwnerArray		*leftViewArray, *rightViewArray, *leftTextArray, *rightTextArray;
    NSMutableParagraphStyle	*paragraphStyle;
    int				loop;

    if(isGroup){ //move text away from flippy triangle
        cellFrame.origin.x += GROUP_PADDING;
        cellFrame.size.width -= GROUP_PADDING;
    }else{ //Negate indentation
        cellFrame.origin.x += INDENTATION_OFFSET;
        cellFrame.size.width -= INDENTATION_OFFSET;
    }
    
    //Pad the right side of our view
    cellFrame.size.width -= RIGHT_MARGIN;

    //Background Color (If this cell is selected, we don't display the background color)
    if((![self isHighlighted] || ![[controlView window] isKeyWindow] || [[controlView window] firstResponder] != controlView) && [(AISCLOutlineView *)controlView showLabels]){
        backgroundColor = [[listObject displayArrayForKey:@"Label Color"] averageColor];
    }

    //Background
    if(backgroundColor){
        int 		innerLeft, innerRight, innerTop, innerBottom;
        float 		centerY, circleRadius;
        NSBezierPath	*pillPath;

        //Calculate some points
        innerLeft = cellFrame.origin.x + BACK_CELL_INDENT;
        innerRight = cellFrame.origin.x + cellFrame.size.width - BACK_CELL_INDENT;
        innerTop = cellFrame.origin.y;
        innerBottom = cellFrame.origin.y + cellFrame.size.height;
        circleRadius = -(innerTop - innerBottom) / 2.0;
        centerY = (innerTop + innerBottom) / 2.0;
        
        //Create the circle path
        pillPath = [NSBezierPath bezierPath];
        [pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
        [pillPath lineToPoint: NSMakePoint(innerRight, innerTop)];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:270 endAngle:90 clockwise:NO];
        [pillPath lineToPoint: NSMakePoint(innerLeft, innerBottom)];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius startAngle:90 endAngle:270 clockwise:NO];

        //Draw
        [backgroundColor set];
        [pillPath fill];
    }

    //Display all 'Left Views'
    leftViewArray = [listObject displayArrayForKey:@"Left View"];
    if(leftViewArray && [leftViewArray count]){
        //Indent into the margin to save space
        cellFrame.origin.x -= LEFT_MARGIN;
        cellFrame.size.width += LEFT_MARGIN;

        //Left aligned icon
        for(loop = 0;loop < [leftViewArray count];loop++){
            id <AIListObjectLeftView>	handler = [leftViewArray objectAtIndex:loop];
            NSRect				drawRect;
            float				width;

            //Calculate the icon size
            width = [handler widthForHeight:cellFrame.size.height];

            //Create a destination rect for the icon
            drawRect = cellFrame;
            drawRect.size.width = width;

            //Draw the icon
            [handler drawInRect:drawRect];

            //Subtract the drawn area from the remaining rect
            cellFrame.origin.x += (width + LEFT_VIEW_PADDING);
            cellFrame.size.width -= (width + LEFT_VIEW_PADDING);
        }
    }
    
    //Display all right views
    rightViewArray = [listObject displayArrayForKey:@"Right View"];
    if(rightViewArray && [rightViewArray count]){//Right aligned icon(s)
        for(loop = 0;loop < [rightViewArray count];loop++){
            id <AIListObjectLeftView>	handler = [rightViewArray objectAtIndex:loop];
            NSRect				drawRect;
            float				width;

            //Calculate the icon size
            width = [handler widthForHeight:cellFrame.size.height];

            //Create a destination rect for the icon
            drawRect = cellFrame;
            drawRect.origin.x = cellFrame.origin.x + cellFrame.size.width - width;
            drawRect.size.width = width;

            //Draw the icon
            [handler drawInRect:drawRect];

            //Subtract the drawn area from the remaining rect
            cellFrame.size.width -= (width + RIGHT_VIEW_PADDING);
        }
    }

    //Text Color (If this cell is selected, use the inverted color, or white)
    if(![self isHighlighted] || ![[controlView window] isKeyWindow] || [[controlView window] firstResponder] != controlView || backgroundColor){
        textColor = [[listObject displayArrayForKey:@"Text Color"] averageColor];
        if(!textColor){
            if(isGroup) textColor = [(AISCLOutlineView *)controlView groupColor];
            else textColor = [(AISCLOutlineView *)controlView color];
        }

    }else{ //use the regular color, or black
        textColor = [[listObject displayArrayForKey:@"Inverted Text Color"] averageColor];
        if(!textColor){
            if(isGroup) textColor = [(AISCLOutlineView *)controlView invertedGroupColor];
            else textColor = [(AISCLOutlineView *)controlView invertedColor];
        }

    }

    //Text Font
    if(!isGroup){
        font = [(AISCLOutlineView *)controlView font];
    }else{
        font = [(AISCLOutlineView *)controlView groupFont];
    }

    //Create a paragraph Style (To turn off clipping by word)
    paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setLineBreakMode:NSLineBreakByClipping];

    //Get the name string
    
    //string
    leftTextArray = [listObject displayArrayForKey:@"Left Text"];
    rightTextArray = [listObject displayArrayForKey:@"Right Text"];
    displayString = [NSMutableString stringWithString:@""];
    leftText = [leftTextArray count] > 0 ? [leftTextArray objectAtIndex:0] : nil;
    rightText = [rightTextArray count] > 0 ? [rightTextArray objectAtIndex:0] : nil;
    
    if(leftText)
    {
    	[displayString appendString:leftText];
    }
    
    [displayString appendString:[listObject longDisplayName]];
    
    if(rightText)
    {
    	[displayString appendString:rightText];
    }
    
    displayName = [[NSAttributedString alloc] initWithString:(NSString *)displayString attributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor, NSForegroundColorAttributeName, font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil]];

    //Draw the name
    [displayName drawInRect:NSOffsetRect(cellFrame, 0, -1)];//Adjust the strings up 1 pixel
    [displayName release];
}

@end
