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

#import "AIImageGridXtraPreviewView.h"

@implementation AIImageGridXtraPreviewView

- (id) initWithFrame:(NSRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		images = [[NSMutableArray alloc] init];
		gridView = [[[AIImageGridView alloc] initWithFrame:[self bounds]] autorelease];
		[gridView setDelegate:self];
		[gridView setDrawsBackground:NO];
		[self addSubview:gridView];
	}
	return self;
}

- (int)numberOfImagesInImageGridView:(AIImageGridView *)imageGridView
{
	return [images count];
}

- (NSImage *)imageGridView:(AIImageGridView *)imageGridView imageAtIndex:(int)index
{
	return [images objectAtIndex:index];
}

- (BOOL)imageGridView:(AIImageGridView *)imageGridView shouldSelectIndex:(int)index
{
	return NO;
}

- (BOOL)isFlipped
{
	return YES;
}

- (void) dealloc
{
	[images release];
	[super dealloc]; //gridView is retained by the NSView code
}

@end
