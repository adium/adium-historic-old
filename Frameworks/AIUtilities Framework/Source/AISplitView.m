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

#import "AISplitView.h"


@interface AISplitView (PRIVATE)
- (void)_initSplitView;
@end

@implementation AISplitView

//Init
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (([super initWithCoder:aDecoder])) {
		[self _initSplitView];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _initSplitView];
	}
	return self;
}

- (void)_initSplitView
{
	dividerThickness = [super dividerThickness];
	drawDivider = YES;
}

//Divider thickness
- (void)setDividerThickness:(float)inThickness{
	dividerThickness = inThickness;
}
- (float)dividerThickness{
	return dividerThickness;
}

//Divider drawing
- (void)setDrawsDivider:(BOOL)inDraw{
	drawDivider = inDraw;
}
- (void)drawDividerInRect:(NSRect)aRect{
	if (drawDivider) {
		[super drawDividerInRect:aRect];
	}
}

@end
