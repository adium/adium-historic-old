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

#import "AIListCell.h"
//#import "AISCLOutlineView.h"
//#import "AISCLViewPlugin.h"

//Side views (Status icons, status circles, etc)
#define VIEW_PADDING				3		//Padding between the list object name and it's side views
#define VIEW_INNER_PADDING			3		//Padding between individual side views
#define LEFT_PADDING				-8		//Padding on the far left of our cell
#define LEFT_PADDING_GROUP			0		//Padding on the far left of our cell when displaying a group
#define RIGHT_PADDING				9		//Padding on the far right of our cell
#define NAME_OFFSET_X				-4		//Offset to apply to our name text (To counter any margins in text layout)
#define	LABEL_PADDING_REDUCTION		4.0 	//25% of the requested label endcap padding
#define GROUP_LABEL_LEFT_OFFSET		-8		//Offset of the left side of the label when drawing behind a group name
#define GROUP_LABEL_RIGHT_OFFSET	0		//Offset of the right side of the label when drawing behind a group name
#define STATUS_CIRCLE_MARGIN_HACK 	-12		//I hate status circles

//This are temporary to work around issues with the horizontal auto-resizing
#define TEMPORARY_PADDING_CORRECTION	16

@interface AIListCell (PRIVATE)
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

#define USER_ICON_SIZE			28
#define CONTENT_CELL_HEIGHT		30
#define GROUP_CELL_HEIGHT		20

@implementation AIListCell

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
	AIListCell	*newCell = [[AIListCell alloc] init];
	[newCell setListObject:listObject];
	return(newCell);
}

//Dealloc
- (void)dealloc
{
	[textContainer release];
	[layoutManager release];
	[textStorage release];
	[genericUserIcon release];
	
	[super dealloc];
}

//Set the list object being drawn
- (void)setListObject:(AIListObject *)inObject
{
    listObject = inObject;
    isGroup = [listObject isKindOfClass:[AIListGroup class]];
}



//Sizing and Display ---------------------------------------------------------------------------------------------------
//Cell heights for the multi-cell outline view
- (int)cellHeightForGroup
{
	return(GROUP_CELL_HEIGHT);
}
- (int)cellHeightForContent
{
	return(CONTENT_CELL_HEIGHT);
}

//Draw frame
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

