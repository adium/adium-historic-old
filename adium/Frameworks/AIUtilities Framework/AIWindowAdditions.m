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

//The method 'center' puts the window really close to the top of the screen.  This method puts it not so close.
- (void)betterCenter
{
	NSRect	frame = [self frame];
	NSRect	screen = [[self screen] visibleFrame];
		
	[self setFrame:NSMakeRect(screen.origin.x + (screen.size.width - frame.size.width) / 2.0,
							  screen.origin.y + (screen.size.height - frame.size.height) / 1.5,
							  frame.size.width,
							  frame.size.height)
		   display:NO];
}


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

//Expos� code from Richard Wareham, Desktop Manager developer
//Modified by Yann Bizeul, GeekTool Developer :-)
-(void)setIgnoresExpose:(BOOL)flag
{
#warning this code prevents us from launching in 10.2
//    CGSConnection cid;
//    CGSWindow wid;
//    SInt32 vers; 
//    
//    Gestalt(gestaltSystemVersion,&vers); 
//    if (vers < 0x1030)
//	return;
//    wid = [ self windowNumber ];
//    cid = _CGSDefaultConnection();
//    int tags[2];
//    tags[0] = tags[1] = 0;
//    OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
//    if(!retVal) {
//	if (flag)
//	    tags[0] = tags[0] | 0x00000800;
//	else
//	    tags[0] -= tags[0] & 0x00000800;
//	
//	CGSSetWindowTags(cid, wid, tags, 32);
//	
//	if (flag) {
//	    tags[0] = 0x02;
//	    tags[1] = 0;
//	    CGSClearWindowTags(cid, wid, tags, 32);
//	}
//    }
}
@end
