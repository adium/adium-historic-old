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

@class AIListGroup, AISCLOutlineView;
@protocol AIContactListViewController;

@interface AISCLViewController : AIObject <AIContactListViewController> {    
    AIListGroup			*contactList;
    AISCLOutlineView	*contactListView;

    BOOL                horizontalResizingEnabled;
	NSPoint				lastMouseLocation;
    
	NSTimer				*tooltipMouseLocationTimer;
	NSPoint				tooltipLocation;
    NSTrackingRectTag	tooltipTrackingTag;
    int 				tooltipCount;
	BOOL				windowHidesOnDeactivate;
	
	BOOL				inDrag;
	NSArray				*dragItems;
	
	BOOL				alreadyDidDealloc;
}

+ (AISCLViewController *)contactListViewController;
- (IBAction)performDefaultActionOnSelectedContact:(id)sender;
- (NSView *)contactListView;
- (void)view:(NSView *)inView willMoveToSuperview:(NSView *)inSuperview;
- (void)view:(NSView *)inView didMoveToSuperview:(NSView *)inSuperview;
- (void)view:(NSView *)inView didMoveToWindow:(NSWindow *)window;
- (void)window:(NSWindow *)inWindow didResignMain:(NSNotification *)notification;
- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent;
- (void)hideTooltip;
- (void)window:(NSWindow *)inWindow didBecomeMain:(NSNotification *)notification;

@end
