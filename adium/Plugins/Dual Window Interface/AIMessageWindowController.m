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

#import "AIMessageWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"

#define AIMessageTabDragBeganNotification		@"AIMessageTabDragBeganNotification"
#define AIMessageTabDragEndedNotification    	@"AIMessageTabDragEndedNotification"
#define	MESSAGE_WINDOW_NIB                      @"MessageWindow"			//Filename of the message window nib
#define TAB_BAR_FPS                             20.0
#define TAB_BAR_STEP                            0.6
#define TOOLBAR_MESSAGE_WINDOW					@"MessageWindow"			//Toolbar identifier

@interface AIMessageWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName interface:(AIDualWindowInterfacePlugin *)inInterface name:(NSString *)inName;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
- (BOOL)_resizeTabBarAbsolute:(NSNumber *)absolute;
- (void)_suppressTabHiding:(BOOL)suppress;
- (void)_updateWindowTitleAndIcon;
@end

@implementation AIMessageWindowController

//Create a new message window controller
+ (AIMessageWindowController *)messageWindowControllerForInterface:(AIDualWindowInterfacePlugin *)inInterface withName:(NSString *)inName
{
    return([[[self alloc] initWithWindowNibName:MESSAGE_WINDOW_NIB interface:inInterface name:inName] autorelease]);
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName interface:(AIDualWindowInterfacePlugin *)inInterface name:(NSString *)inName
{
    interface = [inInterface retain];
	name = [inName retain];
	containedChats = [[NSMutableArray alloc] init];
 	
    //Load our window
    [super initWithWindowNibName:windowNibName];
    [self window];

	//Tab hiding suppression (used to force tab bars visible when a drag is occuring)
    tabBarIsVisible = YES;
    supressHiding = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabDraggingEnded:)
												 name:AICustomTabDragDidComplete object:nil];
	
	
    //Prefs
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

	//Register as a tab drag observer so we know when tabs are dragged over our window and can show our tab bar
    [[self window] registerForDraggedTypes:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];

    //autosave
    [self setWindowFrameAutosaveName:@"DualWindowInterfaceMessageWindowFrame"];
    
    return(self);
}

//dealloc
- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];
    [tabView_customTabs setDelegate:nil];
	[containedChats release];
	[toolbarItems release];
	[name release];

    [super dealloc];
}

- (NSString *)name
{
	return(name);
}

//Setup our window before it is displayed
- (void)windowDidLoad
{
    //Remember the initial tab height
    tabBarHeight = [tabView_customTabs frame].size.height;

    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
	[[self window] useOptimizedDrawing:YES];
	[self _configureToolbar];

    //Remove any tabs from our tab view, it needs to start out empty
    while([tabView_messages numberOfTabViewItems] > 0){
        [tabView_messages removeTabViewItem:[tabView_messages tabViewItemAtIndex:0]];
    }
	
	//
	[[self window] addDocumentIconButton];
}

//Close the message window
- (IBAction)closeWindow:(id)sender
{
    [[self window] performClose:nil];
}

//
- (void)showWindowInFront:(BOOL)inFront
{
	if(inFront){
		[self showWindow:nil];
	}else{
		[[self window] orderWindow:NSWindowBelow relativeTo:[[NSApp mainWindow] windowNumber]];
	}
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    NSEnumerator			*enumerator;
    AIMessageTabViewItem	*tabViewItem;
	
	windowIsClosing = YES;

    //Close all our tabs (The array will change as we remove tabs, so we must work with a copy)
    enumerator = [[[[tabView_messages tabViewItems] copy] autorelease] objectEnumerator];
    while((tabViewItem = [enumerator nextObject])){
		[[adium interfaceController] closeChat:[tabViewItem chat]];
    }
	
	//Chats have all closed, set active to nil, let the interface know we closed
	[[adium interfaceController] chatDidBecomeActive:nil];
	[interface containerDidClose:self];

    return(YES);
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE]) {
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		
//		keepTabsArranged = [[preferenceDict objectForKey:KEY_KEEP_TABS_ARRANGED] boolValue];
//		arrangeByGroup = [[preferenceDict objectForKey:KEY_ARRANGE_TABS_BY_GROUP] boolValue];

#warning re-hook
//		[tabView_customTabs setAllowsInactiveTabClosing:[[preferenceDict objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE] boolValue]];

#warning done within here? .. seems we have to
//		[tabView_customTabs setAllowsTabRearranging:(![[preferenceDict objectForKey:KEY_KEEP_TABS_ARRANGED] boolValue])];
//		[tabView_customTabs setAllowsTabDragging:(![[preferenceDict objectForKey:KEY_ARRANGE_TABS_BY_GROUP] boolValue])];

		alwaysShowTabs = NO;//![[preferenceDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue];
		[self updateTabBarVisibilityAndAnimate:(notification != nil)];
    }
}

