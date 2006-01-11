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

#import "AIChatController.h"
#import "AIInterfaceController.h"
#import "AIListLayoutWindowController.h"
#import "AIListOutlineView.h"
#import "AIListThemeWindowController.h"
#import "AIListWindowController.h"
#import "AIPreferenceController.h"
#import "AIDockController.h"
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIFunctions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIUserIcons.h>

#define CONTACT_LIST_WINDOW_NIB				@"ContactListWindow"		//Filename of the contact list window nib
#define CONTACT_LIST_WINDOW_TRANSPARENT_NIB @"ContactListWindowTransparent" //Filename of the minimalist transparent version
#define CONTACT_LIST_TOOLBAR				@"ContactList"				//ID of the contact list toolbar
#define	KEY_DUAL_CONTACT_LIST_WINDOW_FRAME	@"Dual Contact List Frame 2"

#define PREF_GROUP_CONTACT_LIST		@"Contact List"
#define KEY_CLWH_WINDOW_POSITION	@"Contact Window Position"
#define KEY_CLWH_HIDE				@"Hide While in Background"

#define TOOL_TIP_CHECK_INTERVAL				45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY						25.0	//Number of check intervals of no movement before a tip is displayed

#define MAX_DISCLOSURE_HEIGHT				13		//Max height/width for our disclosure triangles

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

#define PREF_GROUP_CONTACT_STATUS_COLORING	@"Contact Status Coloring"

#define SLIDE_ALLOWED_RECT_EDGE_MASK  		(AIMinXEdgeMask | AIMaxXEdgeMask)
#define DOCK_HIDING_MOUSE_POLL_INTERVAL		0.1
#define WINDOW_ALIGNMENT_TOLERANCE			2.0f
#define MOUSE_EDGE_SLIDE_ON_DISTANCE		1.1f

@interface AIListWindowController (PRIVATE)
- (void)windowDidLoad;
- (void)_configureAutoResizing;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
+ (void)updateScreenSlideBoundaryRect:(id)sender;
- (BOOL)shouldSlideWindowOffScreen_mousePositionStrategy;
- (void)slideWindowIfNeeded:(id)sender;
- (BOOL)shouldSlideWindowOnScreen_mousePositionStrategy;
- (BOOL)shouldSlideWindowOnScreen_adiumActiveStrategy;
- (BOOL)shouldSlideWindowOffScreen_adiumActiveStrategy;
- (void)setPermitSlidingInForeground:(BOOL)flag;
@end

@implementation AIListWindowController

+ (void)initialize
{
	if ([self isEqual:[AIListWindowController class]]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateScreenSlideBoundaryRect:) 
													 name:NSApplicationDidChangeScreenParametersNotification 
												   object:nil];
		
		[self updateScreenSlideBoundaryRect:nil];
	}
}

//Return a new contact list window controller
+ (AIListWindowController *)listWindowController
{
    return [[[self alloc] initWithWindowNibName:[self nibName]] autorelease];
}

//Our window nib name
+ (NSString *)nibName
{
    return @"";
}

- (Class)listControllerClass
{
	return [AIListController class];
}

//Init
- (id)initWithWindowNibName:(NSString *)inNibName
{	
    if ((self = [super initWithWindowNibName:inNibName])) {
		preventHiding = NO;
	}

    return self;
}

- (void)dealloc
{
	[contactListController close];

	[super dealloc];
}


//
- (NSString *)adiumFrameAutosaveName
{
	return KEY_DUAL_CONTACT_LIST_WINDOW_FRAME;
}

//Setup the window after it has loaded
- (void)windowDidLoad
{
	[super windowDidLoad];

	contactListController = [[[self listControllerClass] alloc] initWithContactListView:contactListView
																		   inScrollView:scrollView_contactList 
																			   delegate:self];
	
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
	[[self window] useOptimizedDrawing:YES];

	minWindowSize = [[self window] minSize];
	[contactListController setMinWindowSize:minWindowSize];

    //Watch for resolution and screen configuration changes
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(screenParametersChanged:) 
												 name:NSApplicationDidChangeScreenParametersNotification 
											   object:nil];

	AIPreferenceController *preferenceController = [adium preferenceController];
    //Observe preference changes
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
	
	//Preference code below assumes layout is done before theme.
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_LAYOUT];
	[preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
    
    //Decide whether the contact list needs to hide when the app is about to deactivate
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateWindowHidesOnDeactivateWithNotification:) 
												 name:NSApplicationWillResignActiveNotification 
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateWindowHidesOnDeactivateWithNotification:) 
												 name:NSApplicationWillBecomeActiveNotification 
											   object:nil];
}

