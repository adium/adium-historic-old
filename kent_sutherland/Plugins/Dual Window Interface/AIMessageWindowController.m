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

#import "AIDualWindowInterfacePlugin.h"
#import "AIInterfaceController.h"
#import "AIMenuController.h"
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIDockController.h"
#import "AIPreferenceController.h"
#import "AIToolbarController.h"
#import "AIAccountController.h"
#import "AIStatusIcons.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AICustomTabDragging.h>
#import <AIUtilities/AICustomTabsView.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AISplitView.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <PSMTabBarControl/PSMTabBarControl.h>
#import <PSMTabBarControl/PSMOverflowPopUpButton.h>
#import <PSMTabBarControl/PSMAdiumTabStyle.h>
#import <PSMTabBarControl/PSMTabStyle.h>

#define KEY_MESSAGE_WINDOW_POSITION 			@"Message Window"

#define AIMessageTabDragBeganNotification		@"AIMessageTabDragBeganNotification"
#define AIMessageTabDragEndedNotification    	@"AIMessageTabDragEndedNotification"
#define	MESSAGE_WINDOW_NIB                      @"MessageWindow"			//Filename of the message window nib
#define TAB_BAR_FPS                             20.0
#define TAB_BAR_STEP                            0.6
#define TOOLBAR_MESSAGE_WINDOW					@"AdiumMessageWindow"			//Toolbar identifier

@interface AIMessageWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName interface:(AIDualWindowInterfacePlugin *)inInterface containerID:(NSString *)inContainerID containerName:(NSString *)inName;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
- (void)_updateWindowTitleAndIcon;
- (NSString *)_frameSaveKey;
- (void)_reloadContainedChats;
@end

//Used to squelch compiler warnings on this private call
@interface NSWindow (AISecretWindowDocumentIconAdditions)
- (void)addDocumentIconButton;
@end

@implementation AIMessageWindowController

//Create a new message window controller
+ (AIMessageWindowController *)messageWindowControllerForInterface:(AIDualWindowInterfacePlugin *)inInterface
															withID:(NSString *)inContainerID
															  name:(NSString *)inName
{
    return [[[self alloc] initWithWindowNibName:MESSAGE_WINDOW_NIB
									  interface:inInterface
									containerID:inContainerID
										   containerName:inName] autorelease];
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName
				  interface:(AIDualWindowInterfacePlugin *)inInterface
				containerID:(NSString *)inContainerID
					   containerName:(NSString *)inName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		NSWindow	*myWindow;
	
		interface = [inInterface retain];
		containerName = [inName retain];
		containerID = [inContainerID retain];
		containedChats = [[NSMutableArray alloc] init];
		hasShownDocumentButton = NO;
		
		//Load our window
		myWindow = [self window];

		//Disable the optimization for opaque windows since ours might not be
		[myWindow setOpaque:NO];

		//Tab hiding suppression (used to force tab bars visible when a drag is occuring)
		tabBarIsVisible = YES;
		supressHiding = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(tabDraggingNotificationReceived:)
													 name:PSMTabDragDidBeginNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(tabDraggingNotificationReceived:)
													 name:PSMTabDragDidEndNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(tabBarFrameChanged:)
													 name:NSViewFrameDidChangeNotification
												   object:tabView_tabBar];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(windowWillMiniaturize:)
													 name:NSWindowWillMiniaturizeNotification
												   object:myWindow];
		//Prefs
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		
		//Register as a tab drag observer so we know when tabs are dragged over our window and can show our tab bar
		[myWindow registerForDraggedTypes:[NSArray arrayWithObject:@"PSMTabBarControlItemPBType"]];
	}

    return self;
}

//dealloc
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[adium notificationCenter] removeObserver:self];

	/* Ensure our window is quite clear we have no desire to ever hear from it again.  sendEvent: with a flags changed
	 * event is being sent to this AIMessageWindowController instance by the window after dallocing, for some reason.
	 * It seems likely a double-release is involved.  I can't reproduce this locally, either... but calling
	 * [self setWindow:nil] appears to fix the problem where it was being experienced..
	 *
	 * Something is wrong elsewhere that this could be necessary, but this doesn't hurt I don't believe.
	 */
	[self setWindow:nil];
	
	[containedChats release];
	[toolbarItems release];
	[containerName release];
	[containerID release];

	[[adium preferenceController] unregisterPreferenceObserver:self];

    [super dealloc];
}

//Human readable container name
- (NSString *)name
{
	return containerName;
}

//Internal container ID
- (NSString *)containerID
{
	return containerID;
}

//PSMTabBarControl accessor
- (PSMTabBarControl *)tabBar
{
	return tabView_tabBar;
}

//
- (NSString *)adiumFrameAutosaveName
{
	return [self _frameSaveKey];
}