//Draw contents
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{	
	AISCLOutlineView	*outlineView = (AISCLOutlineView *)controlView;
	NSAttributedString  *displayName = [self displayNameStringWithAttributes:YES inView:outlineView];
    NSBezierPath		*pillPath = nil;
	
	
	if(isGroup) [self drawGroupBackgroundInRect:cellFrame];
	
	if(isGroup){
		//flippy triangle, bah
		cellFrame.origin.x += 12;
		cellFrame.size.width -= 12;
		
		cellFrame.origin.y -= 1;
		
	}else{
#define badgewidth 30
		
		cellFrame.origin.x += 14;
		cellFrame.size.width -= 14;

		//Status badge
		[self drawUserStatusBadgeInRect:NSMakeRect(cellFrame.origin.x + cellFrame.size.width - badgewidth,
												   cellFrame.origin.y,
												   badgewidth,
												   cellFrame.size.height)];
		cellFrame.size.width -= badgewidth;
		
		//Draw the user image
		[self drawUserIconInRect:NSMakeRect(cellFrame.origin.x,
											cellFrame.origin.y + (CONTENT_CELL_HEIGHT - USER_ICON_SIZE) / 2.0,
											USER_ICON_SIZE,
											USER_ICON_SIZE)];
		
		cellFrame.origin.x += USER_ICON_SIZE + 2;
		cellFrame.size.width -= USER_ICON_SIZE + 2;
	}
	
	cellFrame.origin.y += 3;
	
	
	NSAttributedString	*extStatus = [listObject statusObjectForKey:@"StatusMessage"];
	if(!isGroup /*extStatus*/){
		NSRect	statusRect = cellFrame;
		
		
		//Dest rect
		statusRect.origin.y += (statusRect.size.height / 2.0) - 2;
		statusRect.size.height /= 2.0;
		NSRange glyphRange	;
		//Format string
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor grayColor], NSForegroundColorAttributeName,
			[NSFont systemFontOfSize:9], NSFontAttributeName,nil];
		
		
		NSString *string;
		
		string = [extStatus string];
		if(!string) string = @"Online";
		
		
		string = [string stringByTruncatingTailToWidth:statusRect.size.width ];
		
		extStatus = [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
		
		
		
		
		
		
		[textStorage setAttributedString:extStatus];
		//		[textContainer setContainerSize:NSMakeSize(1e7, 16)];
		glyphRange = [layoutManager glyphRangeForBoundingRect:NSMakeRect(0,0,statusRect.size.width,10) inTextContainer:textContainer];
		[layoutManager drawGlyphsForGlyphRange:glyphRange
									   atPoint:NSMakePoint(statusRect.origin.x + NAME_OFFSET_X, statusRect.origin.y)];
		
		
		//cellFrame.origin.y -= statusRect.size.height;
		cellFrame.size.height /= 2.0;//(cellFrame.size.height / 2.0);
			
			[textStorage setAttributedString:displayName];
			glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
			[layoutManager drawGlyphsForGlyphRange:glyphRange
										   atPoint:NSMakePoint(cellFrame.origin.x + NAME_OFFSET_X,cellFrame.origin.y)];
			
	}else{
		//Draw the list object name
		if(!isGroup){
			cellFrame.origin.y -= 3;
			[textStorage setAttributedString:displayName];
			NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
			NSRect	glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
			[layoutManager drawGlyphsForGlyphRange:glyphRange
										   atPoint:NSMakePoint(cellFrame.origin.x + NAME_OFFSET_X,
															   cellFrame.origin.y + (CONTENT_CELL_HEIGHT - glyphRect.size.height) / 2.0)];
		}else{
			[textStorage setAttributedString:displayName];
			NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
			[layoutManager drawGlyphsForGlyphRange:glyphRange
										   atPoint:NSMakePoint(cellFrame.origin.x + NAME_OFFSET_X,cellFrame.origin.y)];
			
		}
		
	}
	
	//Draw all Right Views
	[self displayViews:[[listObject displayArrayForKey:@"Right View"] allValues]
				inRect:cellFrame
				onLeft:NO];
}


- (void)drawGroupBackgroundInRect:(NSRect)inRect
{
	AIGradient	*gradient = [AIGradient gradientWithFirstColor:[NSColor colorWithCalibratedRed:0.542 green:0.726 blue:1.0 alpha:1.0]
												   secondColor:[NSColor colorWithCalibratedRed:0.416 green:0.660 blue:1.0 alpha:1.0]
													 direction:AIVertical];
	[gradient drawInRect:inRect];
}








