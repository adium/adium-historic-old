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

#import "AISCLCell.h"
#import "AISCLOutlineView.h"
#import "AISCLViewPlugin.h"

#define LEFT_MARGIN		12
#define EXTRA_LEFT_VIEW_SPACING 4
#define RIGHT_MARGIN		8
#define GROUP_PADDING		3
#define LEFT_VIEW_PADDING	3
#define RIGHT_VIEW_PADDING	3
#define INDENTATION_OFFSET	-7
#define CELL_SIZE_ADJUST_X	20	//Adjustment for the flippy triangles, and add some padding
#define BACK_CELL_INDENT	2

@interface AISCLCell (PRIVATE)
- (NSSize)leftViewSizeForHeight:(float)height;
- (NSSize)rightViewSizeForHeight:(float)height;
//- (void)highlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView usingColor:(NSColor *)inColor;
- (void)highlightUsingColor:(NSColor *)inColor;
@end

@implementation AISCLCell

- (id)init
{
    [super init];
    
    return self;
}

- (void)setContact:(AIListObject *)inObject
{
//    textSize = NSMakeSize(0,0);
    listObject = inObject;
    isGroup = [listObject isKindOfClass:[AIListGroup class]];
}

- (NSSize)leftViewSizeForHeight:(float)height
{
    AIMutableOwnerArray     *leftViewArray;
    NSSize                  cellSize = NSMakeSize(0,height);
    int loop;
    //Calculate all 'Left Views'
    leftViewArray = [listObject displayArrayForKey:@"Left View"];
    if(leftViewArray && [leftViewArray count]){
        //Indent into the margin to save space
        cellSize.width -= LEFT_MARGIN;
        
        //Left aligned icon
        for(loop = 0;loop < [leftViewArray count];loop++){
            id <AIListObjectLeftView>	handler = [leftViewArray objectAtIndex:loop];
            
            //Calculate the icon size
            cellSize.width += [handler widthForHeight:height];
        }
    }    
    return cellSize;
}
- (NSSize)rightViewSizeForHeight:(float)height
{
    AIMutableOwnerArray     *rightViewArray;
    NSSize                  cellSize = NSMakeSize(0,height);
    int loop;
    
    //Calculate all right views
    rightViewArray = [listObject displayArrayForKey:@"Right View"];
    if(rightViewArray && [rightViewArray count]){//Right aligned icon(s)
        //Move the first rightView item RIGHT_VIEW_PADDING away from the center
        cellSize.width += RIGHT_VIEW_PADDING;
        
        for(loop = 0;loop < [rightViewArray count];loop++){
            id <AIListObjectLeftView>	handler = [rightViewArray objectAtIndex:loop];
            
            //Calculate the icon size
            cellSize.width += [handler widthForHeight:height];
        }
    }    
    
    return cellSize;
}