//Setup our window before it is displayed
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	NSWindow	*theWindow = [self window];

    //Exclude this window from the window menu (since we add it manually)
    [theWindow setExcludedFromWindowsMenu:YES];
	[theWindow useOptimizedDrawing:YES];
	
	[self _configureToolbar];

    //Remove any tabs from our tab view, it needs to start out empty
    while ([tabView_messages numberOfTabViewItems] > 0) {
        [tabView_messages removeTabViewItem:[tabView_messages tabViewItemAtIndex:0]];
    }
	
	//Setup the tab bar
	tabView_tabStyle = [[[PSMAdiumTabStyle alloc] init] autorelease];
	[tabView_tabBar setStyle:tabView_tabStyle];
	[tabView_tabBar setCanCloseOnlyTab:YES];
	[tabView_tabBar setUseOverflowMenu:NO];
	[tabView_tabBar setAllowsResizing:NO];
	[tabView_tabBar setSizeCellsToFit:YES];
	[tabView_tabBar setHideForSingleTab:!alwaysShowTabs];
	[tabView_tabBar setSelectsTabsOnMouseDown:YES];
}

//Frames
- (NSString *)_frameSaveKey
{
	return [NSString stringWithFormat:@"%@ %@",KEY_MESSAGE_WINDOW_POSITION, containerID];
}
- (BOOL)shouldCascadeWindows
{
	//Cascade if we have no frame
	return ([[adium preferenceController] preferenceForKey:[self _frameSaveKey] group:PREF_GROUP_WINDOW_POSITIONS] == nil);
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

//Close the message window
- (IBAction)closeWindow:(id)sender
{
	windowIsClosing = YES;

	//Hide our window now, making sure we set active chat to nil before ordering out.  When we order out, another window
	//may become key and set itself active.  Setting active to nil after that happened would cause problems.
	//We want to set the active chat to nil only if the window being closed is the active window
	if ([[self window] isKeyWindow]) {
		[[adium interfaceController] chatDidBecomeActive:nil];
	}
	[[self window] orderOut:nil];

	//Now we close our window for real.  By hiding first, we get a smoother close as the user won't see each tab closing
	//individually.  The close will also be quicker, since it avoids a lot of redrawing.
	[[self window] performClose:nil];
}

/*!
 * @brief Called as the window closes
 */
- (void)windowWillClose:(id)sender
{
    NSEnumerator			*enumerator;
    AIMessageTabViewItem	*tabViewItem;
	
	windowIsClosing = YES;
	[super windowWillClose:sender];

	[[adium preferenceController] unregisterPreferenceObserver:self];

    //Close all our tabs (The array will change as we remove tabs, so we must work with a copy)
	enumerator = [[tabView_messages tabViewItems] reverseObjectEnumerator];
    while ((tabViewItem = [enumerator nextObject])) {
		[interface closeChat:[tabViewItem chat]];
	}

	//Chats have all closed, set active to nil, let the interface know we closed.  We should skip this step if our
	//window is no longer visible, since in that case another window will have already became active.
	if ([[self window] isVisible] && [[self window] isKeyWindow]) {
		[[adium interfaceController] chatDidBecomeActive:nil];
	}
	[interface containerDidClose:self];

    return;
}

//
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
    if ([group isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE]) {
		NSWindow	*window = [self window];
		alwaysShowTabs = ![[prefDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue];
		[tabView_tabBar setHideForSingleTab:!alwaysShowTabs];
		[tabView_tabBar setAllowsBackgroundTabClosing:[[prefDict objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE] boolValue]];
		[tabView_tabBar setUseOverflowMenu:[[prefDict objectForKey:KEY_TABBAR_USE_OVERFLOW] boolValue]];
		//[[tabView_tabBar overflowPopUpButton] setAlternateImage:[AIStatusIcons statusIconForStatusName:@"content" statusType:AIAvailableStatusType iconType:AIStatusIconTab direction:AIIconNormal]];
		NSImage *overflowImage = [[[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:@"overflow_overlay"]] autorelease];
		[[tabView_tabBar overflowPopUpButton] setAlternateImage:overflowImage];
		
		//change the frame of the tab bar according to the orientation
		if (firstTime || [key isEqualToString:KEY_TABBAR_POSITION]) {
			tabPosition = [[prefDict objectForKey:KEY_TABBAR_POSITION] intValue];
			PSMTabBarOrientation orientation = (tabPosition == AdiumTabPositionBottom || tabPosition == AdiumTabPositionTop) ? PSMTabBarHorizontalOrientation : PSMTabBarVerticalOrientation;
			NSRect tabBarFrame = [tabView_tabBar frame], tabViewFrame = [tabView_messages frame];
			NSRect contentRect = [[[self window] contentView] frame];
			
			//remove the split view if the last orientation was vertical
			if ([tabView_tabBar orientation] == PSMTabBarVerticalOrientation) {
				[tabView_messages retain];
				[tabView_messages removeFromSuperview];
				[tabView_tabBar retain];
				[tabView_tabBar removeFromSuperview];
				[tabView_splitView removeFromSuperview];
				
				[[[self window] contentView] addSubview:tabView_messages];
				[[[self window] contentView] addSubview:tabView_tabBar];
				[tabView_messages release];
				[tabView_tabBar release];
			}
			
			[tabView_tabBar setOrientation:orientation];
			
			if (orientation == PSMTabBarHorizontalOrientation) {
				tabBarFrame.size.height = [tabView_tabBar isTabBarHidden] ? 1 : 22;
				tabBarFrame.size.width = contentRect.size.width + 1;
				
				//set the position of the tab bar (top/bottom)
				if (tabPosition == AdiumTabPositionBottom) {
					tabBarFrame.origin.y = contentRect.origin.y;
					tabViewFrame.origin.y = tabBarFrame.size.height + 6;
					tabViewFrame.size.height = contentRect.size.height - tabBarFrame.size.height - 5;
					[tabView_tabBar setAutoresizingMask:NSViewMaxYMargin | NSViewWidthSizable];
				} else {
					tabBarFrame.origin.y = contentRect.origin.y + contentRect.size.height - tabBarFrame.size.height + 1;
					tabViewFrame.origin.y = contentRect.origin.y;
					tabViewFrame.size.height = contentRect.size.height - tabBarFrame.size.height + 1;
					[tabView_tabBar setAutoresizingMask:NSViewMinYMargin | NSViewWidthSizable];
				}
				
				tabViewFrame.origin.x = -1;
				tabBarFrame.origin.x = 0;
				tabViewFrame.size.width = contentRect.size.width + 1;
			} else {
				float width = [[prefDict objectForKey:KEY_TABBAR_WIDTH] floatValue];
				if (width < 50) {
					width = 50;
				}
				
				tabBarFrame.size.height = [[[self window] contentView] frame].size.height;
				tabBarFrame.size.width = [tabView_tabBar isTabBarHidden] ? 1 : width;
				tabBarFrame.origin.y = contentRect.origin.y;
				tabViewFrame.origin.y = contentRect.origin.y;
				tabViewFrame.size.height = contentRect.size.height + 1;
				tabViewFrame.size.width = contentRect.size.width - tabBarFrame.size.width - 5;
				
				//set the position of the tab bar (left/right)
				if (tabPosition == AdiumTabPositionLeft) {
					tabBarFrame.origin.x = contentRect.origin.x;
					tabViewFrame.origin.x = tabBarFrame.origin.x + tabBarFrame.size.width;
					[tabView_tabBar setAutoresizingMask:NSViewHeightSizable];
				} else {
					tabViewFrame.origin.x = contentRect.origin.x;
					tabBarFrame.origin.x = contentRect.size.width - tabBarFrame.size.width + 1;
					[tabView_tabBar setAutoresizingMask:NSViewHeightSizable | NSViewMinXMargin];
				}
				[tabView_tabBar setCellMinWidth:50];
				[tabView_tabBar setCellMaxWidth:200];
				
				//put the subviews into a split view
				NSRect splitViewRect = [[[self window] contentView] frame];
				splitViewRect.size.width++;
				splitViewRect.size.height++;
				tabView_splitView = [[[AISplitView alloc] initWithFrame:splitViewRect] autorelease];
				[tabView_splitView setDividerThickness:6];
				[tabView_splitView setDrawsDivider:NO];
				[tabView_splitView setVertical:YES];
				[tabView_splitView setDelegate:self];
				if (tabPosition == AdiumTabPositionLeft) {
					[tabView_splitView addSubview:tabView_tabBar];
					[tabView_splitView addSubview:tabView_messages];
				} else {
					[tabView_splitView addSubview:tabView_messages];
					[tabView_splitView addSubview:tabView_tabBar];
				}
				[tabView_splitView adjustSubviews];
				[tabView_splitView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
				[[[self window] contentView] addSubview:tabView_splitView];
			}
			
			[tabView_messages setFrame:tabViewFrame];
			[tabView_tabBar setFrame:tabBarFrame];
			
			//update the tab bar and tab view frame
			[[self window] display];
		}
		
		//set tab style drawing attributes
		[tabView_tabStyle setDrawsRight:(tabPosition == AdiumTabPositionRight)];
		[tabView_tabStyle setDrawsUnified:(tabPosition == AdiumTabPositionTop)];
		//[[[self window] toolbar] setShowsBaselineSeparator:(tabPosition != AdiumTabPositionTop)];
		
		[self _updateWindowTitleAndIcon];

		AIWindowLevel	windowLevel = [[prefDict objectForKey:KEY_WINDOW_LEVEL] intValue];
		int				level = NSNormalWindowLevel;
		
		switch (windowLevel) {
			case AINormalWindowLevel: level = NSNormalWindowLevel; break;
			case AIFloatingWindowLevel: level = NSFloatingWindowLevel; break;
			case AIDesktopWindowLevel: level = kCGDesktopWindowLevel; break;
		}
		[window setLevel:level];
		[window setIgnoresExpose:(windowLevel == AIDesktopWindowLevel)]; //Ignore expose while on the desktop
		[window setHidesOnDeactivate:[[prefDict objectForKey:KEY_WINDOW_HIDE] boolValue]];
    }
}

- (void)updateIconForTabViewItem:(AIMessageTabViewItem *)tabViewItem
{
	if (tabViewItem == [tabView_messages selectedTabViewItem]) {
		[self _updateWindowTitleAndIcon];
	}
	
	if ([[tabView_tabBar representedTabViewItems] indexOfObject:tabViewItem] >= [tabView_tabBar numberOfVisibleTabs]) {
		[[tabView_tabBar overflowPopUpButton] setAnimatingAlternateImage:([[tabViewItem chat] unviewedContentCount] > 0)];
	}
}

//Send the print message to our view
- (void)adiumPrint:(id)sender
{
	id	controller = [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] messageViewController];
	
	if ([controller respondsToSelector:@selector(adiumPrint:)]) {
		[controller adiumPrint:sender];
	}
}

//Contained Chats ------------------------------------------------------------------------------------------------------
#pragma mark Contained Chats
//Add a tab view item container at the end of the tabs (without changing the current selection)
- (void)addTabViewItem:(AIMessageTabViewItem *)inTabViewItem
{
    [self addTabViewItem:inTabViewItem atIndex:-1 silent:NO];
}

//Add a tab view item container (without changing the current selection)
//If silent is NO, the interface controller will be informed of the add
- (void)addTabViewItem:(AIMessageTabViewItem *)inTabViewItem atIndex:(int)index silent:(BOOL)silent
{
	if (index == -1) {
		[tabView_messages addTabViewItem:inTabViewItem];
		//[containedChats addObject:[inTabViewItem chat]];
	} else {
		[tabView_messages insertTabViewItem:inTabViewItem atIndex:index];
		//[containedChats insertObject:[inTabViewItem chat] atIndex:index];
	}
	
	//[inTabViewItem scd etContainer:self];
	
	if (!silent) [[adium interfaceController] chatDidOpen:[inTabViewItem chat]];
}

//Remove a tab view item container
//If silent is NO, the interface controller will be informed of the remove
- (void)removeTabViewItem:(AIMessageTabViewItem *)inTabViewItem silent:(BOOL)silent
{
	/* When a tab isn't selected, its views are not within any window. We want the tab to be able to remove tracking rects
	 * from the window before closing, so if it isn't selected we need to select it briefly to let this happen. Since this is
	 * all within the same run loop, as long as code in the tab view's delegate is well-behaved and uses setNeedsDisplay: rather
	 * than display if it does drawing, the UI shouldn't change at all.
	 */
	if ([tabView_messages selectedTabViewItem] != inTabViewItem) {
		NSTabViewItem	*oldTabViewItem = [tabView_messages selectedTabViewItem];
		[tabView_messages selectTabViewItem:inTabViewItem];
		
		//The tab view item needs to know that this window controller no longer contains it
		[inTabViewItem setContainer:nil];	

		[tabView_messages selectTabViewItem:oldTabViewItem];
	} else {
		//The tab view item needs to know that this window controller no longer contains it
		[inTabViewItem setContainer:nil];
	}
	

    //If the tab is selected, select the next tab before closing it (To mirror the behavior of safari)
    if (!windowIsClosing && inTabViewItem == [tabView_messages selectedTabViewItem]) {
		[tabView_messages selectNextTabViewItem:nil];
    }
	
    //Remove the tab and let the interface know a container closed
	[containedChats removeObject:[inTabViewItem chat]];
	if (!silent) [[adium interfaceController] chatDidClose:[inTabViewItem chat]];

	//Now remove the tab view item from our NSTabView
    [tabView_messages removeTabViewItem:inTabViewItem];

	//close if we're empty
	if (!windowIsClosing && [containedChats count] == 0) {
		[self closeWindow:nil];
	}
}

//
- (void)moveTabViewItem:(AIMessageTabViewItem *)inTabViewItem toIndex:(int)index
{
	AIChat	*chat = [inTabViewItem chat];

	if ([containedChats indexOfObject:chat] != index) {
		NSMutableArray *cells = [tabView_tabBar cells];
		
		[cells moveObject:[cells objectAtIndex:[[tabView_tabBar representedTabViewItems] indexOfObject:inTabViewItem]] toIndex:index];
		[tabView_tabBar setNeedsDisplay:YES];
		[containedChats moveObject:chat toIndex:index];
		
		[[adium interfaceController] chatOrderDidChange];
	}
}

//Returns YES if we are empty (currently contain no chats)
- (BOOL)containerIsEmpty
{
	return ([containedChats count] == 0);
}

//Returns an array of the chats we contain
- (NSArray *)containedChats
{
    return containedChats;
}

- (void)_reloadContainedChats
{
	NSEnumerator			*enumerator;
	AIMessageTabViewItem	*tabViewItem;
	
	//Update our contained chats array to mirror the order of the tabs
	[containedChats release]; containedChats = [[NSMutableArray alloc] init];
	enumerator = [[tabView_tabBar cells] objectEnumerator];
	while ((tabViewItem = [[enumerator nextObject] representedObject])) {
		[tabViewItem setContainer:self];
		[containedChats addObject:[tabViewItem chat]];
	}
}

//Active Chat Tracking -------------------------------------------------------------------------------------------------
#pragma mark Active Chat Tracking
//Our selected tab is now the active chat
- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[[adium interfaceController] chatDidBecomeActive:[(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] chat]];
}

