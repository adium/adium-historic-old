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
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AICustomTabDragging.h>
#import <AIUtilities/AICustomTabsView.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>

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
- (BOOL)_resizeTabBarAbsolute:(NSNumber *)absolute;
- (void)_suppressTabHiding:(BOOL)suppress;
- (void)_updateWindowTitleAndIcon;
- (NSString *)_frameSaveKey;
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
												 selector:@selector(tabDraggingEnded:)
													 name:AICustomTabDragDidComplete
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(windowWillMiniaturize:)
													 name:NSWindowWillMiniaturizeNotification
												   object:myWindow];
		//Prefs
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		
		//Register as a tab drag observer so we know when tabs are dragged over our window and can show our tab bar
		[myWindow registerForDraggedTypes:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];
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

    [tabView_customTabs setDelegate:nil];
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
	
    //Remember the initial tab height
    tabBarHeight = [tabView_customTabs frame].size.height;

    //Exclude this window from the window menu (since we add it manually)
    [theWindow setExcludedFromWindowsMenu:YES];
	[theWindow useOptimizedDrawing:YES];

	[self _configureToolbar];

    //Remove any tabs from our tab view, it needs to start out empty
    while ([tabView_messages numberOfTabViewItems] > 0) {
        [tabView_messages removeTabViewItem:[tabView_messages tabViewItemAtIndex:0]];
    }
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
	[[adium interfaceController] chatDidBecomeActive:nil];
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
	if ([[self window] isVisible]) [[adium interfaceController] chatDidBecomeActive:nil];
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
		[tabView_customTabs setAllowsInactiveTabClosing:[[prefDict objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE] boolValue]];
		[tabView_customTabs setAllowsTabRearranging:YES];
		
		[self updateTabBarVisibilityAndAnimate:!firstTime];
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
		[containedChats addObject:[inTabViewItem chat]];
	} else {
		[tabView_messages insertTabViewItem:inTabViewItem atIndex:index];
		[containedChats insertObject:[inTabViewItem chat] atIndex:index];
	}
	
	[inTabViewItem setContainer:self];
	
	if (!silent) [[adium interfaceController] chatDidOpen:[inTabViewItem chat]];
}

//Remove a tab view item container
//If silent is NO, the interface controller will be informed of the remove
- (void)removeTabViewItem:(AIMessageTabViewItem *)inTabViewItem silent:(BOOL)silent
{
	//Tell the messageViewController that the tab view item will be closed so it can take action
	//before being removed from the window
	[[inTabViewItem messageViewController] tabViewItemWillClose];
	
    //If the tab is selected, select the next tab before closing it (To mirror the behavior of safari)
    if (!windowIsClosing && inTabViewItem == [tabView_messages selectedTabViewItem]) {
		[tabView_messages selectNextTabViewItem:nil];
    }
	
    //Remove the tab and let the interface know a container closed
	[containedChats removeObject:[inTabViewItem chat]];
	if (!silent) [[adium interfaceController] chatDidClose:[inTabViewItem chat]];
	
	[inTabViewItem retain];
    [tabView_messages removeTabViewItem:inTabViewItem];
	[inTabViewItem setContainer:nil];
	[inTabViewItem release];

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
		[tabView_customTabs moveTab:inTabViewItem toIndex:index];
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

//Our selected tab has changed, update the active chat
- (void)customTabView:(AICustomTabsView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
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

//Update our window title
- (void)_updateWindowTitleAndIcon
{
	NSString	*label = [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] label];
	NSString	*title;
	NSButton	*button;
	
	//Window Title
    if ([tabView_messages numberOfTabViewItems] == 1) {
        title = [NSString stringWithFormat:@"%@", label];
    } else {
		title = [NSString stringWithFormat:@"%@ - %@", containerName, label];
    }
	[[self window] setTitle:title];
	
	//Window Icon (We display state in the window title if tabs are not visible)
	if (!hasShownDocumentButton) {
		if ([[self window] respondsToSelector:@selector(addDocumentIconButton)]) {
			[[self window] addDocumentIconButton];
		}
		hasShownDocumentButton = YES;
	}
	
	button = [[self window] standardWindowButton:NSWindowDocumentIconButton];
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

//Custom Tabs Delegate -------------------------------------------------------------------------------------------------
#pragma mark Custom Tabs Delegate
//Contextual menu for tabs
- (NSMenu *)customTabView:(AICustomTabsView *)tabView menuForTabViewItem:(NSTabViewItem *)tabViewItem
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
- (void)customTabViewDidChangeNumberOfTabViewItems:(AICustomTabsView *)tabView
{       
    [self updateTabBarVisibilityAndAnimate:([[tabView window] isVisible])];
    [self _updateWindowTitleAndIcon];
}

//Tab rearranging
- (void)customTabViewDidChangeOrderOfTabViewItems:(AICustomTabsView *)TabView
{
	NSEnumerator			*enumerator;
	AIMessageTabViewItem	*tabViewItem;

	//Update our contained chats array to mirror the order of the tabs
	[containedChats release]; containedChats = [[NSMutableArray alloc] init];
	enumerator = [[tabView_messages tabViewItems] objectEnumerator];
	while ((tabViewItem = [enumerator nextObject])) {
		[containedChats addObject:[tabViewItem chat]];
	}
	
	[[adium interfaceController] chatOrderDidChange];
}

//Tab Dragging
- (void)customTabView:(AICustomTabsView *)tabView didMoveTabViewItem:(NSTabViewItem *)tabViewItem toCustomTabView:(AICustomTabsView *)destTabView index:(int)index screenPoint:(NSPoint)point
{
    [interface transferMessageTab:(AIMessageTabViewItem *)tabViewItem
					  toContainer:[[destTabView window] windowController]
						  atIndex:index
				withTabBarAtPoint:point];
}

//
- (int)customTabView:(AICustomTabsView *)tabView indexForInsertingTabViewItem:(NSTabViewItem *)tabViewItem
{
	return [tabView numberOfTabViewItems];
}

//Close a message tab
- (void)customTabView:(AICustomTabsView *)tabView closeTabViewItem:(NSTabViewItem *)tabViewItem
{
	AIChat	*chat = [(AIMessageTabViewItem *)tabViewItem chat];

	[interface closeChat:chat];
}

//Allow dragging of text
- (NSArray *)customTabViewAcceptableDragTypes:(AICustomTabsView *)tabView
{
    return [NSArray arrayWithObject:NSRTFPboardType];
}

//Accept dragged text
- (BOOL)customTabView:(AICustomTabsView *)tabView didAcceptDragPasteboard:(NSPasteboard *)pasteboard onTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSString    *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObject:NSRTFPboardType]];
	BOOL tmp = NO;
    if ([type isEqualToString:NSRTFPboardType]) { //got RTF data
        [[(AIMessageTabViewItem *)tabViewItem messageViewController] addToTextEntryView:[NSAttributedString stringWithData:[pasteboard dataForType:NSRTFPboardType]]];
        tmp = YES;
    }
    return tmp;
}



