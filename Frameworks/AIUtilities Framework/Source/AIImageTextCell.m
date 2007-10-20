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
#import "AIAttributedStringAdditions.h"

#define DEFAULT_MAX_IMAGE_WIDTH			24
#define DEFAULT_IMAGE_TEXT_PADDING		6

@interface NSCell (UndocumentedHighlightDrawing)
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end

@implementation AIImageTextCell

//Init
- (id)init
{
	if ((self = [super init])) {
		font = nil;
		subString = nil;
		maxImageWidth = DEFAULT_MAX_IMAGE_WIDTH;
		imageTextPadding = DEFAULT_IMAGE_TEXT_PADDING;
		[self setLineBreakMode:NSLineBreakByTruncatingTail];
	}

	return self;
}

//Dealloc
- (void)dealloc
{
	[font release]; font = nil;
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

	return newCell;
}

#pragma mark Accessors

/*
 * @brief Set the string value
 *
 * We redirect a call to setStringValue into one to setObjectValue. 
 * This prevents NSCell from messing up our font (normally, setStringValue: resets any font set on the cell).
 */
- (void)setStringValue:(NSString *)inString
{
	[self setObjectValue:inString];
}


//Font used to display our text
- (void)setFont:(NSFont *)inFont
{
    if (font != inFont) {
        [font release];
        font = [inFont retain];
    }
}
- (NSFont *)font
{
    return font;
}


//Substring (Displayed in gray below our main string)
- (void)setSubString:(NSString *)inSubString
{
	if (subString != inSubString) {
		[subString release];
		subString = [inSubString retain];
	}
}

- (void)setMaxImageWidth:(float)inWidth
{
	maxImageWidth = inWidth;
}

- (void)setImageTextPadding:(float)inImageTextPadding
{
	imageTextPadding = inImageTextPadding;
}

- (void)setLineBreakMode:(NSLineBreakMode)inLineBreakMode
{
	lineBreakMode = inLineBreakMode;
}

- (NSLineBreakMode)lineBreakMode
{
	return lineBreakMode;
}

#pragma mark Drawing

