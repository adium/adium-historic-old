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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIMessageWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import "AIAdium.h"

#define	MESSAGE_WINDOW_NIB		@"MessageWindow"		//Filename of the message window nib
#define KEY_DUAL_MESSAGE_WINDOW_FRAME	@"Dual Message Window Frame"

#define AUTOHIDE_TABBAR		NO
//The tabbed window that contains messages
@interface NSWindow (UNDOCUMENTED) //Handy undocumented window method
- (void)setBottomCornerRounded:(BOOL)rounded;
@end

@interface AIMessageWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner interface:(id <AIContainerInterface>)inInterface;
- (void)dealloc;
- (BOOL)windowShouldClose:(id)sender;
- (BOOL)shouldCascadeWindows;
- (void)windowDidLoad;
- (void)installToolbar;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_updateWindowTitle;
- (void)_updateTabBarVisibility;
@end

@implementation AIMessageWindowController

//Create a new message window controller
+ (AIMessageWindowController *)messageWindowControllerWithOwner:(id)inOwner interface:(id <AIContainerInterface>)inInterface
{
    return([[[self alloc] initWithWindowNibName:MESSAGE_WINDOW_NIB owner:inOwner interface:inInterface] autorelease]);
}

//Close the message window
- (IBAction)closeWindow:(id)sender
{
    [[self window] performClose:nil];
}

//Return the contained message tabs
- (NSArray *)messageContainerArray
{
    return([tabView_messages tabViewItems]);
}

//
- (BOOL)containsMessageContainer:(NSTabViewItem <AIInterfaceContainer> *)tabViewItem
{
    return([[self messageContainerArray] indexOfObjectIdenticalTo:tabViewItem] != NSNotFound);
}

//returns if we have it
- (NSTabViewItem <AIInterfaceContainer> *)containerForListObject:(AIListObject *)inListObject
{
    NSEnumerator		*enumerator;
    AIMessageTabViewItem	*container;

    enumerator = [[self messageContainerArray] objectEnumerator];
    while((container = [enumerator nextObject])){
        if([[[container messageViewController] chat] listObject] == inListObject) break;
    }

    return(container);
}

//returns if we have it
- (NSTabViewItem <AIInterfaceContainer> *)containerForChat:(AIChat *)inChat
{
    NSEnumerator		*enumerator;
    AIMessageTabViewItem	*container;

    enumerator = [[self messageContainerArray] objectEnumerator];
    while((container = [enumerator nextObject])){
        if([[container messageViewController] chat] == inChat) break;
    }

    return(container);
}

//Returns the selected container
- (NSTabViewItem <AIInterfaceContainer> *)selectedTabViewItemContainer
{
    return([tabView_messages selectedTabViewItem]);
}

//Select a specific container
- (void)selectTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem
{
    [self showWindow:nil];

    if(inTabViewItem){
        [tabView_messages selectTabViewItem:inTabViewItem];
    }
}

//Select the next container, returns YES if a new container was selected
- (BOOL)selectNextTabViewItemContainer
{
    NSTabViewItem	*previousSelection = [tabView_messages selectedTabViewItem];

    [self showWindow:nil];
    [tabView_messages selectNextTabViewItem:nil];

    return([tabView_messages selectedTabViewItem] != previousSelection); 
}

//Select the previous container, returns YES if a new container was selected
- (BOOL)selectPreviousTabViewItemContainer
{
    NSTabViewItem	*previousSelection = [tabView_messages selectedTabViewItem];

    [self showWindow:nil];
    [tabView_messages selectPreviousTabViewItem:nil];

    return([tabView_messages selectedTabViewItem] != previousSelection);
}

//Select our first container
- (void)selectFirstTabViewItemContainer
{
    [self showWindow:nil];
    [tabView_messages selectFirstTabViewItem:nil];
}

//Select our last container
- (void)selectLastTabViewItemContainer
{
    [self showWindow:nil];
    [tabView_messages selectLastTabViewItem:nil];
}

//Add a tab view item container (without changing the current selection)
- (void)addTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem
{
    [self window]; //Ensure our window has loaded
    [tabView_messages addTabViewItem:inTabViewItem]; //Add the tab
    [interface containerDidOpen:inTabViewItem]; //Let the interface know it opened
    [self showWindow:nil]; //Show the window
}

//Remove a tab view item container
- (void)removeTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem
{
    //If the tab is selected, select the next tab.
    if(inTabViewItem == [tabView_messages selectedTabViewItem]){
	[tabView_messages selectNextTabViewItem:nil];
    }
    
    [tabView_messages removeTabViewItem:inTabViewItem];
    [interface containerDidClose:inTabViewItem];

    //If that was our last container, close the window (unless we're already closing)
    if(!windowIsClosing && [tabView_messages numberOfTabViewItems] == 0){
        [self closeWindow:nil];
    }
}

//Private -----------------------------------------------------------------------------
//init
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner interface:(id <AIContainerInterface>)inInterface
{
    NSParameterAssert(windowNibName != nil && [windowNibName length] != 0);

    owner = [inOwner retain];
    interface = [inInterface retain];
    windowIsClosing = NO;
    tabIsShowing = YES;

    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    [self preferencesChanged:nil];
    
    [super initWithWindowNibName:windowNibName owner:self];
    [self window];	//Load our window
        
    return(self);
}

//dealloc
- (void)dealloc
{
    [owner release];
    [interface release];

    [super dealloc];
}

