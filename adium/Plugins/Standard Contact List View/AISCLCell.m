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

//Side views (Status icons, status circles, etc)
#define VIEW_PADDING				3		//Padding between the list object name and it's side views
#define VIEW_INNER_PADDING			3		//Padding between individual side views
#define LEFT_PADDING				-7		//Padding on the far left of our cell
#define LEFT_PADDING_GROUP			0		//Padding on the far left of our cell when displaying a group
#define RIGHT_PADDING				6		//Padding on the far right of our cell
#define NAME_OFFSET_X				-4		//Offset to apply to our name text (To counter any margins in text layout)
#define	LABEL_PADDING_REDUCTION		4.0 	//25% of the requested label endcap padding
#define GROUP_LABEL_OFFSET			-8		//Offset of the label when drawing behind a group name
#define STATUS_CIRCLE_MARGIN_HACK 	-12		//I hate status circles

//This are temporary to work around issues with the horizontal auto-resizing
#define TEMPORARY_PADDING_CORRECTION	16

@interface AISCLCell (PRIVATE)
- (NSSize)leftViewSizeForHeight:(float)height;
- (NSSize)rightViewSizeForHeight:(float)height;
- (void)highlightUsingColor:(NSColor *)inColor;
- (void)drawGradientWithFirstColor:(NSColor*)color1 secondColor:(NSColor*)color2 inRect:(NSRect)rect;
- (void)drawGradientWithFirstColor:(NSColor*)color1 secondColor:(NSColor*)color2 withOpacity:(float)inOpacity inBezierPath:(NSBezierPath*)inPath;
- (NSAttributedString *)displayNameStringWithAttributes:(BOOL)applyAttributes inView:(AISCLOutlineView *)controlView;
- (NSBezierPath *)bezierPathLabelOfSize:(NSSize)backgroundSize;
- (NSBezierPath *)bezierPathLabelWithRect:(NSRect)bounds;
- (float)displayViews:(NSArray *)viewArray inRect:(NSRect)drawRect onLeft:(BOOL)onLeft;
- (float)labelEdgePaddingRequiredForLabelOfSize:(NSSize)backgroundSize;
- (NSColor *)textColorInView:(AISCLOutlineView *)controlView;
@end

@implementation AISCLCell

//Init
- (id)init
{
    [super init];

	//Set up our custom text system.
	//Using drawAtPoint: places our text at a seemingly random vertical alignment, so we do the text drawing at a
	//slightly lower level to avoid this.
	textStorage = [[NSTextStorage alloc] init];
	layoutManager = [[NSLayoutManager alloc] init];
	textContainer = [[NSTextContainer alloc] init];
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	
    return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AISCLCell	*newCell = [[AISCLCell alloc] init];
	[newCell setListObject:listObject];
	return(newCell);
}

//Dealloc
- (void)dealloc
{
	[textContainer release];
	[layoutManager release];
	[textStorage release];
	
	[super dealloc];
}

//Set the list object being drawn
- (void)setListObject:(AIListObject *)inObject
{
    listObject = inObject;
    isGroup = [listObject isKindOfClass:[AIListGroup class]];
}

//Returns the necessary column widths (left side views, label, and right side views) to display this cell
- (NSArray *)cellSizeArrayForBounds:(NSRect)aRect inView:(AISCLOutlineView *)controlView
{
	float 				leftWidth, rightWidth;
    NSFont				*font;
    NSAttributedString	*displayName;
    NSSize				displayNameSize;
    NSSize				cellSize = NSMakeSize(0, 0);
    NSMutableArray      *cellSizeArray = [NSMutableArray array];

    //Text Font
	font = (isGroup ? [controlView groupFont] : [controlView font]);

	//Padding
	cellSize.width -= (LEFT_PADDING + RIGHT_PADDING);
#warning Adam: The Horizontal resizing code needs to consider level and indentationPerLevel (Temporary fix)
	cellSize.width += TEMPORARY_PADDING_CORRECTION;
	
	//Get the size needed to display our name
	displayNameSize = [[self displayNameStringWithAttributes:NO inView:controlView] size];
    cellSize.width += displayNameSize.width;
    cellSize.height += displayNameSize.height;

	//Get the size needed for both sets of side views
	leftWidth = [self displayViews:[[listObject displayArrayForKey:@"Left View"] allValues]
							inRect:NSMakeRect(0,0,0,cellSize.height)
							onLeft:YES] + STATUS_CIRCLE_MARGIN_HACK;
	rightWidth = [self displayViews:[[listObject displayArrayForKey:@"Right View"] allValues]
							 inRect:NSMakeRect(0,0,0,cellSize.height)
							 onLeft:NO];
	
	return([NSArray arrayWithObjects:
		[NSNumber numberWithFloat:leftWidth],
		[NSNumber numberWithFloat:cellSize.width],
		[NSNumber numberWithFloat:rightWidth],
		nil]);
}