//Our selected tab is no longer the active chat
- (void)windowDidResignKey:(NSNotification *)notification
{
	[[adium interfaceController] chatDidBecomeActive:nil];
}

//Update our window title
- (void)_updateWindowTitleAndIcon
{
	NSString	*label = [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] label];
	NSString	*title;
	NSButton	*button;
	NSWindow	*window = [self window];
	
	//Window Title
    if ([tabView_messages numberOfTabViewItems] == 1) {
        title = [NSString stringWithFormat:@"%@", label];
    } else {
		title = [NSString stringWithFormat:@"%@ - %@", containerName, label];
    }
	[window setTitle:title];
	
	//Window Icon (We display state in the window title if tabs are not visible)
	if (!hasShownDocumentButton) {
		if ([window respondsToSelector:@selector(addDocumentIconButton)]) {
			[window addDocumentIconButton];
		}
		hasShownDocumentButton = YES;
	}
	
	button = [window standardWindowButton:NSWindowDocumentIconButton];
	if (!tabBarIsVisible) {
		NSImage *image = [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] stateIcon];
		if (image != [button image]) {
			[button setImage:image];
		}

	} else {
		if ([button image]) {
			[button setImage:nil];
		}
	}
}

- (AIChat *)activeChat
{
	return [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] chat];
}

