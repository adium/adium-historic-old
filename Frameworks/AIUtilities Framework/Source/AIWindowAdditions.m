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

#import "AIWindowAdditions.h"
#import "AIApplicationAdditions.h"

@implementation NSWindow (AIWindowAdditions)

/*
 * @brief Set content size with animation
 */
- (void)setContentSize:(NSSize)aSize display:(BOOL)displayFlag animate:(BOOL)animateFlag
{
	NSRect	frame = [self frame];
	NSSize	desiredSize;

	desiredSize = [self frameRectForContentRect:NSMakeRect(0, 0, aSize.width, aSize.height)].size;
	frame.origin.y += frame.size.height - desiredSize.height;
	frame.size = desiredSize;
	
	[self setFrame:frame display:displayFlag animate:animateFlag];
}


/*
 * @brief The method 'center' puts the window really close to the top of the screen.  This method puts it not so close.
 */
- (void)betterCenter
{
	NSRect	frame = [self frame];
	NSRect	screen = [[self screen] visibleFrame];
		
	[self setFrame:NSMakeRect(screen.origin.x + (screen.size.width - frame.size.width) / 2.0,
							  screen.origin.y + (screen.size.height - frame.size.height) / 1.2,
							  frame.size.width,
							  frame.size.height)
		   display:NO];
}

/*
 * @brief Height of the toolbar
 *
 * @result The height of the toolbar, or 0 if no toolbar exists or is visible
 */
- (float)toolbarHeight
{
	NSToolbar 	*toolbar = [self toolbar];
	float 		toolbarHeight = 0.0;
	
	if (toolbar && [toolbar isVisible]) {
		NSRect 		windowFrame = [NSWindow contentRectForFrameRect:[self frame]
														  styleMask:[self styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[self contentView] frame]);
	}
	
	return toolbarHeight;
}

/*
 * @brief Is this window textured/brushed metal?
 */
- (BOOL)isTextured
{
    return (([self styleMask] & NSTexturedBackgroundWindowMask) != 0);
}

/*
 * @brief Is this window borderless?
 */
- (BOOL)isBorderless
{
    return ([self styleMask] == NSBorderlessWindowMask);
}

/*
 * @brief Find the earliest responder which responds to a selector
 *
 * @param selector The target selector
 * @param classToAvoid If non-NULL, a Class which, even if it resopnds to selector, should be ignored
 * @param The NSResponder earliest in the responder chain which matches the passed values, or nil if no such responder exists
 */
- (NSResponder *)earliestResponderWhichRespondsToSelector:(SEL)selector andIsNotOfClass:(Class)classToAvoid
{
	NSResponder	*responder = [self firstResponder];

	//First, walk down the responder chain looking for a responder which can handle the preferred selector
	while (responder && (![responder respondsToSelector:selector] ||
						 ((classToAvoid && [responder isKindOfClass:classToAvoid])))) {
		responder = [responder nextResponder];
	}
	
	return responder;
}

/*
 * @brief Find the earliest responder of a specified class
 *
 * @param targetClass The target class
 * @result The NSResponder earliest in the responder chain which is of class targetClass, or nil if no such responder exists
 */
- (NSResponder *)earliestResponderOfClass:(Class)targetClass
{
	NSResponder	*responder = [self firstResponder];

	//First, walk down the responder chain looking for a responder which can handle the preferred selector
	while (responder && ![responder isKindOfClass:targetClass]) {
		responder = [responder nextResponder];
	}

	return responder;	
}

//We must weak link these symbols.  Failure to will crash us on launch under 10.2
//extern OSStatus CGSGetWindowTags(const CGSConnection cid, const CGSWindow wid, 
//								 int *tags, int thirtyTwo) __attribute__((weak_import));
//extern OSStatus CGSClearWindowTags(const CGSConnection cid, const CGSWindow wid, 
//								   int *tags, int thirtyTwo) __attribute__((weak_import));
//extern OSStatus CGSSetWindowTags(const CGSConnection cid, const CGSWindow wid, 
//								 int *tags, int thirtyTwo) __attribute__((weak_import));
-(void)setIgnoresExpose:(BOOL)flag
{
//	// ### This code correctly sets the expose flag, but doesn't remove it ###
//	
//	//Check for the presence of all three symbols.  If they do not exist, we simply return
//	if (CGSGetWindowTags != NULL && CGSClearWindowTags != NULL && CGSSetWindowTags != NULL) {
//		CGSConnection cid;
//		CGSWindow wid;
//		SInt32 vers; 
//		
//		//As an extra layer of security, make sure we're in 10.3 or newer
//		Gestalt(gestaltSystemVersion,&vers); 
//		if (vers >= 0x1030) {
//			wid = [self windowNumber];
//			cid = _CGSDefaultConnection();
//			int tags[2];
//			tags[0] = tags[1] = 0;
//			OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
//			if (!retVal) {
//				if (flag) {
//					tags[0] = tags[0] | 0x00000800;
//				} else {
//					tags[0] -= tags[0] & 0x00000800;
//				}
//				
//				CGSSetWindowTags(cid, wid, tags, 32);
//				
//				if (flag) {
//					tags[0] = 0x02;
//					tags[1] = 0;
//					CGSClearWindowTags(cid, wid, tags, 32);
//				}
//			}
//		}
//	}
}

@end
