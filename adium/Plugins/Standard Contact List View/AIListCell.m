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

@interface AIListCell (PRIVATE)
@end

@implementation AIListCell

//Init
- (id)init
{
    [super init];
	
	topSpacing = 0;
	bottomSpacing = 0;
	topPadding = 0;
	bottomPadding = 0;
	leftPadding = 0;
	rightPadding = 0;
	leftSpacing = 0;
	rightSpacing = 0;
	
	font = [[NSFont systemFontOfSize:12] retain];
	
	//Set up our custom text system.
	//Using drawAtPoint: places our text at a seemingly random vertical alignment, so we do the text drawing at a
	//slightly lower level to avoid this.
//	textStorage = [[NSTextStorage alloc] init];
//	layoutManager = [[NSLayoutManager alloc] init];
//	textContainer = [[NSTextContainer alloc] init];
//	[layoutManager addTextContainer:textContainer];
//	[textStorage addLayoutManager:layoutManager];
//	[textContainer setLineFragmentPadding:0.0];
	
    return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	[newCell setListObject:listObject];
	return(newCell);
}

//Dealloc
- (void)dealloc
{
//	[textContainer release];
//	[layoutManager release];
//	[textStorage release];
	[genericUserIcon release];
	[font release];
	
	
	[super dealloc];
}

//Set the list object being drawn
- (void)setListObject:(AIListObject *)inObject
{
    listObject = inObject;
    isGroup = [listObject isKindOfClass:[AIListGroup class]];
}

//Set our control view (Better than passing this around like crazy)
- (void)setControlView:(NSView *)inControlView
{
	controlView = inControlView;
}

//Text alignment
- (void)setTextAlignment:(NSTextAlignment)inAlignment
{
	textAlignment = inAlignment; 
}
- (NSTextAlignment)textAlignment{
	return(textAlignment);
}

//
- (void)setFont:(NSFont *)inFont
{
	if(inFont && inFont != font){
		[font release];
		font = [inFont retain];
	}
}
- (NSFont *)font{
	return(font);
}

//Does this cell need the grid draw behind it?
- (BOOL)drawGridBehindCell
{
	return(YES);
}


//Sizing and Display ---------------------------------------------------------------------------------------------------
//
- (NSSize)cellSize
{
	return(NSMakeSize(0, [self topSpacing] + [self topPadding] + [self bottomPadding] + [self bottomSpacing]));
}

//User-defined spacing offsets.  A cell may adjust these values to to obtain a more desirable default. 
//These are offsets, they may be negative!  Spacing is the distance between cells (Spacing gaps are not filled).
- (void)setSplitVerticalSpacing:(int)inSpacing{
	topSpacing = inSpacing / 2;
	bottomSpacing = (inSpacing + 1) / 2;
}
- (void)setTopSpacing:(int)inSpacing{
	topSpacing = inSpacing;
}
- (int)topSpacing{
	return(topSpacing);
}
- (void)setBottomSpacing:(int)inSpacing{
	bottomSpacing = inSpacing;
}
- (int)bottomSpacing{
	return(bottomSpacing);
}
- (void)setLeftSpacing:(int)inSpacing{
	leftSpacing = inSpacing;
}
- (int)leftSpacing{
	return(leftSpacing);
}
- (void)setRightSpacing:(int)inSpacing{
	rightSpacing = inSpacing;
}
- (int)rightSpacing{
	return(rightSpacing);
}

//User-defined padding offsets.  A cell may adjust these values to to obtain a more desirable default.
//These are offsets, they may be negative!  Padding is the distance between cell edges and their content.
- (void)setSplitVerticalPadding:(int)inPadding{
	topPadding = inPadding / 2;
	bottomPadding = (inPadding + 1) / 2;
}
- (void)setTopPadding:(int)inPadding{
	topPadding = inPadding;
}
- (void)setBottomPadding:(int)inPadding{
	bottomPadding = inPadding;
}
- (int)topPadding{
	return(topPadding);
}
- (int)bottomPadding{
	return(bottomPadding);
}