//User Icon ------------------------------------------------------------------------------------------------------------
//Draw the user icon
- (void)drawUserIconInRect:(NSRect)inRect
{
	NSImage	*image = [[listObject displayArrayForKey:KEY_USER_ICON] objectValue];
	if(!image) image = [self genericUserIcon];
	
	if(image){
		[image setFlipped:YES];
		[image drawInRect:inRect
				 fromRect:NSMakeRect(0,0,[image size].width,[image size].height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
		[image setFlipped:NO];
	}
}

//Returns a generic image for users without an icon
- (NSImage *)genericUserIcon
{
	if(!genericUserIcon){
		genericUserIcon = [[NSImage imageNamed:@"Placeholder" forClass:[self class]] retain];
	}
	
	return(genericUserIcon);
}


//User Name ------------------------------------------------------------------------------------------------------------
//
- (void)drawUserNameInRect:(NSRect)inRect
{
	
}


//User Extended Status -------------------------------------------------------------------------------------------------
//
- (void)drawUserExtendedStatusInRect:(NSRect)inRect
{
	
}


//User Status Badge ----------------------------------------------------------------------------------------------------
//
- (void)drawUserStatusBadgeInRect:(NSRect)inRect
{
	NSString	*statusName;
	NSImage 	*statusImage;
	
	//Get the status image
#warning Make this the responsibility of a plugin, just take an image from some display array from within here
//	if(![listObject integerStatusObjectForKey:@"Online"]){
//		statusName = @"status-offline";
//	}else if([listObject doubleStatusObjectForKey:@"Idle"]){
//		statusName = @"status-idle";
//	}else if([listObject doubleStatusObjectForKey:@"Away"]){
//		statusName = @"status-away";
//	}else{
//		statusName = @"status-available";
//	}
//	statusImage = [NSImage imageNamed:statusName forClass:[self class]];
	statusImage = [[listObject displayArrayForKey:@"Tab Status Icon"] objectValue];
	[statusImage setFlipped:YES];

	//Draw the image centered in the badge rect
	NSSize	imageSize = [statusImage size];
	NSRect	centeredRect = NSMakeRect(inRect.origin.x + (inRect.size.width - imageSize.width) / 2.0,
									  inRect.origin.y + (inRect.size.height - imageSize.height) / 2.0,
									  imageSize.width,
									  imageSize.height);
	[statusImage drawInRect:centeredRect
				   fromRect:NSMakeRect(0,0,imageSize.width,imageSize.height)
				  operation:NSCompositeSourceOver
				   fraction:1.0];
}




















//Returns our display name string.  If the string is only for sizing, passing NO will skip applying non-size changing
//attributes, giving a bit of a speed boost
- (NSAttributedString *)displayNameStringWithAttributes:(BOOL)applyAttributes inView:(AISCLOutlineView *)controlView
{
	NSFont				*font = (isGroup ? [NSFont boldSystemFontOfSize:12] : nil);//[controlView groupFont] : [controlView font]);
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
	NSColor	*textColor = nil;
	
	if(![self isHighlighted] || ![[controlView window] isKeyWindow] || [[controlView window] firstResponder] != controlView){
		textColor = [[listObject displayArrayForKey:@"Text Color"] objectValue];
		if(!textColor){
			textColor = [NSColor blackColor];
			
			if(isGroup) textColor = [NSColor whiteColor];
			
			
//			else textColor = [NSColor whiteColor];

			//if(isGroup) textColor = [(AISCLOutlineView *)controlView groupColor];
			//else textColor = [(AISCLOutlineView *)controlView color];
		}
	}else{
		textColor = [NSColor alternateSelectedControlTextColor];
	}    
	
	return(textColor);
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
//- (float)labelEdgePaddingRequiredForLabelOfSize:(NSSize)backgroundSize
//{
//	return(backgroundSize.height / LABEL_PADDING_REDUCTION);  
//}
//
////Returns a bezier path for our label
//- (NSBezierPath *)bezierPathLabelWithRect:(NSRect)bounds
//{
//	int 			innerLeft, innerRight, innerTop, innerBottom;
//	float 			centerY, circleRadius;
//	NSBezierPath	*pillPath;
//    
//	//Calculate some points
//	circleRadius = bounds.size.height / 2.0;
//	innerTop = bounds.origin.y;
//	innerBottom = bounds.origin.y + bounds.size.height;
//	centerY = (innerTop + innerBottom) / 2.0;
//
//	//Conpensate for our rounded caps
//	innerLeft = bounds.origin.x + circleRadius;
//	innerRight = (bounds.origin.x + bounds.size.width) - circleRadius;
//
//	//Create the subpath
//	pillPath = [NSBezierPath bezierPath];
//	[pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
//
//	[pillPath appendBezierPathWithArcWithCenter:NSMakePoint(innerRight, centerY)
//										 radius:circleRadius
//									 startAngle:270
//									   endAngle:90
//									  clockwise:NO];
//
//	[pillPath appendBezierPathWithArcWithCenter:NSMakePoint(innerLeft, centerY)
//										 radius:circleRadius
//									 startAngle:90
//									   endAngle:270
//									  clockwise:NO];
//	
//	[pillPath closePath];
//
//	return(pillPath);
//}
//
//Private NSCell method which needs to be overridden to do custom highlighting properly, regardless of the false claims of the documentation.
//- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
//{
////    if(![(AISCLOutlineView *)controlView labelAroundContactOnly]) {
////        [(id)super _drawHighlightWithFrame:cellFrame inView:controlView];   
////    }
//}

@end
