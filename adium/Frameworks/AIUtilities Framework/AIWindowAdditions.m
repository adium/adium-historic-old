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

#import "AIWindowAdditions.h"

@implementation NSWindow (AIWindowAdditions)

//Is this window textured/brushed metal?
- (BOOL)isTextured
{
    return(([self styleMask] & NSTexturedBackgroundWindowMask) != 0);
}

- (BOOL)isBorderless
{
    return([self styleMask] == NSBorderlessWindowMask);
}

- (void)compatibleInvalidateShadow
{
    if ([NSApp isOnJaguarOrBetter])
        [self invalidateShadow];
    else {
        BOOL hadShadow = [self hasShadow];
        [self setHasShadow:!hadShadow];
        [self setHasShadow:hadShadow];
    }
}

#if 0
//Exposé code from Richard Wareham, Desktop Manager developer
-(void)setIgnoresExpose:(BOOL)flag
{
	CGSConnection cid;
	CGSWindow wid;
	
	wid = [self windowNumber];
	cid = _CGSDefaultConnection();
	int tags[2];
	tags[0] = tags[1] = 0;
	
	OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
	if(!retVal) {
		if (flag)
			tags[0] = tags[0] | 0x00000800;
		else
			tags[0] = tags[0] & 0x00000800;
		
		retVal = CGSSetWindowTags(cid, wid, tags, 32);
	}
}
#endif


@end
