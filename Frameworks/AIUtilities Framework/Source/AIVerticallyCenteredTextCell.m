/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*
 *A text cell with vertically centered text
 */

#import "AIVerticallyCenteredTextCell.h"
#import "AIAttributedStringAdditions.h"

@implementation AIVerticallyCenteredTextCell

- (id)init
{
	if(self = [super init]){
		lineBreakMode = /*NSLineBreakByTruncatingTail*/ NSLineBreakByWordWrapping;
	}

	return self;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSFont		*font  = [self font];
	NSString	*title = [self stringValue];
	
	BOOL 		 highlighted;
	NSColor 	*highlightColor;
	
	highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
	highlighted = [self isHighlighted];
	
	//Draw the cell's text
	if(title != nil){
		NSDictionary	*attributes;
		float			 stringHeight;
		NSColor			*textColor;

		// If we are highlighted AND are drawing with the alternate color, then we want to draw our text with the alternate text color.
		// For any other case, we should draw using our normal text color.
		if(highlighted && [highlightColor isEqual:[NSColor alternateSelectedControlColor]]){
			textColor = [NSColor alternateSelectedControlTextColor]; //Draw the text inverted
		}else{
			if([self isEnabled]){
				textColor = [NSColor controlTextColor]; //Draw the text regular
			}else{
				textColor = [NSColor grayColor]; //Draw the text disabled
			}
		}

		//Paragraph style for alignment and clipping
		NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[style setAlignment:[self alignment]];
		[style setLineBreakMode:lineBreakMode];

		//
		if(font){
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				font, NSFontAttributeName,
				style, NSParagraphStyleAttributeName,
				textColor, NSForegroundColorAttributeName,nil];
		}else{
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				style, NSParagraphStyleAttributeName,
				textColor, NSForegroundColorAttributeName,nil];
		}

		NSAttributedString	*attributedTitle = [[NSAttributedString alloc] initWithString:title
																			   attributes:attributes];
		//Calculate the centered rect
		stringHeight = [attributedTitle heightWithWidth:cellFrame.size.width];
		if(stringHeight < cellFrame.size.height){
			cellFrame.origin.y += (cellFrame.size.height - stringHeight) / 2.0;
		}

		//Draw the string
		[attributedTitle drawInRect:cellFrame];
	}
}

@end
