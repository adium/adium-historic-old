/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AICursorAdditions.h"

@implementation NSCursor (AICursorAdditions)

//these methods always use an Appearance-themed cursor.
//first they look for the NSCursor methods that are only available on Panther and later.
//failing that, they call Appearance Manager's SetThemeCursor function.
+ (void)setOpenGrabHandCursor
{
	if([self respondsToSelector:@selector(openHandCursor)])
		[[NSCursor openHandCursor] set];
	else
		SetThemeCursor(kThemeOpenHandCursor);
}

+ (void)setClosedGrabHandCursor
{
	if([self respondsToSelector:@selector(closedHandCursor)])
		[[NSCursor closedHandCursor] set];
	else
		SetThemeCursor(kThemeClosedHandCursor);
}

+ (void)setHandPointCursor
{
	if([self respondsToSelector:@selector(pointingHandCursor)])
		[[NSCursor pointingHandCursor] set];
	else
		SetThemeCursor(kThemePointingHandCursor);
}

@end
