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
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIDockController.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <PSMTabBarControl/PSMTabBarControl.h>
#import <PSMTabBarControl/PSMOverflowPopUpButton.h>
#import <PSMTabBarControl/PSMAdiumTabStyle.h>
#import <PSMTabBarControl/PSMTabStyle.h>
#import "AIMessageTabSplitView.h"

#define KEY_MESSAGE_WINDOW_POSITION 			@"Message Window"

#define AIMessageTabDragBeganNotification		@"AIMessageTabDragBeganNotification"
#define AIMessageTabDragEndedNotification    	@"AIMessageTabDragEndedNotification"
#define	MESSAGE_WINDOW_NIB                      @"MessageWindow"			//Filename of the message window nib
#define TAB_BAR_FPS                             20.0
#define TAB_BAR_STEP                            0.6
#define TOOLBAR_MESSAGE_WINDOW					@"AdiumMessageWindow"			//Toolbar identifier

#define HORIZONTAL_TAB_BAR_TO_VIEW_SPACING		7

#define KEY_VERTICAL_TABS_WIDTH					@"Vertical Tabs Width"
#define VERTICAL_DIVIDER_THICKNESS				4
#define VERTICAL_TAB_BAR_TO_VIEW_SPACING		3

@interface AIMessageWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName interface:(AIDualWindowInterfacePlugin *)inInterface containerID:(NSString *)inContainerID containerName:(NSString *)inName;
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
	[[self window] setDelegate:nil];
	[self setWindow:nil];

    [tabView_tabBar setDelegate:nil];

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
	[tabView_tabBar setAutomaticallyAnimates:NO];
	[tabView_tabBar setAllowsScrubbing:YES];
	[tabView_tabBar setAllowsBackgroundTabClosing:NO];
	[tabView_tabBar setTearOffStyle:PSMTabBarTearOffAlphaWindow];
}

//Frames
- (NSString *)_frameSaveKey
{
	if ([[[adium preferenceController] preferenceForKey:KEY_TABBED_CHATTING
												  group:PREF_GROUP_INTERFACE] boolValue] &&
		![[[adium preferenceController] preferenceForKey:KEY_GROUP_CHATS_BY_GROUP
												   group:PREF_GROUP_INTERFACE] boolValue]) {
		return KEY_MESSAGE_WINDOW_POSITION;

	} else {
		//Not using tabbed chatting, or we're tabbing by groups: Save the window position on a per-container basis
		return [NSString stringWithFormat:@"%@ %@",KEY_MESSAGE_WINDOW_POSITION, containerID];	
	}
}
- (BOOL)shouldCascadeWindows
{
	if ([[[adium preferenceController] preferenceForKey:KEY_TABBED_CHATTING  group:PREF_GROUP_INTERFACE] boolValue])
		return NO;
	else //Not using tabbed chatting: Cascade if we have no frame
		return ([self savedFrameString] == nil);
}

//Close the message window
- (IBAction)closeWindow:(id)sender
{
	windowIsClosing = YES;

	[[self window] performClose:nil];
}

/*!
 * @brief Called as the window closes
 */