//Close the contact list window
- (void)windowWillClose:(NSNotification *)notification
{
	// don't let the window's saved position be offscreen
	// need to do this before calling -[AIWindowController windowWillClose:], because it's
	// that method that does the saving.  
	[self slideWindowOnScreen]; 
	[super windowWillClose:notification];

	// kill dock-like hiding timer, if it isn't nil
	[slideWindowIfNeededTimer invalidate];

    //Stop observing
	[[adium preferenceController] unregisterPreferenceObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

    //Tell the interface to unload our window
    NSNotificationCenter *adiumNotificationCenter = [adium notificationCenter];
    [adiumNotificationCenter postNotificationName:Interface_ContactListDidResignMain object:self];
	[adiumNotificationCenter postNotificationName:Interface_ContactListDidClose object:self];
}

//Preferences have changed
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
    if ([group isEqualToString:PREF_GROUP_CONTACT_LIST]) {
		AIWindowLevel	windowLevel = [[prefDict objectForKey:KEY_CL_WINDOW_LEVEL] intValue];
		int				level = NSNormalWindowLevel;
		
		switch (windowLevel) {
			case AINormalWindowLevel: level = NSNormalWindowLevel; break;
			case AIFloatingWindowLevel: level = NSFloatingWindowLevel; break;
			case AIDesktopWindowLevel: level = kCGDesktopWindowLevel; break;
		}

		[[self window] setLevel:level];
		[[self window] setIgnoresExpose:(windowLevel == AIDesktopWindowLevel)]; //Ignore expose while on the desktop

		[[self window] setHasShadow:[[prefDict objectForKey:KEY_CL_WINDOW_HAS_SHADOW] boolValue]];
		windowShouldBeVisibleInBackground = ![[prefDict objectForKey:KEY_CL_HIDE] boolValue];
		permitSlidingInForeground = [[prefDict objectForKey:KEY_CL_EDGE_SLIDE] boolValue];
		
		// don't slide the window the first time this is called, because the contact list will display
		// before it is prepared.  This produces screen artifacts.
		if (!firstTime)
			[self slideWindowIfNeeded:nil];

		if (!windowShouldBeVisibleInBackground || permitSlidingInForeground) {
			if (slideWindowIfNeededTimer == nil) {
				slideWindowIfNeededTimer = [NSTimer scheduledTimerWithTimeInterval:DOCK_HIDING_MOUSE_POLL_INTERVAL
																			target:self
																		  selector:@selector(slideWindowIfNeeded:)
																		  userInfo:nil
																		   repeats:YES];            				
			}
		}
		else {
            [slideWindowIfNeededTimer invalidate];
			slideWindowIfNeededTimer = nil;
		}

		[contactListController setShowTooltips:[[prefDict objectForKey:KEY_CL_SHOW_TOOLTIPS] boolValue]];
		[contactListController setShowTooltipsInBackground:[[prefDict objectForKey:KEY_CL_SHOW_TOOLTIPS_IN_BACKGROUND] boolValue]];
    }

    if ([group isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]) {
		if ([key isEqualToString:KEY_SCL_BORDERLESS]) {
			[self retain];
			[[adium interfaceController] closeContactList:nil];
			[[adium interfaceController] showContactList:nil];
			[self autorelease];
		}
	}
	
	//Auto-Resizing
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		int				windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
		BOOL			autoResizeVertically = [[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue];
		BOOL			autoResizeHorizontally = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
		int				forcedWindowWidth, maxWindowWidth;
		
		if (autoResizeHorizontally) {
			//If autosizing, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the maximum width; no forced width.
			maxWindowWidth = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue];
			forcedWindowWidth = -1;
		} else {
			if (windowStyle == WINDOW_STYLE_STANDARD/* || windowStyle == WINDOW_STYLE_BORDERLESS*/) {
				//In the non-transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH has no meaning
				maxWindowWidth = 10000;
				forcedWindowWidth = -1;
			} else {
				//In the transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the width of the window
				forcedWindowWidth = [[prefDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue];
				maxWindowWidth = forcedWindowWidth;
			}
		}
		
		//Show the resize indicator if either or both of the autoresizing options is NO
		[[self window] setShowsResizeIndicator:!(autoResizeVertically && autoResizeHorizontally)];
		
		/*
		 Reset the minimum and maximum sizes in case [self contactListDesiredSizeChanged:nil]; doesn't cause a sizing change
		 (and therefore the min and max sizes aren't set there).
		 */
		NSSize	thisMinimumSize = minWindowSize;
		NSSize	thisMaximumSize = NSMakeSize(maxWindowWidth, 10000);
		NSRect	currentFrame = [[self window] frame];
		
		if (forcedWindowWidth != -1) {
			/*
			 If we have a forced width but we are doing no autoresizing, set our frame now so we don't have t be doing checks every time
			 contactListDesiredSizeChanged is called.
			 */
			if (!(autoResizeVertically || autoResizeHorizontally)) {
				thisMinimumSize.width = forcedWindowWidth;
				
				[[self window] setFrame:NSMakeRect(currentFrame.origin.x,currentFrame.origin.y,forcedWindowWidth,currentFrame.size.height) 
								display:YES
								animate:NO];
			}
		}
		
		//If vertically resizing, make the minimum and maximum heights the current height
		if (autoResizeVertically) {
			thisMinimumSize.height = currentFrame.size.height;
			thisMaximumSize.height = currentFrame.size.height;
		}
		
		//If horizontally resizing, make the minimum and maximum widths the current width
		if (autoResizeHorizontally) {
			thisMinimumSize.width = currentFrame.size.width;
			thisMaximumSize.width = currentFrame.size.width;			
		}
		
		[[self window] setMinSize:thisMinimumSize];
		[[self window] setMaxSize:thisMaximumSize];
		
		[contactListController setAutoresizeHorizontally:autoResizeHorizontally];
		[contactListController setAutoresizeVertically:autoResizeVertically];
		[contactListController setForcedWindowWidth:forcedWindowWidth];
		[contactListController setMaxWindowWidth:maxWindowWidth];
		[contactListController contactListDesiredSizeChanged];
	}

	//Window opacity
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		float opacity = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_OPACITY] floatValue];		
		[contactListController setBackgroundOpacity:opacity];
	}
	
	//Layout and Theme ------------
	BOOL groupLayout = ([group isEqualToString:PREF_GROUP_LIST_LAYOUT]);
	BOOL groupTheme = ([group isEqualToString:PREF_GROUP_LIST_THEME]);
    if (groupLayout || (groupTheme && !firstTime)) { /* We don't want to execute this code twice when initializing */
        NSDictionary	*layoutDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
		NSDictionary	*themeDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_THEME];
		
		//Layout only
		if (groupLayout) {
			int iconSize = [[layoutDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue];
			[AIUserIcons setListUserIconSize:NSMakeSize(iconSize,iconSize)];
		}
			
		//Theme only
		if (groupTheme || firstTime) {
			NSString		*imagePath = [themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH];
			
			//Background Image
			if (imagePath && [imagePath length] && [[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED] boolValue]) {
				[contactListView setBackgroundImage:[[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease]];
			} else {
				[contactListView setBackgroundImage:nil];
			}
		}

		//Both layout and theme
		[contactListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];
	}
}

