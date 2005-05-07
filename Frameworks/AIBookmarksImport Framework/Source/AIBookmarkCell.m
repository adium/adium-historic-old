/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIBookmarkCell.h"

#import "AIBookmarksImporter.h"

#define LEFT_MARGIN 4.0 /*pt*/
#define SPACE_BETWEEN_IMAGE_AND_TEXT 4.0 /*pt*/

@implementation AIBookmarkCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	cellFrame.origin.x   += LEFT_MARGIN;
	cellFrame.size.width -= LEFT_MARGIN;

	NSDictionary *bookmark = [self objectValue];

	NSImage *image = [bookmark objectForKey:ADIUM_BOOKMARK_DICT_FAVICON];
	if(image) {
		NSSize imageSize = [image size];
		NSRect imageRect = { NSZeroPoint, imageSize };

		float y = NSMidY(cellFrame) - (imageSize.height / 2.0);
		[image drawAtPoint:NSMakePoint(cellFrame.origin.x, y)
				  fromRect:imageRect
				 operation:NSCompositeSourceOver
				  fraction:1.0];

		float delta = imageSize.width + SPACE_BETWEEN_IMAGE_AND_TEXT;
		cellFrame.origin.x   += delta;
		cellFrame.size.width -= delta;
	}

	NSAttributedString *title = [bookmark objectForKey:ADIUM_BOOKMARK_DICT_TITLE];
	if(title) {
		NSDictionary *attrs;
		if([title isKindOfClass:[NSString class]]) {
			attrs = [NSDictionary dictionaryWithObjectsAndKeys:
				[self font], NSFontAttributeName,
				nil];
			title = [[[NSAttributedString alloc] initWithString:(NSString *)title
													 attributes:attrs] autorelease];
		}

		NSMutableAttributedString *mTitle = [title mutableCopy];

		NSLineBreakMode lineBreakMode = NSLineBreakByTruncatingTail;
		if([self respondsToSelector:@selector(lineBreakMode)]) {
			//Tiger
			lineBreakMode = [self lineBreakMode];
		}

		//make sure the entire string is set to our line-break mode
		unsigned i = 0, length = [mTitle length];
		NSRange range = { 0, length };
		NSMutableParagraphStyle *defaultParagraphStyle = nil;
		while(i < length) {
			NSParagraphStyle *immutable = [mTitle attribute:NSParagraphStyleAttributeName
													atIndex:i
											 effectiveRange:&range];
			if(!immutable) immutable = defaultParagraphStyle;
			NSMutableParagraphStyle *paragraphStyle = [[[mTitle attribute:NSParagraphStyleAttributeName
																  atIndex:i
														   effectiveRange:&range] mutableCopy] autorelease];
			if(!paragraphStyle) {
				if(!defaultParagraphStyle) {
					defaultParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
				}
				paragraphStyle = defaultParagraphStyle;
			}

			[paragraphStyle setLineBreakMode:lineBreakMode];
			[mTitle addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];

			i = range.location + range.length;
		}

		[mTitle drawInRect:cellFrame];

		[mTitle release];
	}
}

@end
