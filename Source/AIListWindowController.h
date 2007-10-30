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

#import "AIListController.h"
#import "AIDualWindowInterfacePlugin.h"
#import <Adium/AIWindowController.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <AIUtilities/AIFunctions.h>

typedef enum {
	AIContactListWindowHidingStyleNone = 0,
	AIContactListWindowHidingStyleBackground,
	AIContactListWindowHidingStyleSliding
} AIContactListWindowHidingStyle;

#define KEY_CL_WINDOW_HIDING_STYLE			@"Window Hiding Style"
#define KEY_CL_SLIDE_ONLY_IN_BACKGROUND		@"Hide By Sliding Only in Background"

#define PREF_GROUP_CONTACT_LIST_DISPLAY		@"Contact List Display"
#define KEY_SCL_BORDERLESS					@"Borderless"
#define KEY_DUAL_RESIZE_VERTICAL			@"Autoresize Vertical"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

@interface AIListWindowController : AIWindowController <AIInterfaceContainer, AIListControllerDelegate> {
	BOOL                                borderless;
	
	NSSize								minWindowSize;
	IBOutlet	AIAutoScrollView		*scrollView_contactList;
    IBOutlet	AIListOutlineView		*contactListView;
	AIListController					*contactListController;
	
	AIContactListWindowHidingStyle		windowHidingStyle;
	BOOL								slideOnlyInBackground;
	// refers to the GUI preference.  Sometimes this is expressed as dock-like 
	// sliding instead, sometimes as orderOut:-type hiding.
	BOOL								windowShouldBeVisibleInBackground; 

	// used by the "show contact list" event behavior to prevent the contact list
	// from hiding during the amount of time it is to be shown
	BOOL								preventHiding;
	BOOL								overrodeWindowLevel;
	int									previousWindowLevel;

	//this needs to be stored because we turn the shadow off when the window slides offscreen
	BOOL								listHasShadow; 
	
	BOOL								permitSlidingInForeground;
	AIRectEdgeMask						windowSlidOffScreenEdgeMask;
	NSScreen							*windowLastScreen;
	NSTimer								*slideWindowIfNeededTimer;
	
	NSRect								oldFrame;
	NSScreen							*currentScreen;
	NSRect								currentScreenFrame;
	
	NSViewAnimation						*windowAnimation;
	float								previousAlpha;
}

+ (AIListWindowController *)listWindowController;
+ (NSString *)nibName;
- (void)close:(id)sender;

// Dock-like hiding
- (void)slideWindowOnScreenWithAnimation:(BOOL)flag;
- (BOOL)shouldSlideWindowOnScreen;
- (BOOL)shouldSlideWindowOffScreen;

- (AIRectEdgeMask)slidableEdgesAdjacentToWindow;
- (void)slideWindowOffScreenEdges:(AIRectEdgeMask)rectEdgeMask;
- (void)slideWindowOnScreen;
- (void)setPreventHiding:(BOOL)newPreventHiding;
- (BOOL)windowShouldHideOnDeactivate;
- (AIRectEdgeMask)windowSlidOffScreenEdgeMask;
- (void)moveWindowToPoint:(NSPoint)inOrigin;

	void manualWindowMoveToPoint(NSWindow *inWindow,
								 NSPoint targetPoint,
								 AIRectEdgeMask windowSlidOffScreenEdgeMask,
								 BOOL keepOnScreen);

@end