- (IBAction)performDefaultActionOnSelectedObject:(AIListObject *)selectedObject sender:(NSOutlineView *)sender
{	
    if ([selectedObject isKindOfClass:[AIListGroup class]]) {
        //Expand or collapse the group
        if ([sender isItemExpanded:selectedObject]) {
            [sender collapseItem:selectedObject];
        } else {
            [sender expandItem:selectedObject];
        }
		
    } else if ([selectedObject isKindOfClass:[AIListContact class]]) {
		//Hide any tooltip the contactListController is currently showing
		[contactListController hideTooltip];

		//Open a new message with the contact
		[[adium interfaceController] setActiveChat:[[adium chatController] openChatWithContact:(AIListContact *)selectedObject]];
		
    }
}


//Interface Container --------------------------------------------------------------------------------------------------
#pragma mark Interface Container
//Close this container
- (void)close:(id)sender
{
    //In response to windowShouldClose, the interface controller releases us.  At that point, no one would be retaining
	//this instance of AIContactListWindowController, and we would be deallocated.  The call to [self window] will
	//crash if we are deallocated.  A dirty, but functional fix is to temporarily retain ourself here.
    [self retain];

    if ([self windowShouldClose:nil]) {
        [[self window] close];
    }

    [self release];
}

//Contact list brought to front
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//Contact list sent back
- (void)windowDidResignKey:(NSNotification *)notification
{
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidResignMain object:self];
}