//AISplitView Delegate -------------------------------------------------------------------------------------------------
#pragma mark AISplitView Delegate

//handles the minimum size of vertical tabs
- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	return tabPosition == 2 ? 50 : [sender frame].size.width - 250 - [sender dividerThickness];
}

//handles the maximum size of vertical tabs
- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	return tabPosition == 2 ? 250 : proposedMax - 50;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect messageFrame = [tabView_messages frame], tabBarFrame = [tabView_tabBar frame];
	messageFrame.size = NSMakeSize([sender frame].size.width - tabBarFrame.size.width - 6, [sender frame].size.height);
	tabBarFrame.size = NSMakeSize(tabBarFrame.size.width, [sender frame].size.height);
	
	if (tabPosition == AdiumTabPositionLeft) {
		messageFrame.origin.x = tabBarFrame.size.width + 6;
	} else {
		messageFrame.origin.x = 0;
		tabBarFrame.origin.x = messageFrame.size.width + 6;
	}
	
	[tabView_messages setFrame:messageFrame];
	[tabView_tabBar setFrame:tabBarFrame];
}

//PSMTabBarControl Delegate -------------------------------------------------------------------------------------------------
#pragma mark PSMTabBarControl Delegate

//Handle closing a tab
- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
	//The window controller handles removing the tab as we need to dispose of tracking rects properly
	[self removeTabViewItem:(AIMessageTabViewItem *)tabViewItem silent:NO];
	if ([tabViewItem respondsToSelector:@selector(chat)]) {
		[interface closeChat:[(AIMessageTabViewItem *)tabViewItem chat]];
	}
	return NO;
}