//Returns our display name string.  If the string is only for sizing, passing NO will skip applying non-size changing
//attributes, giving a bit of a speed boost
- (NSAttributedString *)displayNameStringWithAttributes:(BOOL)applyAttributes inView:(AISCLOutlineView *)controlView
{
	NSFont				*font = (isGroup ? [controlView groupFont] : [controlView font]);
	NSString 			*displayString;
	NSDictionary		*attributes;
	
	//Apply left and right text attachments
	NSString *leftText = [[listObject displayArrayForKey:@"Left Text"] objectValue];
	NSString *rightText = [[listObject displayArrayForKey:@"Right Text"] objectValue];

	if(leftText || rightText){
		displayString = (NSString *)[NSMutableString string];

		//Combine left text, the object name, and right text
		if(leftText) [(NSMutableString *)displayString appendString:leftText];
		[(NSMutableString *)displayString appendString:[listObject longDisplayName]];
		if(rightText) [(NSMutableString *)displayString appendString:rightText];
		
	}else{
		displayString = [listObject longDisplayName];
	}
		
	//Add the display attributes
	if(applyAttributes){
		NSColor				*textColor;
		NSParagraphStyle	*paragraphStyle;
		
		//Text Color (If this cell is selected, use the inverted color, or white)
		textColor = [self textColorInView:controlView];
		
		//Font & Clipping paragraph style
		paragraphStyle = [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment lineBreakMode:NSLineBreakByClipping];
		
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			textColor, NSForegroundColorAttributeName,
			font, NSFontAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			nil];
		
	}else{
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
	}
	
	return([[[NSAttributedString alloc] initWithString:displayString attributes:attributes] autorelease]);
}

//Text Color (If this cell is selected, use the inverted color, or white)
- (NSColor *)textColorInView:(AISCLOutlineView *)controlView
{
	NSColor	*textColor;
	
	if(![self isHighlighted] || ![[controlView window] isKeyWindow] || [[controlView window] firstResponder] != controlView){
		textColor = [[listObject displayArrayForKey:@"Text Color"] objectValue];
		if(!textColor){
			if(isGroup) textColor = [(AISCLOutlineView *)controlView groupColor];
			else textColor = [(AISCLOutlineView *)controlView color];
		}
	}else{
		textColor = [NSColor alternateSelectedControlTextColor];
	}    
	
	return(textColor);
}

//Draw
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