//
- (void)showWindowInFront:(BOOL)inFront
{
	if (inFront) {
		[self showWindow:nil];
	} else {
		[[self window] orderWindow:NSWindowBelow relativeTo:[[NSApp mainWindow] windowNumber]];
	}
}


// Auto-resizing support ------------------------------------------------------------------------------------------------
#pragma mark Auto-resizing support

- (void)screenParametersChanged:(NSNotification *)notification
{
	[self slideWindowOnScreen];
	[contactListController contactListDesiredSizeChanged];
}

// Printing
#pragma mark Printing
- (void)adiumPrint:(id)sender
{
	[contactListView print:sender];
}

// Dock-like hiding -----------------------------------------------------------------------------------------------------
#pragma mark Dock-like hiding

// screenSlideBoundaryRect is the rect that the contact list slides in and out of for dock-like hiding
// screenSlideBoundaryRect = (menubarScreen frame without menubar) union (union of frames of all other screens) 
static NSRect screenSlideBoundaryRect = { {0.0f, 0.0f}, {0.0f, 0.0f} };
+ (void)updateScreenSlideBoundaryRect:(id)sender
{
	NSArray *screens = [NSScreen screens];
	int numScreens = [screens count];
	int i;
	
	if (numScreens > 0) {
		// menubar screen is a special case - the menubar is not a part of the rect we're interested in
		NSScreen *menubarScreen = [screens objectAtIndex:0];
		screenSlideBoundaryRect = [menubarScreen frame];
		screenSlideBoundaryRect.size.height = NSMaxY([menubarScreen visibleFrame]) - NSMinY([menubarScreen frame]);
		for (i = 1; i < numScreens; i++) {
			screenSlideBoundaryRect = NSUnionRect(screenSlideBoundaryRect, [[screens objectAtIndex:i] frame]);
		}		
	}
}

- (void)updateWindowHidesOnDeactivateWithNotification:(NSNotification *)notification
{
    if ([notification isKindOfClass:[NSNotification class]] && [[notification name] isEqualToString:NSApplicationWillResignActiveNotification]) {
        [[self window] setHidesOnDeactivate:[self windowShouldHideOnDeactivate]];
    }
    else {
        [[self window] setHidesOnDeactivate:NO];
        [[[self window] contentView] setNeedsDisplay:YES];
    }
}

// this refers to the value of [[self window] hidesOnDeactivate]
// this should return NO if we're going to do dock-like sliding
// instead of orderOut:-type hiding.
- (BOOL)windowShouldHideOnDeactivate
{
	BOOL shouldHideOnDeactivate = NO;
		
	if (!windowShouldBeVisibleInBackground) {
		shouldHideOnDeactivate = YES; // unless..
		
		// window is slid off the screen
		if (windowSlidOffScreenEdgeMask != 0) {
			shouldHideOnDeactivate = NO;
		}
		
		// or window is in position to slide off of the screen
		if ([self slidableEdgesAdjacentToWindow] != 0) {
			shouldHideOnDeactivate = NO;
		}
	}

	return shouldHideOnDeactivate;
}

- (void)slideWindowIfNeeded:(id)sender
{
	if ([self shouldSlideWindowOnScreen]) {
		[self slideWindowOnScreen];

	} else if([self shouldSlideWindowOffScreen]) {
		AIRectEdgeMask adjacentEdges = [self slidableEdgesAdjacentToWindow];
        if (adjacentEdges & (AIMinXEdgeMask | AIMaxXEdgeMask))
            [self slideWindowOffScreenEdges:(adjacentEdges & (AIMinXEdgeMask | AIMaxXEdgeMask))];
        else
            [self slideWindowOffScreenEdges:adjacentEdges];
	}
}