//Our selected tab has changed, update the active chat
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (tabViewItem != nil) {
		AIChat	*chat = [(AIMessageTabViewItem *)tabViewItem chat];
        [(AIMessageTabViewItem *)tabViewItem tabViewItemWasSelected]; //Let the tab know it was selected
		
        if ([[self window] isMainWindow]) { //If our window is main, set the newly selected container as active
			[[adium interfaceController] chatDidBecomeActive:chat];
        }
		
        [self _updateWindowTitleAndIcon]; //Reflect change in window title
		[[adium interfaceController] chatDidBecomeVisible:chat inWindow:[self window]];
    }
}

- (BOOL)tabView:(NSTabView*)tabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl
{
	return YES;
}

- (BOOL)tabView:(NSTabView*)tabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl
{
	return YES;
}

- (void)tabView:(NSTabView *)tabView closeWindowForLastTabViewItem:(NSTabViewItem *)tabViewItem
{
	[self closeWindow:self];
}

//Contextual menu for tabs
- (NSMenu *)tabView:(NSTabView *)tabView menuForTabViewItem:(NSTabViewItem *)tabViewItem
{
	AIChat			*chat = [(AIMessageTabViewItem *)tabViewItem chat];
    AIListContact	*selectedObject = [chat listObject];
    NSMenu			*tmp = nil;

    if (selectedObject) {
		NSMutableArray *locations;
		if ([selectedObject isStranger]) {
			locations = [NSMutableArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_ChatAction],
				[NSNumber numberWithInt:Context_Contact_Stranger_ChatAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		} else {
			locations = [NSMutableArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_ChatAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		}
		
		[locations addObject:[NSNumber numberWithInt:Context_Tab_Action]];

		tmp = [[adium menuController] contextualMenuWithLocations:locations
													 forListObject:selectedObject
														   inChat:chat];
        
    }
	
	return tmp;
}

//Tab count changed
- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView
{
    [self _updateWindowTitleAndIcon];
	[self _reloadContainedChats];
	[[adium interfaceController] chatOrderDidChange];
}

//Tabs reordered, rebuild the containedChats collection
- (void)tabView:(NSTabView*)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl;
{
	[self _reloadContainedChats];
	[[adium interfaceController] chatOrderDidChange];
}

//Allow dragging of text
- (NSArray *)allowedDraggedTypesForTabView:(NSTabView *)aTabView
{
	//return [NSArray arrayWithObject:NSRTFPboardType];
	return [NSArray arrayWithObjects:NSRTFPboardType, NSStringPboardType, NSFilenamesPboardType, NSTIFFPboardType, NSPDFPboardType, NSPICTPboardType, nil];
}

//Accept dragged text
- (void)tabView:(NSTabView *)aTabView acceptedDraggingInfo:(id <NSDraggingInfo>)draggingInfo onTabViewItem:(NSTabViewItem *)tabViewItem
{
	/*NSPasteboard *pasteboard = [draggingInfo draggingPasteboard];
	
    if ([[pasteboard availableTypeFromArray:[NSArray arrayWithObject:NSRTFPboardType]] isEqualToString:NSRTFPboardType]) { //got RTF data
        [[(AIMessageTabViewItem *)tabViewItem messageViewController] addToTextEntryView:[NSAttributedString stringWithData:[pasteboard dataForType:NSRTFPboardType]]];
    }*/
	[[(AIMessageTabViewItem *)tabViewItem messageViewController] addDraggedDataToTextEntryView:draggingInfo];
}

//Get an image representation of the chat
- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(unsigned int *)styleMask
{
	// grabs whole window image
	NSImage *viewImage = [[[NSImage alloc] init] autorelease];
	NSRect contentFrame = [[[self window] contentView] frame];
	[[[self window] contentView] lockFocus];
	NSBitmapImageRep *viewRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:contentFrame] autorelease];
	[viewImage addRepresentation:viewRep];
	[[[self window] contentView] unlockFocus];
	
    // grabs snapshot of dragged tabViewItem's view (represents content being dragged)
	NSView *viewForImage = [tabViewItem view];
	NSRect viewRect = [viewForImage frame];
	NSImage *tabViewImage = [[[NSImage alloc] initWithSize:viewRect.size] autorelease];
	[tabViewImage lockFocus];
	[viewForImage drawRect:[viewForImage bounds]];
	[tabViewImage unlockFocus];
	
	[viewImage lockFocus];
	NSPoint tabOrigin = [tabView frame].origin;
	tabOrigin.x += 10;
	tabOrigin.y += 13;
	[tabViewImage compositeToPoint:tabOrigin operation:NSCompositeSourceOver];
	[viewImage unlockFocus];
	
	//draw over where the tab bar would usually be
	NSRect tabFrame = [tabView_tabBar frame];
	[viewImage lockFocus];
	[[NSColor windowBackgroundColor] set];
	NSRectFill(tabFrame);
	//draw the background flipped, which is actually the right way up
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:1.0 yBy:-1.0];
	[transform concat];
	tabFrame.origin.y = -tabFrame.origin.y - tabFrame.size.height;
	[(id <PSMTabStyle>)[[tabView delegate] style] drawBackgroundInRect:tabFrame];
	[transform invert];
	[transform concat];
	
	[viewImage unlockFocus];
	
	id <PSMTabStyle> style = (id <PSMTabStyle>)[[tabView delegate] style];
	if (tabPosition == AdiumTabPositionBottom) {
		offset->width = [style leftMarginForTabBarControl];
		offset->height = contentFrame.size.height;
	} else if (tabPosition == AdiumTabPositionTop) {
		offset->width = [style leftMarginForTabBarControl];
		offset->height = 21;
	} else if (tabPosition == AdiumTabPositionLeft) {
		offset->width = 0;
		offset->height = 21 + [style topMarginForTabBarControl];
	} else {
		offset->width = [tabView_tabBar frame].origin.x;
		offset->height = 21 + [style topMarginForTabBarControl];
	}
	
	*styleMask = NSTitledWindowMask;
	
	return viewImage;
}