//Setup our window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;
    
    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_DUAL_MESSAGE_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }

    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];

    //Remove any tabs from our tab view, it needs to start out empty
    while([tabView_messages numberOfTabViewItems] > 0){
        [tabView_messages removeTabViewItem:[tabView_messages tabViewItemAtIndex:0]];
    }

    [[self window] setBottomCornerRounded:NO]; //Sneaky lil private method
    [[self window] useOptimizedDrawing:YES]; //should be set to YES unless subview overlap... we should be good to go.  check the docs on this for more info.
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    NSArray				*viewArrayCopy = [[[tabView_messages tabViewItems] copy] autorelease]; //the array will change as we remove views, so we must work with a copy
    NSEnumerator			*enumerator;
    AIMessageTabViewItem		*tabViewItem;

    //Close down
    windowIsClosing = YES; //This is used to prevent sending more close commands than needed.
    [[owner notificationCenter] removeObserver:self];
    
    //Close all our tabs
    enumerator = [viewArrayCopy objectEnumerator];
    while((tabViewItem = [enumerator nextObject])){
        [[owner interfaceController] closeChat:[[tabViewItem messageViewController] chat]];
    }

    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_DUAL_MESSAGE_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
    return(YES);
}

//Prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//
- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [interface containerDidBecomeActive:(NSTabViewItem <AIInterfaceContainer> *)[tabView_messages selectedTabViewItem]];
}

//
- (void)windowDidResignMain:(NSNotification *)notification
{
    [interface containerDidBecomeActive:nil];
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DUAL_WINDOW_INTERFACE] == 0) {
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

        autohide_tabBar = [[preferenceDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue];

        //
        [self _updateTabBarVisibility];
    }
}

//
- (NSMenu *)customTabView:(AICustomTabsView *)tabView menuForTabViewItem:(NSTabViewItem *)tabViewItem
{
    AIListObject	*selectedContact = [[[(AIMessageTabViewItem *)tabViewItem messageViewController] chat] listObject];
    
    if(selectedContact && [selectedContact isKindOfClass:[AIListContact class]]){
        return([[owner menuController] contextualMenuWithLocations:[NSArray arrayWithObjects:
            [NSNumber numberWithInt:Context_Contact_Manage],
            [NSNumber numberWithInt:Context_Contact_Action],
            [NSNumber numberWithInt:Context_Contact_NegativeAction],
            [NSNumber numberWithInt:Context_Contact_Additions], nil]
                                                        forContact:(AIListContact *)selectedContact]);
        
    }else{
        return(nil);

    }
}

//
- (void)customTabView:(AICustomTabsView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if(tabViewItem != nil){
        [(AIMessageTabViewItem *)tabViewItem tabViewItemWasSelected]; //Let the tab know it was selected

        if([[self window] isMainWindow]){ //If our window is main, set the newly selected container as active
            [interface containerDidBecomeActive:(AIMessageTabViewItem *)tabViewItem];
        }

        //[self _updateWindowTitle]; //Reflect change in window title
    }
}

//
- (void)customTabViewDidChangeNumberOfTabViewItems:(AICustomTabsView *)TabView
{
    [self _updateTabBarVisibility];
    [self _updateWindowTitle];
}

//
- (void)customTabViewDidChangeOrderOfTabViewItems:(AICustomTabsView *)TabView
{
    //Refresh interface menus
    [interface containerOrderDidChange];
}

//
- (void)customTabView:(AICustomTabsView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
    //Close the message tab
    [[owner interfaceController] closeChat:[[(AIMessageTabViewItem *)tabViewItem messageViewController] chat]];
}

//Update our window title
- (void)_updateWindowTitle
{
    if([tabView_messages numberOfTabViewItems] == 1){
        [[self window] setTitle:[NSString stringWithFormat:@"Adium : %@", [(AIMessageTabViewItem *)[tabView_messages selectedTabViewItem] labelString]]];
    }else{
        [[self window] setTitle:@"Adium : Messages"];
    }
}

//Hide/show our tab bar
- (void)_updateTabBarVisibility
{
    NSSize	tabSize;
    NSRect 	newFrame;

    if(autohide_tabBar && ([tabView_messages numberOfTabViewItems] == 1) && tabIsShowing){
        //Remember the correct tab height
        tabSize = [tabsView_customTabs frame].size;
        tabHeight = tabSize.height;

        //Resize tabs so they're not visible
        tabSize.height = 0;
        [tabsView_customTabs setFrameSize:tabSize];
        tabIsShowing = NO;

        //Adjust other views
        newFrame = [tabView_messages frame];
        newFrame.size.height += tabHeight;
        newFrame.origin.y -= tabHeight;
        [tabView_messages setFrame:newFrame];

        //Refresh
        [[self window] display];

    }else if((([tabView_messages numberOfTabViewItems] == 2) || !autohide_tabBar) && !tabIsShowing) {
        //Restore tabs to the correct height
        tabSize = [tabsView_customTabs frame].size;
        tabSize.height = tabHeight;
        [tabsView_customTabs setFrameSize:tabSize];
        tabIsShowing = YES;

        //Adjust other views
        newFrame = [tabView_messages frame];
        newFrame.size.height -= tabHeight;
        newFrame.origin.y += tabHeight;
        [tabView_messages setFrame:newFrame];

        //Refresh
        [[self window] display];
    }
}

@end