//Tab Bar Visibility --------------------------------------------------------------------------------------------------
#pragma mark Tab Bar Visibility
//Update the visibility of our tab bar (Tab bar is visible if autohide is off, or if there are 2 or more tabs present)
- (void)updateTabBarVisibilityAndAnimate:(BOOL)animate
{
    if (tabView_messages != nil) {
        BOOL    shouldShowTabs = (supressHiding || alwaysShowTabs || ([tabView_messages numberOfTabViewItems] > 1));

        if (shouldShowTabs != tabBarIsVisible) {
            tabBarIsVisible = shouldShowTabs;
            
			//We invoke both of these on a delay to prevent a display issue when dragging completes and the tab bar
			//is momentarily told to hide and then quickly to become visible again
			if (animate) {
				[self performSelector:@selector(_resizeTabBarAbsolute:)
						   withObject:[NSNumber numberWithBool:YES]
						   afterDelay:0.0001];
			} else {
				[self _resizeTabBarAbsolute:[NSNumber numberWithBool:YES]];
			}
        }
    }    
}

//Smoothly resize the tab bar (Calls itself with a timer until the tabbar is correctly positioned)
//- (void)_resizeTabBarTimer:(NSTimer *)inTimer
//{
//    //If the tab bar isn't at the right height, we set ourself to adjust it again
//    if (![self _resizeTabBarAbsolute:[NSNumber numberWithBool:NO]]) { 
//        [NSTimer scheduledTimerWithTimeInterval:(1.0/TAB_BAR_FPS)
//										 target:self
//									   selector:@selector(_resizeTabBarTimer:)
//									   userInfo:nil
//										repeats:NO];
//    }
//}

//Resize the tab bar towards it's desired height
- (BOOL)_resizeTabBarAbsolute:(NSNumber *)absolute
{   
    NSSize              tabSize = [tabView_customTabs frame].size;
    double              destHeight;
    NSRect              newFrame;

    //Determine the desired height
    destHeight = (tabBarIsVisible ? tabBarHeight : 0);
    
    //Move the tab view's height towards this desired height
    int distance = (destHeight - tabSize.height) * TAB_BAR_STEP;
    if ([absolute boolValue] || (distance > -1 && distance < 1)) distance = destHeight - tabSize.height;

    tabSize.height += distance;
    [tabView_customTabs setFrameSize:tabSize];
    [tabView_customTabs setNeedsDisplay:YES];

    //Adjust other views
    newFrame = [tabView_messages frame];
    newFrame.size.height -= distance;
    newFrame.origin.y += distance;
    [tabView_messages setFrame:newFrame];
    [tabView_messages setNeedsDisplay:YES];

	//[[self window] displayIfNeeded];
	
    //Return YES when the desired height is reached
    return (tabSize.height == destHeight);
}


//Tab Bar Hiding Suppression -------------------------------------------------------------------------------------------
//Make sure auto-hide suppression is off after a drag completes
- (void)tabDraggingEnded:(NSNotification *)notification
{
	[self _suppressTabHiding:NO];
}

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
		@"InsertEmoticon", @"LinkEditor", @"SafariLink", NSToolbarShowColorsItemIdentifier,
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