//Draw our contents
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{	
	AISCLOutlineView	*outlineView = (AISCLOutlineView *)controlView;
	NSAttributedString  *displayName = [self displayNameStringWithAttributes:YES inView:outlineView];
	BOOL 				labelAroundContactOnly = [outlineView labelAroundContactOnly];
    NSBezierPath		*pillPath = nil;
	
	//Move our entire cell into the margin
    if(isGroup){
        cellFrame.origin.x += LEFT_PADDING_GROUP;
        cellFrame.size.width -= LEFT_PADDING_GROUP;
    }else{
        cellFrame.origin.x += LEFT_PADDING;
        cellFrame.size.width -= LEFT_PADDING;
    }
	cellFrame.size.width -= RIGHT_PADDING;
	
	//Draw all left Views before the background if drawing a label around the contact only
	if(labelAroundContactOnly && ([[listObject displayArrayForKey:@"Left View"] count]) ){
		int sideViewWidth = [self displayViews:[[listObject displayArrayForKey:@"Left View"] allValues]
										inRect:NSOffsetRect(cellFrame, STATUS_CIRCLE_MARGIN_HACK, 0.0f)
										onLeft:YES];
		cellFrame.origin.x += (sideViewWidth + STATUS_CIRCLE_MARGIN_HACK);
		cellFrame.size.width -= (sideViewWidth + STATUS_CIRCLE_MARGIN_HACK);
	}
	
	//List Object Label
    if([outlineView showLabels]){
		NSColor			*labelColor = nil;

		//Determine our label color
        if([self isHighlighted] && ([[outlineView window] isKeyWindow] && [[outlineView window] firstResponder] == outlineView)){
            if(labelAroundContactOnly) {
                labelColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:[outlineView labelOpacity]];
            }
        }else{
            if(isGroup){
                labelColor = [[outlineView labelGroupColor] colorWithAlphaComponent:[outlineView labelOpacity]];
            }else{
                labelColor = [[[listObject displayArrayForKey:@"Label Color"] objectValue] colorWithAlphaComponent:[outlineView labelOpacity]];
            }
        }
		
		//Draw our label
		if(labelColor){
			int 		innerLeft, innerRight, innerTop, innerBottom;
			NSRect		labelRect = cellFrame;
			
			//Restict our label to the object name if desired
			if(labelAroundContactOnly) {				
				labelRect.size.width = [displayName size].width/* + (cellFrame.size.height / 2.0f)*/;
			}
			
			//Indent our label into the available margins
			float	indent = [self labelEdgePaddingRequiredForLabelOfSize:labelRect.size];
			labelRect.origin.x -= indent;
			
			//EDS - This should technically be * 2.0f but that doesn't look right at present.
			labelRect.size.width += indent * 3.0f;
			
			//Adjust labels slightly when displaying for a group (to avoid overlapping the flippy triangle)
			if(isGroup){
				labelRect.origin.x += GROUP_LABEL_OFFSET;
				labelRect.size.width -= GROUP_LABEL_OFFSET;
			}
			labelRect.size.width -= GROUP_LABEL_OFFSET;
                        
			//Retrieve the label and shift it into position
			pillPath = [self bezierPathLabelWithRect:labelRect];
			
			//Fill the label
			if(![outlineView useGradient]){
				[labelColor set];
				[pillPath fill];
			}else{
				[[AIGradient gradientWithFirstColor:labelColor secondColor:[labelColor darkenAndAdjustSaturationBy:0.4f] direction:AIVertical] drawInBezierPath:pillPath];
			}
			
			//Outline the label
			if([outlineView outlineLabels]){
				[pillPath setLineWidth:1.0f];
				[[self textColorInView:outlineView] set];
				[pillPath stroke];
			}
		}
    }
    
    //Draw all left Views after the background if drawing a label around the entire width
	if(!labelAroundContactOnly && ([[listObject displayArrayForKey:@"Left View"] count]) ){
		int sideViewWidth = [self displayViews:[[listObject displayArrayForKey:@"Left View"] allValues]
										inRect:NSOffsetRect(cellFrame, STATUS_CIRCLE_MARGIN_HACK, 0)
										onLeft:YES];
		cellFrame.origin.x += (sideViewWidth + STATUS_CIRCLE_MARGIN_HACK);
		cellFrame.size.width -= (sideViewWidth + STATUS_CIRCLE_MARGIN_HACK);
	}

	//Outline the group name as per preferences if not highlighted by the system or we are doing custom highlighting
	if(isGroup && (![self isHighlighted] || labelAroundContactOnly) && [outlineView outlineGroupColor]){
		NSMutableAttributedString	*highlightString;
		highlightString = [[displayName mutableCopy] autorelease];
		[highlightString addAttribute:NSStrokeColorAttributeName
								value:[outlineView outlineGroupColor]
								range:NSMakeRange(0, [displayName length])];
		[highlightString addAttribute:NSStrokeWidthAttributeName
								value:[NSNumber numberWithFloat:15.0]
								range:NSMakeRange(0, [displayName length])];
		
		[textStorage setAttributedString:highlightString];
		NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
		[layoutManager drawGlyphsForGlyphRange:glyphRange
									   atPoint:NSMakePoint(cellFrame.origin.x + NAME_OFFSET_X, cellFrame.origin.y)];
	}
    
	//Draw the list object name
	[textStorage setAttributedString:displayName];
	NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
	[layoutManager drawGlyphsForGlyphRange:glyphRange
								   atPoint:NSMakePoint(cellFrame.origin.x + NAME_OFFSET_X, cellFrame.origin.y)];
	
    //Draw all Right Views
	[self displayViews:[[listObject displayArrayForKey:@"Right View"] allValues]
				inRect:cellFrame
				onLeft:NO];
}

