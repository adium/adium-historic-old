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

	//Set up our custom text system.
	//Using drawAtPoint: places our text at a seemingly random vertical alignment, so we do the text drawing at a
	//slightly lower level to avoid this.
	textStorage = [[NSTextStorage alloc] init];
	layoutManager = [[NSLayoutManager alloc] init];
	textContainer = [[NSTextContainer alloc] init];
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[textContainer setLineFragmentPadding:0.0];
	
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

//Font
- (NSFont *)font
{
	return([controlView font]);
}


//Sizing and Display ---------------------------------------------------------------------------------------------------
//
- (NSSize)cellSize
{
	return(NSMakeSize(0, [self topSpacing] + [self topPadding] + [self bottomPadding] + [self bottomSpacing]));
}

//User-defined spacing offsets.  A cell may adjust these values to to obtain a more desirable default. 
//These are offsets, they may be negative!  Spacing is the distance between cells (Spacing gaps are not filled).
- (int)topSpacing{
	return(0);
}
- (int)bottomSpacing{
	return(0);
}

//User-defined padding offsets.  A cell may adjust these values to to obtain a more desirable default.
//These are offsets, they may be negative!  Padding is the distance between cell edges and their content.
- (int)topPadding{
	return(0);
}
- (int)bottomPadding{
	return(0);
}
- (int)leftPadding{
	return(0);
}
- (int)rightPadding{
	return(0);
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
		
		[self drawBackgroundWithFrame:cellFrame];

		//Padding
		cellFrame.origin.y += [self topPadding];
		cellFrame.size.height -= [self bottomPadding] + [self topPadding];
		cellFrame.origin.x += [self leftPadding];
		cellFrame.size.width -= [self rightPadding] + [self leftPadding];

		[self drawContentWithFrame:cellFrame];
	}
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
- (void)drawDisplayNameWithFrame:(NSRect)rect
{	
	[textStorage setAttributedString:[self displayNameStringWithAttributes:YES]];
	NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
	NSRect	glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];

	//Alignment
	switch([self textAlignment]){
		case NSCenterTextAlignment:
			rect.origin.x += (rect.size.width - glyphRect.size.width) / 2.0;
		break;
		case NSRightTextAlignment:
			rect.origin.x += (rect.size.width - glyphRect.size.width);
		break;
		default:
		break;
	}

	[layoutManager drawGlyphsForGlyphRange:glyphRange
								   atPoint:NSMakePoint(rect.origin.x,
													   rect.origin.y + (rect.size.height - glyphRect.size.height) / 2.0)];
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
		NSColor				*textColor;
		NSParagraphStyle	*paragraphStyle;
		
		//Text Color (If this cell is selected, use the inverted color, or white)
		textColor = [self textColor];
		
		//Font & Clipping paragraph style
		paragraphStyle = [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment lineBreakMode:NSLineBreakByClipping];
		
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			textColor, NSForegroundColorAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			font, NSFontAttributeName,
			nil];
		
	}else{
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
	}
	
	return([[[NSAttributedString alloc] initWithString:displayString attributes:attributes] autorelease]);
}

//Text Color (If this cell is selected, use the inverted color, or white)
- (NSColor *)textColor
{
	NSColor	*textColor = nil;
	
	if(![self isHighlighted] || ![[controlView window] isKeyWindow] || [[controlView window] firstResponder] != controlView){
		textColor = [[listObject displayArrayForKey:@"Text Color"] objectValue];
		if(!textColor) textColor = [NSColor blackColor];
	}else{
		textColor = [NSColor alternateSelectedControlTextColor];
	}    
	
	return(textColor);
}

@end