- (NSArray *)cellSizeArrayForBounds:(NSRect)aRect inView:(NSView *)controlView
{
    NSFont		*font;
    NSAttributedString	*displayName;
    NSSize		displayNameSize;
    NSSize		cellSize = NSMakeSize(CELL_SIZE_ADJUST_X, 0);
    NSMutableArray      *cellSizeArray = [NSMutableArray array];

    //Text Font
    font = [(AISCLOutlineView *)controlView font];

    //Add Bold for Groups
    if(isGroup){
        font = [(AISCLOutlineView *)controlView groupFont];
    }
    
    if(isGroup){ //move text away from flippy triangle
        cellSize.width += INDENTATION_OFFSET + 4;
    }else{ //Negate indentation
        cellSize.width += INDENTATION_OFFSET;
        
        //Pad the right side of our view
        cellSize.width += RIGHT_MARGIN;
    }
    
    //string
    NSMutableString 	*displayString = [NSMutableString stringWithString:@""];
    AIMutableOwnerArray *leftTextArray = [listObject displayArrayForKey:@"Left Text"];
    AIMutableOwnerArray *rightTextArray = [listObject displayArrayForKey:@"Right Text"];
    NSString *leftText = [leftTextArray count] > 0 ? [leftTextArray objectAtIndex:0] : nil;
    NSString *rightText = [rightTextArray count] > 0 ? [rightTextArray objectAtIndex:0] : nil;
    
    if(leftText) {
    	[displayString appendString:leftText];
    }
    
    [displayString appendString:[listObject longDisplayName]];
    
    if(rightText) {
    	[displayString appendString:rightText];
    }
    
    //Name
    displayName = [[NSAttributedString alloc] initWithString:(NSString *)displayString
                                                  attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]];
    displayNameSize = [displayName size];
    cellSize.width += displayNameSize.width;
    cellSize.height += displayNameSize.height;
    [displayName release];
    
    int height = cellSize.height;
    
    [cellSizeArray addObject:NSStringFromSize([self leftViewSizeForHeight:height])];
    [cellSizeArray addObject:NSStringFromSize(cellSize)];
    [cellSizeArray addObject:NSStringFromSize([self rightViewSizeForHeight:height])];
    
    return(cellSizeArray);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSFont		    *font;
    NSAttributedString      *displayName;
    NSMutableString	    *displayString;
    NSString		    *rightText, *leftText;
    NSColor		    *textColor, *backgroundColor = nil;
    AIMutableOwnerArray     *leftViewArray, *rightViewArray, *leftTextArray, *rightTextArray;
    NSParagraphStyle	    *paragraphStyle;
    int			    loop;
    
    NSBezierPath            *pillPath = nil;
    NSAffineTransform       *leftViewCompensation = nil;
    
    BOOL showLabels = [(AISCLOutlineView *)controlView showLabels];
    BOOL labelAroundContactOnly = [(AISCLOutlineView *)controlView labelAroundContactOnly];
    
    if(isGroup){ //move text away from flippy triangle
        cellFrame.origin.x += GROUP_PADDING;
        cellFrame.size.width -= GROUP_PADDING;
    }else{ //Negate indentation
        cellFrame.origin.x += INDENTATION_OFFSET;
        cellFrame.size.width -= INDENTATION_OFFSET;
    }
    
    //Pad the right side of our view
    cellFrame.size.width -= RIGHT_MARGIN;
    
    
    if (showLabels) {
        //Background Color (If this cell is selected, we don't display the background color)
        if ([self isHighlighted] && ([[controlView window] isKeyWindow] && [[controlView window] firstResponder] == controlView)){
            if ([(AISCLOutlineView *)controlView labelAroundContactOnly]) {
                backgroundColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:[(AISCLOutlineView *)controlView labelOpacity]];
            } else {
                backgroundColor = nil;
            }
        } else {
            backgroundColor = [[[listObject displayArrayForKey:@"Label Color"] averageColor] colorWithAlphaComponent:[(AISCLOutlineView *)controlView labelOpacity]];
        }
    }
    
    
    //Create a paragraph Style (To turn off clipping by word)
    paragraphStyle = [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment lineBreakMode:NSLineBreakByClipping];
    
    //Text Font
    if(!isGroup){
        font = [(AISCLOutlineView *)controlView font];
    }else{
        font = [(AISCLOutlineView *)controlView groupFont];
    }
    
    //Text Color (If this cell is selected, use the inverted color, or white)
    if(![self isHighlighted] || ![[controlView window] isKeyWindow] || [[controlView window] firstResponder] != controlView){
        textColor = [[listObject displayArrayForKey:@"Text Color"] averageColor];
        if(!textColor){
            if(isGroup) textColor = [(AISCLOutlineView *)controlView groupColor];
            else textColor = [(AISCLOutlineView *)controlView color];
        }
    }else{ //use the regular color, or black
        textColor = [NSColor alternateSelectedControlTextColor];
/*        textColor = [[listObject displayArrayForKey:@"Inverted Text Color"] averageColor];
        if(!textColor){
            if(isGroup) textColor = [(AISCLOutlineView *)controlView invertedGroupColor];
            else textColor = [(AISCLOutlineView *)controlView invertedColor];
        }
*/
    }    
    
    //Get the name string and build our displayString with all its attributes
    leftTextArray = [listObject displayArrayForKey:@"Left Text"];
    rightTextArray = [listObject displayArrayForKey:@"Right Text"];
    displayString = [NSMutableString stringWithString:@""];
    leftText = [leftTextArray count] > 0 ? [leftTextArray objectAtIndex:0] : nil;
    rightText = [rightTextArray count] > 0 ? [rightTextArray objectAtIndex:0] : nil;
    
    if(leftText){
        [displayString appendString:leftText];
    }
    
    [displayString appendString:[listObject longDisplayName]];
    
    if(rightText){
        [displayString appendString:rightText];
    }

    NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:textColor, NSForegroundColorAttributeName, font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    
    displayName = [[NSAttributedString alloc] initWithString:(NSString *)displayString attributes:attributesDict];
    
    //Background
    if(backgroundColor){
        
        int 		innerLeft, innerRight, innerTop, innerBottom;
        float 		centerY, circleRadius;
        NSSize          backgroundSize;
        
        if (labelAroundContactOnly) {
            backgroundSize = [displayName size];
        } else {
            backgroundSize = cellFrame.size;   
        }
        
        //Calculate some points
        innerLeft = cellFrame.origin.x + BACK_CELL_INDENT;
        innerRight = cellFrame.origin.x + backgroundSize.width - BACK_CELL_INDENT;
        innerTop = cellFrame.origin.y;
        innerBottom = cellFrame.origin.y + backgroundSize.height;
        circleRadius = -(innerTop - innerBottom) / 2.0;
        
        if (isGroup)
            innerLeft -= (LEFT_MARGIN - 3);
        
        centerY = (innerTop + innerBottom) / 2.0;
        
        //Create the circle path
        pillPath = [NSBezierPath bezierPath];
        [pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
        [pillPath lineToPoint: NSMakePoint(innerRight, innerTop)];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerRight, centerY) radius:circleRadius startAngle:270 endAngle:90 clockwise:NO];
        [pillPath lineToPoint: NSMakePoint(innerLeft, innerBottom)];
        [pillPath appendBezierPathWithArcWithCenter: NSMakePoint(innerLeft, centerY)radius:circleRadius     startAngle:90 endAngle:270 clockwise:NO];

        //Fill the label background now if it would overwrite left views if done later
        if (!labelAroundContactOnly) {
            [backgroundColor set];
            [pillPath fill];
            
            //Stroke the outline if needed
            if ([(AISCLOutlineView *)controlView outlineLabels]) {
                [pillPath setLineWidth:1.0];
                [textColor set];
                [pillPath stroke];
            }
        }
    }
    
    
    //Display all Left Views
    leftViewArray = [listObject displayArrayForKey:@"Left View"];
    
    if(leftViewArray && [leftViewArray count]){
        float indentation = LEFT_MARGIN;
        
        //move the left views a bit further away to give the label room
        if (labelAroundContactOnly)
            indentation += EXTRA_LEFT_VIEW_SPACING;
        //Indent into the margin to save space
        cellFrame.origin.x -= indentation;
        cellFrame.size.width += indentation;

        if (labelAroundContactOnly) {
            leftViewCompensation = [NSAffineTransform transform];
            [leftViewCompensation translateXBy:(-LEFT_MARGIN) yBy:0.0];
        }
        
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
            
            //Modify the pillpath if necessary
            if (labelAroundContactOnly) {
                [leftViewCompensation translateXBy:(width + LEFT_VIEW_PADDING) yBy:0.0];
            }
        }
        
        //if drawing only around the label, bring the rest of the drawing back into line (having moved the left views a bit further away)
        if (labelAroundContactOnly) {
            cellFrame.origin.x += EXTRA_LEFT_VIEW_SPACING;
            cellFrame.size.width -= EXTRA_LEFT_VIEW_SPACING;
        }
        
    }

    
    //Now draw the label if it only goes around the contact (having compensated for left views as necessary)
    if (backgroundColor && labelAroundContactOnly) {
        if (leftViewCompensation)
            [pillPath transformUsingAffineTransform:leftViewCompensation];
        
        [backgroundColor set];
        [pillPath fill];
        
        //Stroke the outline if needed
        if ([(AISCLOutlineView *)controlView outlineLabels]) {
            [pillPath setLineWidth:1.0];
            [textColor set];
            [pillPath stroke];
        }
         
    }
    
    
    //Display all Right Views
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
   
    //Outline the group name as per preferences if not highlighted by the system or we are doing custom highlighting
    
    if (isGroup && (![self isHighlighted] || labelAroundContactOnly) && [(AISCLOutlineView *)controlView outlineGroupColor]) {
        NSColor *outlineGroupColor = [(AISCLOutlineView *)controlView outlineGroupColor];
        NSDictionary * attributesDict_two = [NSDictionary dictionaryWithObjectsAndKeys:
            outlineGroupColor, NSForegroundColorAttributeName, 
            font, NSFontAttributeName, 
            paragraphStyle, NSParagraphStyleAttributeName, 
            outlineGroupColor, NSStrokeColorAttributeName, 
            [NSNumber numberWithFloat:15.0], NSStrokeWidthAttributeName, nil];
  
        [(NSAttributedString *)[[[NSAttributedString alloc] initWithString:(NSString *)displayString attributes:attributesDict_two] autorelease] drawInRect:NSOffsetRect(cellFrame, 0, [(AISCLOutlineView *)controlView labelAroundContactOnly] ? 0 : -1)];//Adjust the strings up 1 pixel
    }
    
    //Draw the name
    [displayName drawInRect:NSOffsetRect(cellFrame, 0, labelAroundContactOnly ? 0 : -1)];//Adjust the strings up 1 pixel
    [displayName release];
}

//Private NSCell method which needs to be overridden to do custom highlighting properly, regardless of the false claims of the documentation.
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (![(AISCLOutlineView *)controlView labelAroundContactOnly]) {
        [(id)super _drawHighlightWithFrame:cellFrame inView:controlView];   
    }
}

@end