- (BOOL)shouldSlideWindowOnScreen
{
	BOOL shouldSlide = NO;
	
	if ((permitSlidingInForeground && ![NSApp isHidden]) || (![NSApp isActive] && !windowShouldBeVisibleInBackground)) {
		shouldSlide = [self shouldSlideWindowOnScreen_mousePositionStrategy];
	}
	else if (!permitSlidingInForeground && [NSApp isActive] && (windowSlidOffScreenEdgeMask != 0))
	{
		shouldSlide = YES;
	}
	
	return shouldSlide;
}

- (BOOL)shouldSlideWindowOffScreen
{
	BOOL shouldSlide = NO;
	    if (preventHiding) {
        shouldSlide = NO;
    }
    else if (windowSlidOffScreenEdgeMask != 0) {
        // window is already slid off screen in some direction
        shouldSlide = NO;
    }
    else if (permitSlidingInForeground) {
        shouldSlide = [self shouldSlideWindowOffScreen_mousePositionStrategy];
    } 
    else if (!windowShouldBeVisibleInBackground && ![NSApp isActive] && [[self window] isVisible]) {
        shouldSlide = [self shouldSlideWindowOffScreen_mousePositionStrategy];
    }

	return shouldSlide;
}

// slide off screen if the window is aligned to a screen edge and the mouse is not in the strip of screen 
// you'd get by translating the window along the screen edge.  This is the dock's behavior.
- (BOOL)shouldSlideWindowOffScreen_mousePositionStrategy
{
	BOOL shouldSlideOffScreen = NO;
	
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	NSPoint mouseLocation = [NSEvent mouseLocation];
	
	AIRectEdgeMask slidableEdgesAdjacentToWindow = [self slidableEdgesAdjacentToWindow];
	NSRectEdge screenEdge;
	for (screenEdge = 0; screenEdge < 4; screenEdge++) {		
		if (slidableEdgesAdjacentToWindow & (1 << screenEdge)) {
			float distanceMouseOutsideWindow = AISignedExteriorDistanceRect_edge_toPoint_(windowFrame, AIOppositeRectEdge_(screenEdge), mouseLocation);
			if (distanceMouseOutsideWindow > 0)
				shouldSlideOffScreen = YES;
		}
	}
	
	// don't allow the window to slide off if the user is dragging
	// this method is hacky and does not completely work.  is there a way to detect if the mouse is down?
	NSEventType currentEventType = [[NSApp currentEvent] type];
	if (currentEventType == NSLeftMouseDragged || currentEventType == NSRightMouseDragged || currentEventType == NSOtherMouseDragged) {
		shouldSlideOffScreen = NO;
	}	
	
	return shouldSlideOffScreen;
}

// note: may be inaccurate when mouse is up against an edge 
- (NSScreen *)ScreenForPoint:(NSPoint)point
{
	NSScreen *pointScreen = nil;
	
	NSEnumerator *screenEnumerator = [[NSScreen screens] objectEnumerator];
	NSScreen *screen;
	while ((screen = [screenEnumerator nextObject]) != nil) {
		if (NSPointInRect(point, NSInsetRect([screen frame], -1, -1))) {
			pointScreen = screen;
			break;
		}		
	}
	
	return pointScreen;
}	

- (NSRect)SquareRectWithCenter:(NSPoint)point sideLength:(float)sideLength
{
	return NSMakeRect(point.x - sideLength*0.5f, point.y - sideLength*0.5f, sideLength, sideLength);
}

- (BOOL)PointIsInScreenCorner:(NSPoint)point
{
	BOOL inCorner = NO;
	NSScreen *menubarScreen = [[NSScreen screens] objectAtIndex:0];
	float menubarHeight = NSMaxY([menubarScreen frame]) - NSMaxY([menubarScreen visibleFrame]); // breaks if the dock is at the top of the screen (i.e. if the user is insane)
	
	NSRect screenFrame = [[self ScreenForPoint:point] frame];
	NSPoint lowerLeft  = screenFrame.origin;
	NSPoint upperRight = NSMakePoint(NSMaxX(screenFrame), NSMaxY(screenFrame));
	NSPoint lowerRight = NSMakePoint(upperRight.x, lowerLeft.y);
	NSPoint upperLeft  = NSMakePoint(lowerLeft.x, upperRight.y);
	
	float sideLength = menubarHeight * 2.0f;
	inCorner = (NSPointInRect(point, [self SquareRectWithCenter:lowerLeft sideLength:sideLength])
				|| NSPointInRect(point, [self SquareRectWithCenter:lowerRight sideLength:sideLength])
				|| NSPointInRect(point, [self SquareRectWithCenter:upperLeft sideLength:sideLength])
				|| NSPointInRect(point, [self SquareRectWithCenter:upperRight sideLength:sideLength]));
	
	return inCorner;
}

