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
    A cell that displays an image and text
*/

#import "AIImageTextCell.h"
#import "AIParagraphStyleAdditions.h"

#define DEFAULT_MAX_IMAGE_WIDTH 24
#define IMAGE_TEXT_PADDING		2

@interface NSCell (UndocumentedHighlightDrawing)
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end

@implementation AIImageTextCell

//Init
- (id)init
{
	if((self = [super init])) {
		font = nil;
		subString = nil;
		maxImageWidth = DEFAULT_MAX_IMAGE_WIDTH;
	}

	return self;
}

//Dealloc
- (void)dealloc
{
	[font release];
	[subString release];

	[super dealloc];
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIImageTextCell *newCell = [super copyWithZone:zone];

	newCell->font = nil;
	[newCell setFont:font];
	
	newCell->subString = nil;
	[newCell setSubString:subString];
	
	[newCell setMaxImageWidth:maxImageWidth];
	return(newCell);
}

//Font used to display our text
- (void)setFont:(NSFont *)obj
{
	if(font != obj){
		[font release];
		font = [obj retain];
	}
}
- (NSFont *)font{
	return(font);
}

//Substring (Displayed in gray below our main string)
- (void)setSubString:(NSString *)inSubString
{
	if(subString != inSubString){
		[subString release];
		subString = [inSubString retain];
	}
}

- (void)setMaxImageWidth:(float)inWidth
{
	maxImageWidth = inWidth;
}

- (NSSize)cellSizeForBounds:(NSRect)cellFrame
{
	NSString	*title = [self objectValue];
	NSImage		*image = [self image];
	NSSize		cellSize = NSZeroSize;
	
	if(image){
		NSSize	destSize = [image size];

		//Center image vertically, or scale as needed
		if (destSize.height > cellFrame.size.height){
			float proportionChange = cellFrame.size.height / destSize.height;
			destSize.height = cellFrame.size.height;
			destSize.width = destSize.width * proportionChange;
		}
		
		if (destSize.width > maxImageWidth){
			float proportionChange = maxImageWidth / destSize.width;
			destSize.width = maxImageWidth;
			destSize.height = destSize.height * proportionChange;
		}

		cellSize.width += destSize.width + 5;
		cellSize.height = destSize.height;
	}
	
	if(title != nil){
		NSDictionary	*attributes;
		NSSize			titleSize;

		cellSize.width += IMAGE_TEXT_PADDING*2;
		
		//Truncating paragraph style
		NSParagraphStyle	*paragraphStyle = [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment
																	 lineBreakMode:NSLineBreakByTruncatingTail];
		
		//
		if(font){
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				font, NSFontAttributeName,
				nil];
		}else{
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				nil];
		}
		
		titleSize = [title sizeWithAttributes:attributes];
		
		if(subString){
			NSSize			subStringSize;

			attributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:10]
													 forKey:NSFontAttributeName];
			subStringSize = [subString sizeWithAttributes:attributes];
			
			//Use the wider of the two strings as the required width
			if(subStringSize.width > titleSize.width){
				cellSize.width += subStringSize.width;
			}else{
				cellSize.width += titleSize.width;
			}
			
			if(cellSize.height < (subStringSize.height + titleSize.height)){
				cellSize.height = (subStringSize.height + titleSize.height);
			}
		}else{
			//No substring
			cellSize.width += titleSize.width;
			if(cellSize.height < titleSize.height){
				cellSize.height = titleSize.height;
			}
		}
	}
	
	return(cellSize);
}

//Draw
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSString	*title = [self objectValue];
	NSImage		*image = [self image];
	BOOL 	highlighted;

//	[super drawInteriorWithFrame:cellFrame inView:controlView];
	
	highlighted = [self isHighlighted];
	if(highlighted){
		[self _drawHighlightWithFrame:cellFrame inView:controlView];
	}

	//Draw the cell's image
	if(image != nil){
		NSSize	size = [image size];
		NSSize  destSize = size;
		NSPoint	destPoint = cellFrame.origin;

		//Adjust the rects
		destPoint.y += 1;
		destPoint.x += 2;

		//Center image vertically, or scale as needed
		if (destSize.height > cellFrame.size.height){
			 float proportionChange = cellFrame.size.height / size.height;
			 destSize.height = cellFrame.size.height;
			 destSize.width = size.width * proportionChange;
		 }
		 
		 if (destSize.width > maxImageWidth){
			 float proportionChange = maxImageWidth / destSize.width;
			 destSize.width = maxImageWidth;
			 destSize.height = destSize.height * proportionChange;
		 }
		 
		if(destSize.height < cellFrame.size.height){
			destPoint.y += (cellFrame.size.height - destSize.height) / 2.0;
		} 
			
		 cellFrame.size.width -= destSize.width + 4;
		 cellFrame.origin.x += destSize.width + 5;
		 
		BOOL flippedIt = NO;
		if (![image isFlipped]){
			[image setFlipped:YES];
			flippedIt = YES;
		}
		
		[image drawInRect:NSMakeRect(destPoint.x,destPoint.y,destSize.width,destSize.height)
				 fromRect:NSMakeRect(0,0,size.width,size.height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
		if (flippedIt){
			[image setFlipped:NO];
		}
	}
	
	//Draw the cell's text
	if(title != nil){
		NSColor			*textColor;
		NSDictionary	*attributes;
		float			 stringHeight;

		//Determine the correct text color
		if(highlighted){
			textColor = [NSColor alternateSelectedControlTextColor]; //Draw the text inverted
		}else{
			if([self isEnabled]){
				textColor = [NSColor controlTextColor]; //Draw the text regular
			}else{
				textColor = [NSColor grayColor]; //Draw the text disabled
			}
		}

		//Adjust if a substring is present
		if(subString) cellFrame.size.height /= 2;

		//Padding
		cellFrame.origin.x += IMAGE_TEXT_PADDING;
		cellFrame.size.width -= IMAGE_TEXT_PADDING*2;
		
		//Truncating paragraph style
		NSParagraphStyle	*paragraphStyle = [NSParagraphStyle styleWithAlignment:NSLeftTextAlignment
																	 lineBreakMode:NSLineBreakByTruncatingTail];
		
		//
		if(font){
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				font, NSFontAttributeName,
				textColor, NSForegroundColorAttributeName,
				nil];
		}else{
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				textColor, NSForegroundColorAttributeName,
				nil];
		}

		//Calculate the centered rect
		stringHeight = [title sizeWithAttributes:attributes].height;
		if(stringHeight < cellFrame.size.height){
			cellFrame.origin.y += (cellFrame.size.height - stringHeight) / 2.0;
		}

		//Draw the string
		[title drawInRect:cellFrame withAttributes:attributes];

		//Draw the substring
		if(subString){
			//Determine the correct text color
			if(highlighted){
				textColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0]; //Draw the text inverted
			}else{
				if([self isEnabled]){
					textColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0]; //Draw the text regular
				}else{
					textColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0]; //Draw the text disabled
				}
			}

			cellFrame.origin.y += (cellFrame.size.height);

			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:10], NSFontAttributeName,
				textColor, NSForegroundColorAttributeName,
				nil];
			[subString drawInRect:cellFrame withAttributes:attributes];
		}
	}
}

@end