- (void)updateIconForTabViewItem:(AIMessageTabViewItem *)tabViewItem
{
	if(tabViewItem == [tabView_messages selectedTabViewItem]){
		[self _updateWindowTitleAndIcon];
	}
}

//Contained Chats ------------------------------------------------------------------------------------------------------
#pragma mark Contained Chats
//Add a tab view item container at the end of the tabs (without changing the current selection)
- (void)addTabViewItem:(AIMessageTabViewItem *)inTabViewItem
{    
    [self addTabViewItem:inTabViewItem atIndex:-1];
}

//Add a tab view item container (without changing the current selection)
- (void)addTabViewItem:(AIMessageTabViewItem *)inTabViewItem atIndex:(int)index
{
	if(index == -1){
		[tabView_messages addTabViewItem:inTabViewItem];
		[containedChats addObject:[inTabViewItem chat]];
	}else{
		[tabView_messages insertTabViewItem:inTabViewItem atIndex:index];
		[containedChats insertObject:[inTabViewItem chat] atIndex:index];
	}
	
	[inTabViewItem setContainer:self];

	[[adium interfaceController] chatDidOpen:[inTabViewItem chat]];
}

//Remove a tab view item container
- (void)removeTabViewItem:(AIMessageTabViewItem *)inTabViewItem
{
    //If the tab is selected, select the next tab before closing it (To mirror the behavior of safari)
    if(!windowIsClosing && inTabViewItem == [tabView_messages selectedTabViewItem]){
		[tabView_messages selectNextTabViewItem:nil];
    }
	
    //Remove the tab and let the interface know a container closed
	[containedChats removeObject:[inTabViewItem chat]];
	[[adium interfaceController] chatDidClose:[inTabViewItem chat]];
    [tabView_messages removeTabViewItem:inTabViewItem];
	[inTabViewItem setContainer:nil];
	
	//close if we're empty
	if(!windowIsClosing && [containedChats count] == 0){
		[self closeWindow:nil];
	}
}

//
- (void)moveTabViewItem:(AIMessageTabViewItem *)inTabViewItem toIndex:(int)index
{
	AIChat	*chat = [inTabViewItem chat];

	if([containedChats indexOfObject:chat] != index){
		if([tabView_messages indexOfTabViewItem:inTabViewItem] < index) index--;
		
		[tabView_customTabs moveTab:inTabViewItem toIndex:index selectTab:NO];
		[containedChats moveObject:chat toIndex:index];
		
		[[adium interfaceController] chatOrderDidChange];
	}
}

//Returns YES if we are empty (currently contain no chats)
- (BOOL)containerIsEmpty
{
	return([containedChats count] == 0);
}

//Returns an array of the chats we contain
- (NSArray *)containedChats
{
    return(containedChats);
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
    if(tabViewItem != nil){
        [(AIMessageTabViewItem *)tabViewItem tabViewItemWasSelected]; //Let the tab know it was selected
		
        if([[self window] isMainWindow]){ //If our window is main, set the newly selected container as active
			[[adium interfaceController] chatDidBecomeActive:[(AIMessageTabViewItem *)tabViewItem chat]];
        }
		
        [self _updateWindowTitleAndIcon]; //Reflect change in window title
    }
}

//Update our window title
- (void)_updateWindowTitleAndIcon
{
	//Window Title
    if([tabView_messages numberOfTabViewItems] == 1){
        [[self window] setTitle:[NSString stringWithFormat:@"%@", [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] label]]];
    }else{
        [[self window] setTitle:[NSString stringWithFormat:@"%@ Ð %@", name, [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] label]]];
//        [[self window] setTitle:name/*@"Adium : Messages"*/];
    }
	
	//Window Icon (We display state in the window title if tabs are not visible)
	NSButton	*button = [[self window]standardWindowButton:NSWindowDocumentIconButton];
	//	NSLog(@"%@",button);
	
//	if([tabView_messages numberOfTabViewItems] == 1 && !alwaysShowTabs){
		[button setImage:[(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] stateIcon]];
//	}else{
//		[button setImage:nil];
//	}
}