//Calculates sizing and displays the views.  Pass a 0 width rect to skip drawing.
- (float)displayViews:(NSArray *)viewArray inRect:(NSRect)drawRect onLeft:(BOOL)onLeft
{
	float					width = 0;
	NSEnumerator			*enumerator;
	id <AIListObjectView>	sideView;
	
	if(viewArray && [viewArray count]){
		//Padding goes first for right aligned icons
		if(!onLeft) width += VIEW_PADDING;
		
		//Size and draw all the contained views
		enumerator = [viewArray objectEnumerator];
		while(sideView = [enumerator nextObject]){
			float		viewWidth = [sideView widthForHeight:drawRect.size.height];
            NSRect		viewRect;
			
			//If a zero width rect is passed, skip any drawing
			if(drawRect.size.width != 0){
				//Create a destination rect for the icon
				viewRect = drawRect;
				viewRect.size.width = viewWidth;
				if(!onLeft) viewRect.origin.x = drawRect.origin.x + drawRect.size.width - viewRect.size.width; //Right align
				
				//Draw the icon
				[sideView drawInRect:viewRect];
				
				//Subtract the drawn area from the remaining rect
				drawRect.size.width -= (viewRect.size.width + VIEW_INNER_PADDING);
				if(onLeft) drawRect.origin.x += (viewRect.size.width + VIEW_INNER_PADDING); //Move right
			}

			//Factor the width of this view into our total
			width += viewWidth + VIEW_INNER_PADDING;
		}		

		//Padding goes last for left aligned icons
		if(onLeft) width += VIEW_PADDING;
	}
	
	return(width);
}

//Returns the padding required for the caps of our label
- (float)labelEdgePaddingRequiredForLabelOfSize:(NSSize)backgroundSize
{
	return(backgroundSize.height / LABEL_PADDING_REDUCTION);  
}

//Returns a bezier path for our label
- (NSBezierPath *)bezierPathLabelOfSize:(NSSize)backgroundSize
{
	int 		innerLeft, innerRight, innerTop, innerBottom;
	float 		centerY, circleRadius;
	NSBezierPath	*pillPath;
    
	//Calculate some points
	circleRadius = backgroundSize.height / 2.0;
	innerTop = 0;
	innerBottom = backgroundSize.height;
	centerY = (innerTop + innerBottom) / 2.0;

	//Conpensate for our rounded caps
	innerLeft = circleRadius;
	innerRight = backgroundSize.width - circleRadius;

	//Create the subpath
	pillPath = [NSBezierPath bezierPath];
	[pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];

	[pillPath appendBezierPathWithArcWithCenter:NSMakePoint(innerRight, centerY)
										 radius:circleRadius
									 startAngle:270
									   endAngle:90
									  clockwise:NO];

	[pillPath appendBezierPathWithArcWithCenter:NSMakePoint(innerLeft, centerY)
										 radius:circleRadius
									 startAngle:90
									   endAngle:270
									  clockwise:NO];
	
	[pillPath closePath];

	return(pillPath);
}

- (NSBezierPath *)bezierPathLabelWithRect:(NSRect)bounds
{
	float 		innerLeft, innerRight, innerTop, innerBottom;
	float 		centerY, circleRadius;
	NSBezierPath	*pillPath;
    
	//Calculate some points
	circleRadius = bounds.size.height / 2.0f;
	innerTop    = bounds.origin.y;
	innerBottom = bounds.origin.y + bounds.size.height;
	centerY = (innerTop + innerBottom) / 2.0f;

	//Compensate for our rounded caps
	innerLeft  =  bounds.origin.x + circleRadius;
	innerRight = (bounds.origin.x + bounds.size.width) - (circleRadius * 2.0f);

	//Create the path and its subpath
	pillPath = [NSBezierPath bezierPath];

	[pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];

	//top edge, right end.
	[pillPath appendBezierPathWithArcWithCenter:NSMakePoint(innerRight, centerY)
										 radius:circleRadius
									 startAngle:270.0f
									   endAngle:90.0f
									  clockwise:NO];

	//bottom edge, left end.
	[pillPath appendBezierPathWithArcWithCenter:NSMakePoint(innerLeft, centerY)
										 radius:circleRadius
									 startAngle:90.0f
									   endAngle:270.0f
									  clockwise:NO];

	[pillPath closePath];

	return(pillPath);
}

//Private NSCell method which needs to be overridden to do custom highlighting properly, regardless of the false claims of the documentation.
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if(![(AISCLOutlineView *)controlView labelAroundContactOnly]) {
        [(id)super _drawHighlightWithFrame:cellFrame inView:controlView];   
    }
}

@end