- (NSSize)cellSizeForBounds:(NSRect)cellFrame
{
	NSString	*title = [self objectValue];
	NSImage		*image = [self image];
	NSSize		cellSize = NSZeroSize;
	
	if (image) {
		NSSize	destSize = [image size];

		//Center image vertically, or scale as needed
		if (destSize.height > cellFrame.size.height) {
			float proportionChange = cellFrame.size.height / destSize.height;
			destSize.height = cellFrame.size.height;
			destSize.width = destSize.width * proportionChange;
		}
		
		if (destSize.width > maxImageWidth) {
			float proportionChange = maxImageWidth / destSize.width;
			destSize.width = maxImageWidth;
			destSize.height = destSize.height * proportionChange;
		}

		cellSize.width += destSize.width + imageTextPadding;
		cellSize.height = destSize.height;
	}
	
	if (title != nil) {
		NSDictionary	*attributes;
		NSSize			titleSize;

		cellSize.width += (imageTextPadding * 2);
		
		//Truncating paragraph style
		NSParagraphStyle	*paragraphStyle = [NSParagraphStyle styleWithAlignment:[self alignment]
																	 lineBreakMode:lineBreakMode];
		
		//
		if ([self font]) {
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[self font], NSFontAttributeName,
				nil];
		} else {
			attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				nil];
		}
		
		titleSize = [title sizeWithAttributes:attributes];
		
		if (subString) {
			NSSize			subStringSize;

			attributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:10]
													 forKey:NSFontAttributeName];
			subStringSize = [subString sizeWithAttributes:attributes];
			
			//Use the wider of the two strings as the required width
			if (subStringSize.width > titleSize.width) {
				cellSize.width += subStringSize.width;
			} else {
				cellSize.width += titleSize.width;
			}
			
			if (cellSize.height < (subStringSize.height + titleSize.height)) {
				cellSize.height = (subStringSize.height + titleSize.height);
			}
		} else {
			//No substring
			cellSize.width += titleSize.width;
			if (cellSize.height < titleSize.height) {
				cellSize.height = titleSize.height;
			}
		}
	}
	
	return cellSize;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSString	*title = [self stringValue];
	NSImage		*image = [self image];
	BOOL		highlighted = [self isHighlighted];

	//Draw the cell's image
	if (image != nil) {
		NSSize	size = [image size];
		NSSize  destSize = size;
		NSPoint	destPoint = cellFrame.origin;
		
		//Adjust the rects
		destPoint.y += 1;
		destPoint.x += imageTextPadding;
		
		//Center image vertically, or scale as needed
		if (destSize.height > cellFrame.size.height) {
			 float proportionChange = cellFrame.size.height / size.height;
			 destSize.height = cellFrame.size.height;
			 destSize.width = size.width * proportionChange;
		 }
		 
		 if (destSize.width > maxImageWidth) {
			 float proportionChange = maxImageWidth / destSize.width;
			 destSize.width = maxImageWidth;
			 destSize.height = destSize.height * proportionChange;
		 }
		 
		if (destSize.height < cellFrame.size.height) {
			destPoint.y += (cellFrame.size.height - destSize.height) / 2.0;
		} 

		//Decrease the cell width by the width of the image we drew and its left padding
		cellFrame.size.width -= imageTextPadding + destSize.width;
		
		//Shift the origin over to the right edge of the image we just drew
		cellFrame.origin.x += imageTextPadding + destSize.width;
		
		BOOL flippedIt = NO;
		if (![image isFlipped]) {
			[image setFlipped:YES];
			flippedIt = YES;
		}
		
		[NSGraphicsContext saveGraphicsState];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[image drawInRect:NSMakeRect(destPoint.x,destPoint.y,destSize.width,destSize.height)
				 fromRect:NSMakeRect(0,0,size.width,size.height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
		[NSGraphicsContext restoreGraphicsState];

		if (flippedIt) {
			[image setFlipped:NO];
		}
	}
	
	//Draw the cell's text
	if (title != nil) {
		NSAttributedString	*attributedMainString, *attributedSubString;
		NSColor				*mainTextColor, *subStringTextColor;
		NSDictionary		*mainAttributes, *subStringAttributes;
		float				mainStringHeight = 0.0, subStringHeight = 0.0, textSpacing = 0.0;

		//Determine the correct text color
		NSWindow			*window;

		//If we don't have a control view, or we do and it's the first responder, draw the text in the alternateSelectedControl text color (white)
		if (highlighted && ((window = [controlView window]) &&
							([window isKeyWindow] && ([window firstResponder] == controlView)))) {
			// Draw the text inverted
			mainTextColor = [NSColor alternateSelectedControlTextColor];
			subStringTextColor = [NSColor alternateSelectedControlTextColor];
		} else {
			if ([self isEnabled]) {
				// Draw the text regular
				mainTextColor = [NSColor controlTextColor];
				subStringTextColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
			} else {
				// Draw the text disabled
				mainTextColor = [NSColor grayColor];
				subStringTextColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
			}
		}
		
		/* Padding: Origin goes right by our padding amount, and the width decreases by twice it
		 * (for left and right padding).
		 */
		if (image != nil) {
			cellFrame.origin.x += imageTextPadding;
			cellFrame.size.width -= imageTextPadding * 2;
		}

		//Paragraph style
		NSParagraphStyle	*paragraphStyle = [NSParagraphStyle styleWithAlignment:[self alignment]
																	 lineBreakMode:lineBreakMode];		
		//
		if ([self font]) {
			mainAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[self font], NSFontAttributeName,
				mainTextColor, NSForegroundColorAttributeName,
				nil];
		} else {
			mainAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				mainTextColor, NSForegroundColorAttributeName,
				nil];
		}
		
		attributedMainString = [[NSAttributedString alloc] initWithString:title
															   attributes:mainAttributes];
		
		if (subString) {
			// Keep the mainString NSDictionary attributes in case we're
			// using NSLineBreakByTruncatingMiddle line breaking (see below).
			subStringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:10], NSFontAttributeName,
				subStringTextColor, NSForegroundColorAttributeName,
				nil];
			
			attributedSubString = [[NSAttributedString alloc] initWithString:subString
																  attributes:subStringAttributes];
		}

		switch (lineBreakMode) {
			case NSLineBreakByWordWrapping:
			case NSLineBreakByCharWrapping:
				mainStringHeight = [attributedMainString heightWithWidth:cellFrame.size.width];
				if (subString) {
					subStringHeight = [attributedSubString heightWithWidth:cellFrame.size.width];
				}
				break;
			case NSLineBreakByClipping:
			case NSLineBreakByTruncatingHead:
			case NSLineBreakByTruncatingTail:
			case NSLineBreakByTruncatingMiddle:
				mainStringHeight = [title sizeWithAttributes:mainAttributes].height;
				if (subString) {
					subStringHeight = [subString sizeWithAttributes:subStringAttributes].height;
				}
				break;
		}

		//Calculate the centered rect
		if (!subString && mainStringHeight < cellFrame.size.height) {
			// Space out the main string evenly
			cellFrame.origin.y += (cellFrame.size.height - mainStringHeight) / 2.0;
		} else if (subString) {
			// Space out our extra space evenly
			textSpacing = (cellFrame.size.height - mainStringHeight - subStringHeight) / 3.0;
			// In case we don't have enough height..
			if (textSpacing < 0.0)
				textSpacing = 0.0;
			cellFrame.origin.y += textSpacing;
		}

		//Draw the string
		[attributedMainString drawInRect:cellFrame];
		[attributedMainString release];
		
		//Draw the substring
		if (subString) {
			cellFrame.origin.y += mainStringHeight + textSpacing;
			
			//Draw the substring
			[attributedSubString drawInRect:cellFrame];
			[attributedSubString release];
		}
	}
}

#pragma mark Accessibility

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return NSAccessibilityButtonRole;
		
    } else if([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
        return [self stringValue];
		
    } else if([attribute isEqualToString:NSAccessibilityHelpAttribute]) {
        return [self stringValue];
		
	} else if ([attribute isEqualToString: NSAccessibilityWindowAttribute]) {
		return [super accessibilityAttributeValue:NSAccessibilityWindowAttribute];
		
	} else if ([attribute isEqualToString: NSAccessibilityTopLevelUIElementAttribute]) {
		return [super accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
		
    } else {
        return [super accessibilityAttributeValue:attribute];
    }
}


@end
