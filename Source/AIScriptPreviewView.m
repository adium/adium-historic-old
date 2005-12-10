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

#import "AIScriptPreviewView.h"

@implementation AIScriptPreviewView

- (id)initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		//Create the text view
		readMeView = [[NSTextView alloc] initWithFrame:frame];
		[readMeView setEditable:NO];
				
		//Add it
		[self addSubview:readMeView];
		
		//Clean up
		[readMeView release];
    }
    return self;
}

- (void)setXtra:(AIXtraInfo *)xtraInfo
{
	//Load the readme and set it.
	NSAttributedString *readMeString = [[NSAttributedString alloc] initWithPath:[xtraInfo readMePath] documentAttributes:NULL];
	[[readMeView textStorage] setAttributedString:readMeString];
	
	//Clean up
	[readMeString release];
}

@end