//Custom Tabs Delegate -------------------------------------------------------------------------------------------------
#pragma mark Custom Tabs Delegate
//Contextual menu for tabs
- (NSMenu *)customTabView:(AICustomTabsView *)tabView menuForTabViewItem:(NSTabViewItem *)tabViewItem
{
    AIListObject	*selectedObject = [[(AIMessageTabViewItem *)tabViewItem chat] listObject];
    
    if(selectedObject){
		NSArray *locations;
		if ([selectedObject integerStatusObjectForKey:@"Stranger"]){
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_TabAction],
				[NSNumber numberWithInt:Context_Contact_Stranger_TabAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		}else{
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_TabAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		}
		
		return([[adium menuController] contextualMenuWithLocations:locations
													 forListObject:selectedObject]);
        
    }
	
	return(nil);
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

//Close a message tab
- (void)customTabView:(AICustomTabsView *)tabView closeTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[adium interfaceController] closeChat:[(AIMessageTabViewItem *)tabViewItem chat]];
}

//Allow dragging of text
- (NSArray *)customTabViewAcceptableDragTypes:(AICustomTabsView *)tabView
{
    return([NSArray arrayWithObject:NSRTFPboardType]);
}

//Accept dragged text
- (BOOL)customTabView:(AICustomTabsView *)tabView didAcceptDragPasteboard:(NSPasteboard *)pasteboard onTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSString    *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:NSRTFPboardType,nil]];
    if([type isEqualToString:NSRTFPboardType]){ //got RTF data
        [[(AIMessageTabViewItem *)tabViewItem messageViewController] addToTextEntryView:[NSAttributedString stringWithData:[pasteboard dataForType:NSRTFPboardType]]];
        return(YES);
    }
    return(NO);
}



//Tab Bar Visibility --------------------------------------------------------------------------------------------------
#pragma mark Tab Bar Visibility
//Update the visibility of our tab bar (Tab bar is visible if autohide is off, or if there are 2 or more tabs present)
- (void)updateTabBarVisibilityAndAnimate:(BOOL)animate
{
    if(tabView_messages != nil){
        BOOL    shouldShowTabs = (supressHiding || alwaysShowTabs || ([tabView_messages numberOfTabViewItems] > 1));
		
        if(shouldShowTabs != tabBarIsVisible){
            tabBarIsVisible = shouldShowTabs;
            
			//We invoke both of these on a delay to prevent a display issue when dragging completes and the tab bar
			//is momentarily told to hide and then quickly to become visible again
//            if(animate){
//				[self performSelector:@selector(_resizeTabBarTimer:)
//						   withObject:nil
//						   afterDelay:0.0001];
//            }else{
			if(animate){
				[self performSelector:@selector(_resizeTabBarAbsolute:)
						   withObject:[NSNumber numberWithBool:YES]
						   afterDelay:0.0001];
			}else{
				[self _resizeTabBarAbsolute:[NSNumber numberWithBool:YES]];
			}
			
//			}
        }
    }    
}

//Smoothly resize the tab bar (Calls itself with a timer until the tabbar is correctly positioned)
//- (void)_resizeTabBarTimer:(NSTimer *)inTimer
//{
//    //If the tab bar isn't at the right height, we set ourself to adjust it again
//    if(![self _resizeTabBarAbsolute:[NSNumber numberWithBool:NO]]){ 
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
    if([absolute boolValue] || (distance > -1 && distance < 1)) distance = destHeight - tabSize.height;

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
    return(tabSize.height == destHeight);
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
    NSString 		*type = [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];

    if(sender == nil || type){
        if(![[self window] isKeyWindow]) [[self window] makeKeyAndOrderFront:nil];
		[self _suppressTabHiding:YES];
        return(NSDragOperationPrivate);
    }else{
		return(NSDragOperationNone);
	}

}
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	NSString 		*type = [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];
	
    if(sender == nil || type) [self _suppressTabHiding:NO];
}

- (void)_suppressTabHiding:(BOOL)suppress
{
	supressHiding = suppress;
	[self updateTabBarVisibilityAndAnimate:YES];
}


//Toolbar --------------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Install our toolbar
- (void)_configureToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_MESSAGE_WINDOW] autorelease];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
	
    //
	toolbarItems = [[[adium toolbarController] toolbarItemsForToolbarTypes:[NSArray arrayWithObjects:@"General", @"ListObject", @"TextEntry", nil]] retain];
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return([NSArray arrayWithObjects:@"ShowInfo", NSToolbarSeparatorItemIdentifier, @"InsertEmoticon", NSToolbarFlexibleSpaceItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, @"ShowPreferences", nil]);
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return([[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]]);
}

@end
