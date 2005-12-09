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

#import "AIEmoticonPreviewView.h"
#import "AIEmoticonPack.h"
#import "AIEmoticon.h"

@implementation AIEmoticonPreviewView

- (void) setXtra:(AIXtraInfo *)xtraInfo
{
	[images autorelease];
	images = [[NSMutableArray alloc] init];
	NSArray * emoticons = [[AIEmoticonPack emoticonPackFromPath:[xtraInfo path]] emoticons];
	NSEnumerator * e = [emoticons objectEnumerator];
	NSImage * image;
	NSSize size;
	NSSize maxEmoticonSize = NSZeroSize;
	AIEmoticon * emote;
	while((emote = [e nextObject]))
	{
		image = [emote image];
		if(image) {
			[images addObject:image];
			size = [image size];
			maxEmoticonSize.width = (size.width > maxEmoticonSize.width) ? size.width : maxEmoticonSize.width;	
			maxEmoticonSize.height = (size.height > maxEmoticonSize.height) ? size.height : maxEmoticonSize.height;

		}
	}
	[gridView setImageSize:maxEmoticonSize];
#warning this is SUCH a hack
	[(NSSplitView *)[[self superview] superview] adjustSubviews];
}

@end