//Create a new tab window
- (PSMTabBarControl *)tabView:(NSTabView *)tabView newTabBarForDraggedTabViewItem:(NSTabViewItem *)tabViewItem atPoint:(NSPoint)point
{
	id newController = [interface openNewContainer];
	NSRect frame;
	id <PSMTabStyle> style = (id <PSMTabStyle>)[[tabView delegate] style];
	
	//set the size of the new window
	//set the size and origin separately so that toolbar visibility and size doesn't mess things up
	frame.size = [[self window] frame].size;
	[[newController window] setFrame:frame display:NO];
	
	if (tabPosition == AdiumTabPositionBottom) {
		point.x -= [style leftMarginForTabBarControl];
		point.y -= 22;
	} else if (tabPosition == AdiumTabPositionTop) {
		point.x -= [style leftMarginForTabBarControl];
		point.y -= [[[newController window] contentView] frame].size.height + 1;
	} else if (tabPosition == AdiumTabPositionLeft) {
		point.y -= [[[newController window] contentView] frame].size.height - [style topMarginForTabBarControl] + 1;
	} else {
		point.x -= [tabView_tabBar frame].origin.x;
		point.y -= [[[newController window] contentView] frame].size.height - [style topMarginForTabBarControl] + 1;
	}
	
	//set the origin point of the new window
	frame.origin = point;
	[[newController window] setFrame:frame display:NO];
	
	return [newController tabBar];
}