// YES if the mouse is against all edges of the screen where we previously slid the window and not in a corner.
// This means that this method will never return YES of the cl is slid into a corner. 
- (BOOL)shouldSlideWindowOnScreen_mousePositionStrategy
{
	BOOL mouseNearSlideOffEdges = (windowSlidOffScreenEdgeMask != 0);
	
	NSPoint mouseLocation = [NSEvent mouseLocation];
	
	NSRectEdge screenEdge;
	for (screenEdge = 0; screenEdge < 4; screenEdge++) {
		if (windowSlidOffScreenEdgeMask & (1 << screenEdge)) {
			float mouseOutsideSlideBoundaryRectDistance = AISignedExteriorDistanceRect_edge_toPoint_(screenSlideBoundaryRect, screenEdge, mouseLocation);
			if(mouseOutsideSlideBoundaryRectDistance < -MOUSE_EDGE_SLIDE_ON_DISTANCE) {
				mouseNearSlideOffEdges = NO;
			}
		}
	}
	
	return mouseNearSlideOffEdges && ![self PointIsInScreenCorner:mouseLocation];
}

// ----------------------------------
// ------------------- window sliding
// ----------------------------------

- (AIRectEdgeMask)slidableEdgesAdjacentToWindow
{
	AIRectEdgeMask slidableEdges = 0;

	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	
	NSRectEdge edge;
	for (edge = 0; edge < 4; edge++) {
		if (   (SLIDE_ALLOWED_RECT_EDGE_MASK & (1 << edge))
		   && (AIRectIsAligned_edge_toRect_edge_tolerance_(windowFrame, edge, screenSlideBoundaryRect, edge, WINDOW_ALIGNMENT_TOLERANCE))) 
		{
			slidableEdges |= (1 << edge);
		}
	}
	
	return slidableEdges;
}

- (void)slideWindowOffScreenEdges:(AIRectEdgeMask)rectEdgeMask
{
	NSWindow *window = [self window];
	NSRect newWindowFrame = [window frame];
	NSRectEdge edge;
	
	if (rectEdgeMask == 0)
		return;
	
	for (edge = 0; edge < 4; edge++) {
		if (rectEdgeMask & (1 << edge)) {
			newWindowFrame = AIRectByAligningRect_edge_toRect_edge_(newWindowFrame, AIOppositeRectEdge_(edge), screenSlideBoundaryRect, edge);
		}
	}

	[window setFrame:newWindowFrame display:NO animate:YES];
	[window orderOut:nil]; // otherwise we cast a shadow on the screen
	windowSlidOffScreenEdgeMask |= rectEdgeMask;
}

- (void)slideWindowOnScreen
{
	NSWindow	*window = [self window];
	NSRect		windowFrame = [window frame];
	NSRect		newWindowFrame = windowFrame;

	newWindowFrame = AIRectByMovingRect_intoRect_(newWindowFrame, screenSlideBoundaryRect);

	if (!NSEqualRects(windowFrame, newWindowFrame)) {
		if([NSApp isActive])
			[window orderFront:nil]; 
		else
			[window makeKeyAndOrderFront:nil];
		
		[window setFrame:newWindowFrame display:NO animate:YES];
		
		// be lenient; the window is now within the screenSlideBoundaryRect, but it isn't
		// necessarily on screen
		if ([window screen] == nil)
		{
			[window constrainFrameRect:newWindowFrame toScreen:[[NSScreen screens] objectAtIndex:0]];
		}
				
		// when the window is offscreen, there are no constraints on its size, for example it will grow downwards as much as
		// it needs to to accomodate new rows.  Now that it's onscreen, there are constraints.
		[contactListController contactListDesiredSizeChanged];
	}
	windowSlidOffScreenEdgeMask = 0;
}

- (void)setPreventHiding:(BOOL)newPreventHiding {
	preventHiding = newPreventHiding;
}
@end