- (void)setLeftPadding:(int)inPadding{
	leftPadding = inPadding;
}
- (int)leftPadding{
	return(leftPadding);
}
- (void)setRightPadding:(int)inPadding{
	rightPadding = inPadding;
}
- (int)rightPadding{
	return(rightPadding);
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{	
	if(listObject){
		//Cell spacing
		cellFrame.origin.y += [self topSpacing];
		cellFrame.size.height -= [self bottomSpacing] + [self topSpacing];
		cellFrame.origin.x += [self leftSpacing];
		cellFrame.size.width -= [self rightSpacing] + [self leftSpacing];
		
		[self drawBackgroundWithFrame:cellFrame];

		//Padding
		cellFrame.origin.y += [self topPadding];
		cellFrame.size.height -= [self bottomPadding] + [self topPadding];
		cellFrame.origin.x += [self leftPadding];
		cellFrame.size.width -= [self rightPadding] + [self leftPadding];

		[self drawContentWithFrame:cellFrame];
	}
}

- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
//	[super _drawHighlightWithFrame:cellFrame inView:controlView];
	
	//Cell spacing
	cellFrame.origin.y += [self topSpacing];
	cellFrame.size.height -= [self bottomSpacing] + [self topSpacing];
	cellFrame.origin.x += [self leftSpacing];
	cellFrame.size.width -= [self rightSpacing] + [self leftSpacing];
	
	[self drawSelectionWithFrame:cellFrame];
}

//Draw Selection
- (void)drawSelectionWithFrame:(NSRect)rect
{
	
}
	
//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	//
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	[self drawDisplayNameWithFrame:rect];
}

//Draw our display name
- (NSRect)drawDisplayNameWithFrame:(NSRect)inRect
{	
	NSAttributedString	*displayName = [self displayNameStringWithAttributes:YES];
	NSSize				nameSize = [displayName size];
	NSRect				rect = inRect;
	
	if(nameSize.width > rect.size.width) nameSize = rect.size;

	//Alignment
	switch([self textAlignment]){
		case NSCenterTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width) / 2.0;
		break;
		case NSRightTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width);
		break;
		default:
		break;
	}

	//Draw (centered vertical)
	int half = (rect.size.height - nameSize.height) / 2.0;
	[displayName drawInRect:NSMakeRect(rect.origin.x,
									   rect.origin.y + half,
									   rect.size.width,
									   rect.size.height - half)];
	
	
	switch([self textAlignment]){
		case NSCenterTextAlignment:
			//How to handle this case?
		break;
		case NSRightTextAlignment:
			inRect.size.width -= nameSize.width;
		break;
		default:
			inRect.origin.x += nameSize.width;
			inRect.size.width -= nameSize.width;
		break;
	}
	
	return(inRect);
	
	
//	[[self displayNameStringWithAttributes:YES] drawInRect:rect];
//	[textStorage setAttributedString:[self displayNameStringWithAttributes:YES]];
//	NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
//	NSRect	glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
//
//	//Alignment
//	switch([self textAlignment]){
//		case NSCenterTextAlignment:
//			rect.origin.x += (rect.size.width - glyphRect.size.width) / 2.0;
//		break;
//		case NSRightTextAlignment:
//			rect.origin.x += (rect.size.width - glyphRect.size.width);
//		break;
//		default:
//		break;
//	}
//
//	[layoutManager drawGlyphsForGlyphRange:glyphRange
//								   atPoint:NSMakePoint(rect.origin.x,
//													   rect.origin.y + (rect.size.height - glyphRect.size.height) / 2.0)];
}

//Returns our display name string.  If the string is only for sizing, passing NO will skip applying non-size changing
//attributes, giving a bit of a speed boost
- (NSAttributedString *)displayNameStringWithAttributes:(BOOL)applyAttributes
{
	NSFont				*font = [self font];//(isGroup ? [NSFont boldSystemFontOfSize:12] : nil);//[controlView groupFont] : [controlView font]);
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
		NSDictionary		*additionalAttributes = [self displayNameAttributes];
		NSColor				*textColor = [self textColor];
		NSParagraphStyle	*paragraphStyle;
		
		//Attributes
		paragraphStyle = [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment lineBreakMode:NSLineBreakByTruncatingTail/*NSLineBreakByClipping*/];
		attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			textColor, NSForegroundColorAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			font, NSFontAttributeName,
			nil];
		if(additionalAttributes) [attributes addEntriesFromDictionary:additionalAttributes];
		
	}else{
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
	}
	
	return([[[NSAttributedString alloc] initWithString:displayString attributes:attributes] autorelease]);
}

//Additional attributes for the display name
- (NSDictionary *)displayNameAttributes
{
	return(nil);
}

//Text Color (If this cell is selected, use the inverted color)
- (NSColor *)textColor
{
	if([self isSelectionInverted]){
		return([NSColor alternateSelectedControlTextColor]);
	}else{
		return([NSColor blackColor]);
	}
}

//Should our selection be drawn inverted?
- (BOOL)isSelectionInverted
{
	return([self isHighlighted] && [[controlView window] isKeyWindow] && [[controlView window] firstResponder] == controlView);
}

@end