- (void)tabView:(NSTabView *)tabView tabBarDidHide:(PSMTabBarControl *)tabBarControl
{
    //hide the space between the tab bar and the tab view
    NSRect frame = [tabView frame];
    if ([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
        frame.origin.y -= 7;
        frame.size.height += 7;
    } else {
        frame.origin.x -= 3;
        frame.size.width += 3;
	}
	
	[tabView setFrame:frame];
	[tabView setNeedsDisplay:YES];
}

- (void)tabView:(NSTabView *)tabView tabBarDidUnhide:(PSMTabBarControl *)tabBarControl
{
    //show the space between the tab bar and the tab view
    NSRect frame = [tabView frame];
    if ([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
        frame.origin.y += 7;
        frame.size.height -= 7;
    } else {
        frame.origin.x += 3;
        frame.size.width -= 3;
    }
    
    [tabView setFrame:frame];
    [tabView setNeedsDisplay:YES];
}

- (NSString *)tabView:(NSTabView *)tabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem
{
	AIChat		*chat = [(AIMessageTabViewItem *)tabViewItem chat];
	NSString	*tooltip = nil;

	if ([chat isGroupChat]) {
		tooltip = [NSString stringWithFormat:AILocalizedString(@"%@ in %@","AccountName on ChatRoomName"), [[chat account] formattedUID], [chat name]];
	} else {
		AIListObject	*destination = [chat listObject];
		NSString		*destinationFormattedUID = [destination formattedUID];
		BOOL			includeDestination = NO;
		BOOL			includeSource = NO;

		if (![[[destination displayName] compactedString] isEqualToString:[destinationFormattedUID compactedString]]) {
			includeDestination = YES;
		}
		
		AIAccount	*account;
		NSEnumerator *enumerator = [[[adium accountController] accounts] objectEnumerator];
		int onlineAccounts = 0;
		while ((account = [enumerator nextObject]) && onlineAccounts < 2) {
			if ([account online]) onlineAccounts++;
		}

		if (onlineAccounts >=2) {
			includeSource = YES;
		}
		AILog(@"Displaying tooltip for %@ --> %@ (%@) --> %@ (%@)",chat,[chat account], [[chat account] formattedUID], destination,destinationFormattedUID);
		if (includeDestination && includeSource) {
			tooltip = [NSString stringWithFormat:AILocalizedString(@"%@ talking to %@","AccountName talking to Username"), [[chat account] formattedUID], destinationFormattedUID];

		} else if (includeDestination) {
			tooltip = destinationFormattedUID;
			
		} else if (includeSource) {
			tooltip = [[chat account] formattedUID];
		}
	}
	
	return tooltip;
}

//Tab Bar Visibility --------------------------------------------------------------------------------------------------
#pragma mark Tab Bar Visibility/Drag And Drop

//Replaced by PSMTabBarControl

//Make sure auto-hide suppression is off after a drag completes
- (void)tabDraggingNotificationReceived:(NSNotification *)notification
{
	if ([[notification name] isEqualToString:PSMTabDragDidBeginNotification]) {
		[tabView_tabBar setHideForSingleTab:NO];
	} else {
		[tabView_tabBar setHideForSingleTab:!alwaysShowTabs];
	}
}

//Save width of the vertical tabs when changed
- (void)tabBarFrameChanged:(NSNotification *)notification {
	if ([tabView_tabBar orientation] == PSMTabBarVerticalOrientation) {
		[[adium preferenceController] setPreference:[NSNumber numberWithFloat:[tabView_tabBar frame].size.width]
											 forKey:KEY_TABBAR_WIDTH
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	}
}

//Bring our window to the front
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSDragOperation tmp = NSDragOperationNone;
    NSString 		*type = [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"PSMTabBarControlItemPBType"]];
	
    if (sender == nil || type) {
        if (![[self window] isKeyWindow]) {
			[[self window] makeKeyAndOrderFront:nil];
		}
		
        tmp = NSDragOperationPrivate;
    }
	return tmp;
}

//Toolbar --------------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Install our toolbar
- (void)_configureToolbar
{
	NSToolbar *toolbar;
    toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_MESSAGE_WINDOW] autorelease];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
	//[toolbar setShowsBaselineSeparator:NO];
	
    //
	toolbarItems = [[[adium toolbarController] toolbarItemsForToolbarTypes:[NSArray arrayWithObjects:@"General", @"ListObject", @"TextEntry", @"MessageWindow", nil]] retain];

	[[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"UserIcon",@"Encryption",  NSToolbarSeparatorItemIdentifier, 
		@"SourceDestination", @"InsertEmoticon", @"BlockParticipants", @"LinkEditor", @"SafariLink", NSToolbarShowColorsItemIdentifier,
		NSToolbarShowFontsItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, @"SendFile",
		@"ShowInfo", @"LogViewer", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarShowColorsItemIdentifier,
			NSToolbarShowFontsItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]];
}