- (void)windowWillClose:(id)sender
{
    NSEnumerator			*enumerator;
    AIMessageTabViewItem	*tabViewItem;
	
	if ([tabView_tabBar orientation] == PSMTabBarVerticalOrientation) {
		float widthToStore;
		if ([tabView_tabBar isTabBarHidden]) {
			widthToStore = lastTabBarWidth;
		} else {
			widthToStore = NSWidth([tabView_tabBar frame]);
		}

		[[adium preferenceController] setPreference:[NSNumber numberWithFloat:widthToStore]
											 forKey:KEY_VERTICAL_TABS_WIDTH
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	}
	
	windowIsClosing = YES;
	[super windowWillClose:sender];

	[[adium preferenceController] unregisterPreferenceObserver:self];

    //Close all our tabs (The array will change as we remove tabs, so we must work with a copy)
	enumerator = [[tabView_messages tabViewItems] reverseObjectEnumerator];
    while ((tabViewItem = [enumerator nextObject])) {
		[[adium interfaceController] closeChat:[tabViewItem chat]];
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
		NSNumber *useOverflow = [prefDict objectForKey:KEY_TABBAR_OVERFLOW];
		[tabView_tabBar setUseOverflowMenu:(useOverflow ? [useOverflow boolValue] : YES)];
		
		[[tabView_tabBar overflowPopUpButton] setAlternateImage:[AIStatusIcons statusIconForStatusName:@"content" statusType:AIAvailableStatusType iconType:AIStatusIconTab direction:AIIconNormal]];
		//NSImage *overflowImage = [[[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForImageResource:@"overflow_overlay"]] autorelease];
		//[[tabView_tabBar overflowPopUpButton] setAlternateImage:overflowImage];
		
		//change the frame of the tab bar according to the orientation
		if (firstTime || [key isEqualToString:KEY_TABBAR_POSITION]) {
			PSMTabBarOrientation orientation;
			
			tabPosition = [[prefDict objectForKey:KEY_TABBAR_POSITION] intValue];
			orientation = ((tabPosition == AdiumTabPositionBottom || tabPosition == AdiumTabPositionTop) ?
						   PSMTabBarHorizontalOrientation :
						   PSMTabBarVerticalOrientation);

			NSRect tabBarFrame = [tabView_tabBar frame], tabViewMessagesFrame = [tabView_messages frame];
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
			
			switch (orientation) {
				case PSMTabBarHorizontalOrientation:
				{
					tabBarFrame.size.height = [tabView_tabBar isTabBarHidden] ? 1 : 22;
					tabBarFrame.size.width = contentRect.size.width + 1;
					
					//set the position of the tab bar (top/bottom)
					if (tabPosition == AdiumTabPositionBottom) {
						tabBarFrame.origin.y = NSMinY(contentRect);
						tabViewMessagesFrame.origin.y = NSHeight(tabBarFrame) + ([tabView_tabBar isTabBarHidden] ? 0 : (HORIZONTAL_TAB_BAR_TO_VIEW_SPACING - 1));
						tabViewMessagesFrame.size.height = (NSHeight(contentRect) - NSHeight(tabBarFrame) -
															([tabView_tabBar isTabBarHidden] ? 0 : (HORIZONTAL_TAB_BAR_TO_VIEW_SPACING - 2)));
						[tabView_tabBar setAutoresizingMask:(NSViewMaxYMargin | NSViewWidthSizable)];
						
					} else {
						tabBarFrame.origin.y = NSMaxY(contentRect) - NSHeight(tabBarFrame);
						tabViewMessagesFrame.origin.y = NSMinY(contentRect);
						tabViewMessagesFrame.size.height = NSHeight(contentRect) - NSHeight(tabBarFrame) + 2;
						[tabView_tabBar setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
					}
					/* If the cell is less than 60, icon + title + unread message count may overlap */
					[tabView_tabBar setCellMinWidth:60];
					[tabView_tabBar setCellMaxWidth:250];
					
					tabBarFrame.origin.x = 0;
					
					//Items within the tabview draw frames, so be sure to clip the left and right edges.
					tabViewMessagesFrame.origin.x = -1;
					tabViewMessagesFrame.size.width = NSWidth(contentRect) + 2;
					break;
				}
				case PSMTabBarVerticalOrientation:
				{
					float width = ([prefDict objectForKey:KEY_VERTICAL_TABS_WIDTH] ?
								   [[prefDict objectForKey:KEY_VERTICAL_TABS_WIDTH] floatValue] :
								   100);
					lastTabBarWidth = width;
					
					tabBarFrame.size.height = [[[self window] contentView] frame].size.height;
					tabBarFrame.size.width = [tabView_tabBar isTabBarHidden] ? 1 : width;
					tabBarFrame.origin.y = NSMinY(contentRect);
					tabViewMessagesFrame.origin.y = NSMinY(contentRect);
					tabViewMessagesFrame.size.height = NSHeight(contentRect) + 1;
					tabViewMessagesFrame.size.width = NSWidth(contentRect) - NSWidth(tabBarFrame) - 5;
					
					//set the position of the tab bar (left/right)
					if (tabPosition == AdiumTabPositionLeft) {
						tabBarFrame.origin.x = NSMinX(contentRect);
						tabViewMessagesFrame.origin.x = NSMaxX(tabBarFrame);
						[tabView_tabBar setAutoresizingMask:NSViewHeightSizable];
					} else {
						tabViewMessagesFrame.origin.x = NSMinX(contentRect);
						tabBarFrame.origin.x = NSWidth(contentRect) - NSWidth(tabBarFrame) + 1;
						[tabView_tabBar setAutoresizingMask:NSViewHeightSizable | NSViewMinXMargin];
					}
					[tabView_tabBar setCellMinWidth:50];
					[tabView_tabBar setCellMaxWidth:200];
					
					//put the subviews into a split view
					NSRect splitViewRect = [[[self window] contentView] frame];
					splitViewRect.size.width++;
					splitViewRect.size.height++;
					tabView_splitView = [[[AIMessageTabSplitView alloc] initWithFrame:splitViewRect] autorelease];
					[tabView_splitView setDividerThickness:([tabView_tabBar isTabBarHidden] ? 0 : VERTICAL_DIVIDER_THICKNESS)];
					[tabView_splitView setVertical:YES];
					[tabView_splitView setDelegate:self];
					if (tabPosition == AdiumTabPositionLeft) {
						[tabView_splitView addSubview:tabView_tabBar];
						[tabView_splitView addSubview:tabView_messages];
						[tabView_splitView setLeftColor:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]
											 rightColor:[NSColor colorWithCalibratedWhite:0.91 alpha:1.0]];
					} else {
						[tabView_splitView addSubview:tabView_messages];
						[tabView_splitView addSubview:tabView_tabBar];
						[tabView_splitView setLeftColor:[NSColor colorWithCalibratedWhite:0.91 alpha:1.0]
											 rightColor:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]];
					}
					[tabView_splitView adjustSubviews];
					[tabView_splitView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
					[[[self window] contentView] addSubview:tabView_splitView];
					break;
				}
			}
			
			[tabView_messages setFrame:tabViewMessagesFrame];
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
		if (![NSApp isOnLeopardOrBetter]) {
			[window setIgnoresExpose:(windowLevel == AIDesktopWindowLevel)]; //Ignore expose while on the desktop
		}
		[window setHidesOnDeactivate:[[prefDict objectForKey:KEY_WINDOW_HIDE] boolValue]];
    }
}

- (void)updateOverflowMenuUnviewedContentIcon
{
	BOOL someUnviewedContent = NO;
	
	int count = [[tabView_tabBar representedTabViewItems] count];
	for (int i = [tabView_tabBar numberOfVisibleTabs]; i < count; i++) {
		if ([[[[tabView_tabBar representedTabViewItems] objectAtIndex:i] chat] unviewedContentCount] > 0) {
			someUnviewedContent = YES;
			break;
		}
	}
	
	[[tabView_tabBar overflowPopUpButton] setAnimatingAlternateImage:someUnviewedContent];	
}


- (void)updateIconForTabViewItem:(AIMessageTabViewItem *)tabViewItem
{
	if (tabViewItem == [tabView_messages selectedTabViewItem]) {
		[self _updateWindowTitleAndIcon];
	}
	
	if ([[tabView_tabBar representedTabViewItems] indexOfObject:tabViewItem] >= [tabView_tabBar numberOfVisibleTabs]) {
		//The chat is in the overflow menu. If any chat has unviewed content, it should be animating to demonstrate that.
		[self updateOverflowMenuUnviewedContentIcon];
	}
}

- (AdiumTabPosition)tabPosition
{
	return tabPosition;
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
	/* XXX This mirrors the hack in -[AIMessageTabViewItem initWithMessageView]. It may have been undone
	 * in removeTabViewItem:silent: below if the tab was moving between windows.
	 */
	[inTabViewItem setIdentifier:inTabViewItem];

	if (index == -1) {
		[tabView_messages addTabViewItem:inTabViewItem];
	} else {
		[tabView_messages insertTabViewItem:inTabViewItem atIndex:index];
	}

	//Refresh our list and order of chats
	[self _reloadContainedChats];
	
	if (![tabView_messages selectedTabViewItem]) [tabView_messages selectNextTabViewItem:nil];
	
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
		[inTabViewItem setWindowController:nil];	

		[tabView_messages selectTabViewItem:oldTabViewItem];

	} else {
		//The tab view item needs to know that this window controller no longer contains it
		[inTabViewItem setWindowController:nil];
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

	/* AIMessageTabViewItem sets itself as its own identifer.  We have to break the recursive retain from the outside.
	 * This must be done last so that the NSTabView and its delegate (PSMTabBarControl) can still make use of the idenfitier.
	 */
	[inTabViewItem setIdentifier:nil];

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
	enumerator = [[tabView_messages tabViewItems] objectEnumerator];
	
	while ((tabViewItem = [enumerator nextObject])) {
		[tabViewItem setWindowController:self];
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
    if (([tabView_messages numberOfTabViewItems] == 1) || !containerName) {
        title = (label ? [NSString stringWithFormat:@"%@", label] : nil);
    } else {
		if (containerName && label) {
			title = [NSString stringWithFormat:@"%@ - %@", containerName, label];
		} else {
			if (containerName)
				title = containerName;
			else if (label)
				title = label;
			else
				title = nil;
		}
    }
	
	if (title) [window setTitle:title];
	
	//Window Icon (We display state in the window title if tabs are not visible)
	if (!hasShownDocumentButton) {
		if ([window respondsToSelector:@selector(addDocumentIconButton)]) {
			[window addDocumentIconButton];
		}
		hasShownDocumentButton = YES;
	}

	button = [window standardWindowButton:NSWindowDocumentIconButton];
		  
	if ([tabView_tabBar isTabBarHidden]) {
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
	AIMessageTabViewItem *selectedTabViewItem = (AIMessageTabViewItem *)[tabView_messages selectedTabViewItem];
	
	if (![selectedTabViewItem isKindOfClass:[AIMessageTabViewItem class]]) {
		return nil;
	}
	
	return [selectedTabViewItem chat];
}

//AISplitView Delegate -------------------------------------------------------------------------------------------------
#pragma mark AISplitView Delegate

#define MINIMUM_WIDTH_FOR_VERTICAL_TABS 50
#define MAXIMUM_WIDTH_FOR_VERTICAL_TABS 250

//handles the minimum size of vertical tabs
- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	float min = proposedMin;

	if (sender == tabView_splitView) {
		switch (tabPosition) {
			case AdiumTabPositionBottom:
			case AdiumTabPositionTop:
				/* should never be passed these */
				break;
			case AdiumTabPositionLeft:
				min = ([tabView_tabBar isTabBarHidden] ? 0 : MINIMUM_WIDTH_FOR_VERTICAL_TABS);
				break;
			case AdiumTabPositionRight:
				min = ([tabView_tabBar isTabBarHidden] ?
					   NSWidth([tabView_splitView frame]) :
					   (NSWidth([tabView_splitView frame]) - MAXIMUM_WIDTH_FOR_VERTICAL_TABS - [sender dividerThickness]));
				break;				
		}
	} else {
		NSLog(@"Unknown split view");
	}
	
	return min;
}

//handles the maximum size of vertical tabs
- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	float max = proposedMax;
	
	if (sender == tabView_splitView) {
		switch (tabPosition) {
			case AdiumTabPositionBottom:
			case AdiumTabPositionTop:
				/* should never be passed these */
				break;
			case AdiumTabPositionLeft:
				max = MAXIMUM_WIDTH_FOR_VERTICAL_TABS;
				break;
			case AdiumTabPositionRight:
				max = proposedMax - MINIMUM_WIDTH_FOR_VERTICAL_TABS;
				break;
		}
	} else {
		NSLog(@"Unknown split view");
	}
	
	return max;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect messageFrame = [tabView_messages frame], tabBarFrame = [tabView_tabBar frame];
	messageFrame.size = NSMakeSize([sender frame].size.width - tabBarFrame.size.width - [sender dividerThickness], [sender frame].size.height);
	tabBarFrame.size = NSMakeSize(tabBarFrame.size.width, [sender frame].size.height);
	
	if (sender == tabView_splitView) {
		switch (tabPosition) {
			case AdiumTabPositionBottom:
			case AdiumTabPositionTop:
				/* should never be passed these */
				break;
			case AdiumTabPositionLeft:
				messageFrame.origin.x = NSWidth(tabBarFrame) + [sender dividerThickness];
				break;
			case AdiumTabPositionRight:
				messageFrame.origin.x = 0;
				tabBarFrame.origin.x = NSWidth(messageFrame) + [sender dividerThickness];
				break;
		}
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
	if ([tabViewItem respondsToSelector:@selector(chat)]) {
		AIChat	*chat = [(AIMessageTabViewItem *)tabViewItem chat];
		
		[[adium interfaceController] closeChat:chat];
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
		if ([selectedObject isIntentionallyNotAStranger]) {
			locations = [NSMutableArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_ChatAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		} else {
			locations = [NSMutableArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_ChatAction],
				[NSNumber numberWithInt:Context_Contact_Stranger_ChatAction],
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
	
	//Remaining disabled until the last crasher I know of is removed
	/*if ([tabView numberOfTabViewItems] > 0) {
		[tabView_tabBar setAutomaticallyAnimates:YES];
	}*/
}

//Tabs reordered
- (void)tabView:(NSTabView*)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl;
{
	[self _reloadContainedChats];
	[[adium interfaceController] chatOrderDidChange];
}

//Allow dragging of text
- (NSArray *)allowedDraggedTypesForTabView:(NSTabView *)aTabView
{
	return [NSArray arrayWithObjects:NSRTFPboardType, NSStringPboardType, NSFilenamesPboardType, NSTIFFPboardType, NSPDFPboardType, NSPICTPboardType, nil];
}

//Accept dragged text
- (void)tabView:(NSTabView *)aTabView acceptedDraggingInfo:(id <NSDraggingInfo>)draggingInfo onTabViewItem:(NSTabViewItem *)tabViewItem
{
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
	
	switch (tabPosition) {
		case AdiumTabPositionBottom:
			offset->width = [style leftMarginForTabBarControl];
			offset->height = contentFrame.size.height;
			break;
		case AdiumTabPositionTop:
			offset->width = [style leftMarginForTabBarControl];
			offset->height = 21;
			break;
		case AdiumTabPositionLeft:
			offset->width = 0;
			offset->height = 21 + [style topMarginForTabBarControl];
			break;
		case AdiumTabPositionRight:
			offset->width = [tabView_tabBar frame].origin.x;
			offset->height = 21 + [style topMarginForTabBarControl];
			break;
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
	frame.origin = NSZeroPoint;
	[[newController window] setFrame:frame display:NO];
	
	switch (tabPosition) {
		case AdiumTabPositionBottom:
			point.x -= [style leftMarginForTabBarControl];
			point.y -= 22;
			break;
		case AdiumTabPositionTop:
			point.x -= [style leftMarginForTabBarControl];
			point.y -= NSHeight([[[newController window] contentView] frame]) + 1;
			break;
		case AdiumTabPositionLeft:
			point.y -= NSHeight([[[newController window] contentView] frame]) - [style topMarginForTabBarControl] + 1;
			break;
		case AdiumTabPositionRight:
			point.x -= NSMinX([tabView_tabBar frame]);
			point.y -= NSHeight([[[newController window] contentView] frame]) - [style topMarginForTabBarControl] + 1;
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
	switch ([tabBarControl orientation]) {
		case PSMTabBarHorizontalOrientation:
			/* We put a space between a bottom horizontal tab bar and the message tab view.
			 * This space is not needed when the tab bar is at the top.
			 */			
			if (tabPosition == AdiumTabPositionBottom) {
				frame.origin.y -= HORIZONTAL_TAB_BAR_TO_VIEW_SPACING;
				frame.size.height += HORIZONTAL_TAB_BAR_TO_VIEW_SPACING;				
			}
			break;

		case PSMTabBarVerticalOrientation:
			frame.origin.x -= VERTICAL_TAB_BAR_TO_VIEW_SPACING;
			frame.size.width += VERTICAL_TAB_BAR_TO_VIEW_SPACING;
			
			[tabView_splitView setDividerThickness:0];
			break;
	}

	[tabView setFrame:frame];
	[tabBarControl setHidden:YES];
	[tabView setNeedsDisplay:YES];

	[[tabView_messages tabViewItems] makeObjectsPerformSelector:@selector(tabViewDidChangeVisibility)];
}

- (void)tabView:(NSTabView *)tabView tabBarDidUnhide:(PSMTabBarControl *)tabBarControl
{
	//show the space between the tab bar and the tab view
    NSRect frame = [tabView frame];
	
	switch ([tabBarControl orientation]) {
		case PSMTabBarHorizontalOrientation:
			/* We put a space between a bottom horizontal tab bar and the message tab view.
			 * This space is not needed when the tab bar is at the top.
			 */
			if (tabPosition == AdiumTabPositionBottom) {
				frame.origin.y += HORIZONTAL_TAB_BAR_TO_VIEW_SPACING;
				frame.size.height -= HORIZONTAL_TAB_BAR_TO_VIEW_SPACING;				
			}
			break;

		case PSMTabBarVerticalOrientation:
			frame.origin.x += VERTICAL_TAB_BAR_TO_VIEW_SPACING;
			frame.size.width -= VERTICAL_TAB_BAR_TO_VIEW_SPACING;
			
			[tabView_splitView setDividerThickness:VERTICAL_DIVIDER_THICKNESS];
			break;
    }
    
    [tabView setFrame:frame];
	[tabBarControl setHidden:NO];
    [tabView setNeedsDisplay:YES];
	
	[[tabView_messages tabViewItems] makeObjectsPerformSelector:@selector(tabViewDidChangeVisibility)];
}

- (float)desiredWidthForVerticalTabBar:(PSMTabBarControl *)tabBarControl
{
	return (lastTabBarWidth ? lastTabBarWidth : 120);
}

- (NSString *)tabView:(NSTabView *)tabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem
{
	AIChat		*chat = [(AIMessageTabViewItem *)tabViewItem chat];
	NSString	*tooltip = nil;

	if ([chat isGroupChat]) {
		tooltip = [NSString stringWithFormat:AILocalizedString(@"%@ in %@","AccountName on ChatRoomName"), [[chat account] formattedUID], [chat name]];
	} else {
		AIListObject	*destination = [chat listObject];
		NSString		*destinationDisplayName = [destination displayName];
		NSString		*destinationFormattedUID = [destination formattedUID];
		BOOL			includeDestination = NO;
		BOOL			includeSource = NO;
		
		if (destinationFormattedUID && destinationDisplayName &&
			![[destinationDisplayName compactedString] isEqualToString:[destinationFormattedUID compactedString]]) {
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

- (void)tabView:(NSTabView *)aTabView tabViewItem:(NSTabViewItem *)tabViewItem isInOverflowMenu:(BOOL)inOverflowMenu
{
	//Wait until the next run loop, then update the icons so the overflow menu will be updated appropriately
	[self performSelector:@selector(updateOverflowMenuUnviewedContentIcon)
			   withObject:nil
			   afterDelay:0];
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
		if (![tabView_tabBar isTabBarHidden]) {
			float newWidth = NSWidth([tabView_tabBar frame]);
			if (newWidth >= MINIMUM_WIDTH_FOR_VERTICAL_TABS)
				lastTabBarWidth = newWidth;
			
		}
	}
}

/*//Custom Tabs Delegate -------------------------------------------------------------------------------------------------
#pragma mark Custom Tabs Delegate
//Bring our window to the front
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSDragOperation tmp = NSDragOperationNone;
    NSString 		*type = [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];

    if (sender == nil || type) {
        if (![[self window] isKeyWindow]) [[self window] makeKeyAndOrderFront:nil];
		[self _suppressTabHiding:YES];
        tmp = NSDragOperationPrivate;
    }
	return tmp;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	NSString 		*type = [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];
	
    if (sender == nil || type) [self _suppressTabHiding:NO];
}

- (void)_suppressTabHiding:(BOOL)suppress
{
	supressHiding = suppress;
	[self updateTabBarVisibilityAndAnimate:YES];
}

//Send the print message to our view
- (void)adiumPrint:(id)sender
{
	id	controller = [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] messageViewController];
	
	if ([controller respondsToSelector:@selector(adiumPrint:)]) {
		[controller adiumPrint:sender];
	}
}*/

//Toolbar --------------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Install our toolbar
- (void)_configureToolbar
{
//	NSToolbar *toolbar; change this if need be
    toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_MESSAGE_WINDOW] autorelease];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
	
    //
	toolbarItems = [[[adium toolbarController] toolbarItemsForToolbarTypes:[NSArray arrayWithObjects:@"General", @"ListObject", @"TextEntry", @"MessageWindow", nil]] retain];

	/* Seemingly randomly, setToolbar: may throw:
	 * Exception:	NSInternalInconsistencyException
	 * Reason:		Uninitialized rectangle passed to [View initWithFrame:].
	 *
	 * With the same window positioning information as a user for whom this happens consistently, I can't reproduce. Let's
	 * fail to set the toolbar gracefully.
	 */
	@try
	{
		[[self window] setToolbar:toolbar];
	}
	@catch(id exc)
	{
		NSLog(@"Warning: While setting the message window's toolbar, exception %@ was thrown.", exc);
	}
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"UserIcon",@"Encryption",  NSToolbarSeparatorItemIdentifier, 
		@"SourceDestination", @"InsertEmoticon", @"BlockParticipants", @"LinkEditor", @"SafariLink", @"AddBookmark", NSToolbarShowColorsItemIdentifier,
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

- (void)toolbarWillAddItem:(NSNotification *)notification
{

	NSToolbarItem *item = [[notification userInfo] objectForKey:@"item"];

	if ([[item itemIdentifier] isEqualToString:NSToolbarShowFontsItemIdentifier]) {
		[item setTarget:[adium interfaceController]];
		[item setAction:@selector(toggleFontPanel:)];
	}
}

- (void)removeToolbarItemWithIdentifier:(NSString*)identifier
{
	NSArray			*itemArray = [toolbar items];
	NSEnumerator	*enumerator = [itemArray objectEnumerator];
	NSToolbarItem	*item;
	int				index = NSNotFound;

	while ((item = [enumerator nextObject])) {
		if ([[item itemIdentifier] isEqualToString:identifier]) {
			index = [itemArray indexOfObject:item];
			break;
		}
	}

	if (index != NSNotFound) {
		[toolbar removeItemAtIndex:index];
	}
}

#pragma mark Miniaturization
/*!
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

- (BOOL)window:(NSWindow *)sender shouldDragDocumentWithEvent:(NSEvent *)mouseEvent from:(NSPoint)startPoint withPasteboard:(NSPasteboard *)pasteboard
{
	return NO;
}

#pragma mark Printing
/*!
 * @brief Support for printing.  Forward the print command to the active tab view's message view controller
 */
- (void)adiumPrint:(id)sender
{
	[[(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] messageViewController] adiumPrint:sender];
}

#pragma mark Gestures

/*!
 * @brief Responds to a swipe gesture
 *
 * This is a private method added in AppKit 949.18.0.
 */
- (void)swipeWithEvent:(NSEvent *)inEvent
{
	// We don't do anything for vertical swipes.
	if ([inEvent deltaY] != 0)
		return;
	
	// Horizontal swipe; +1f is left, -1f is right.
	if ([inEvent deltaX] == -1) {
		[[adium interfaceController] nextChat:nil];
	} else {
		[[adium interfaceController] previousChat:nil];
	}
}

@end