#pragma mark Miniaturization
/*
 * @brief Our window is about to minimize
 *
 * Set our miniwindow image, which will display in the dock, appropriately.
 */
- (void)windowWillMiniaturize:(NSNotification *)notification
{
	NSImage *miniwindowImage;
	NSImage	*chatImage = [[(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] chat] chatImage];
	NSImage	*appImage = [[adium dockController] baseApplicationIconImage];
	NSSize	chatImageSize = [chatImage size];
	NSSize	appImageSize = [appImage size];
	NSSize	newChatImageSize;
	NSSize	badgeSize;
	
	miniwindowImage = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];
	
	//Determine the properly scaled chat image size
	newChatImageSize = NSMakeSize(96,96);
	if (chatImageSize.width != chatImageSize.height) {
		if (chatImageSize.width > chatImageSize.height) {
			//Give width priority: Make the height change by the same proportion as the width will change
			newChatImageSize.height = chatImageSize.height * (newChatImageSize.width / chatImageSize.width);
		} else {
			//Give height priority: Make the width change by the same proportion as the height will change
			newChatImageSize.width = chatImageSize.width * (newChatImageSize.height / chatImageSize.height);
		}		
	}
	
	//OS X 10.4 always returns a square application icon of 128x128, but better safe than sorry
	badgeSize = NSMakeSize(48, 48);
	if (appImageSize.width != appImageSize.height) {
		if (appImageSize.width > appImageSize.height) {
			//Give width priority: Make the height change by the same proportion as the width will change
			badgeSize.height = appImageSize.height * (badgeSize.width / appImageSize.width);
		} else {
			//Give height priority: Make the width change by the same proportion as the height will change
			badgeSize.width = appImageSize.width * (badgeSize.height / appImageSize.height);
		}		
	}
	
	[miniwindowImage lockFocus];
	{
		//Draw the chat image with space around it (the dock will do ugly scaling if we don't make a transparent border)
		[chatImage drawInRect:NSMakeRect((128 - newChatImageSize.width)/2, (128 - newChatImageSize.height)/2,
										 newChatImageSize.width, newChatImageSize.height)
					 fromRect:NSMakeRect(0, 0, chatImageSize.width, chatImageSize.height)
					operation:NSCompositeSourceOver
					 fraction:1.0];
		
		//Draw the Adium icon as a badge in the bottom right
		[appImage drawInRect:NSMakeRect(128 - badgeSize.width,
										0,
										badgeSize.width,
										badgeSize.height)
					fromRect:NSMakeRect(0, 0, appImageSize.width, appImageSize.height)
				   operation:NSCompositeSourceOver
					fraction:1.0];
	}
	[miniwindowImage unlockFocus];
	
	//Set the image
	[[self window] setMiniwindowImage:miniwindowImage];
	
	//Cleanup
	[miniwindowImage release];
}

@end
