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


#define TABS_HEIGHT_CHANGE	12

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

//Returns the selected container
- (NSTabViewItem <AIInterfaceContainer> *)selectedTabViewItemContainer
{
    return([tabView_messages selectedTabViewItem]);
}

//Select a container
- (void)selectTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem
{
    [self showWindow:nil];

    if(inTabViewItem){
        [tabView_messages selectTabViewItem:inTabViewItem];
    }
}

//Add a tab view item container (without changing the current selection)
- (void)addTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem
{
    [self window]; //Ensure our window has loaded
    [tabView_messages addTabViewItem:inTabViewItem]; //Add the tab
    [self showWindow:nil]; //Show the window
}

//Remove a tab view item container
- (void)removeTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem
{
    [self removeTabViewItemContainer:inTabViewItem removingChat:YES];
}

- (void)removeTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem removingChat:(BOOL)remove
{
    [(AIMessageTabViewItem *)inTabViewItem tabShouldClose:nil closingChat:remove];
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

//    [[self window] setShowsResizeIndicator:NO];
    [[self window] setBottomCornerRounded:NO]; //Sneaky lil private method

}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    NSArray				*viewArrayCopy = [[[tabView_messages tabViewItems] copy] autorelease]; //the array will change as we remove views, so we must work with a copy
    NSEnumerator			*enumerator;
    AIMessageTabViewItem		*tabViewItem;

    //We are closing
    windowIsClosing = YES;

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

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [interface containerDidBecomeActive:(NSTabViewItem <AIInterfaceContainer> *)[tabView_messages selectedTabViewItem]];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    [interface containerDidBecomeActive:nil];
}


//Tabs Delegate ---------------------------------------------------------------
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

- (void)customTabView:(AICustomTabsView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if(tabViewItem != nil){
        [(AIMessageTabViewItem *)tabViewItem tabViewItemWasSelected]; //Let the tab know it was selected

        if([[self window] isMainWindow]){ //If our window is main, set the newly selected container as active
            [interface containerDidBecomeActive:(AIMessageTabViewItem *)tabViewItem];
        }
    }
}

- (void)customTabViewDidChangeNumberOfTabViewItems:(AICustomTabsView *)TabView
{
    NSSize newSize = [TabView frame].size;
    
    if ([tabView_messages numberOfTabViewItems] == 1) {
	newSize.height = 0;
	[TabView setFrameSize:newSize];

	NSRect newFrame = [tabView_messages frame];
	newFrame.size.height += TABS_HEIGHT_CHANGE;
	newFrame.origin.y -= TABS_HEIGHT_CHANGE;
	[tabView_messages setFrame:newFrame];

	[[self window] setTitle:[NSString stringWithFormat:@"Adium : %@",
	    [[[[[[self messageContainerArray] objectAtIndex:0] messageViewController] chat] listObject] displayName]]];
	
	[[self window] display];
	
    } else if ([tabView_messages numberOfTabViewItems] == 2) {
	newSize.height = 22;
	[TabView setFrameSize:newSize];
	
	NSRect newFrame = [tabView_messages frame];
	newFrame.size.height -= TABS_HEIGHT_CHANGE;
	newFrame.origin.y += TABS_HEIGHT_CHANGE;
	[tabView_messages setFrame:newFrame];

	[[self window] setTitle:@"Adium : Messages"];
	[[self window] display];
    } 
}

- (void)customTabViewDidChangeOrderOfTabViewItems:(AICustomTabsView *)TabView
{
    //Refresh interface menus
    [interface containerOrderDidChange];
}

- (void)customTabView:(AICustomTabsView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
    //Close the message tab
    [[owner interfaceController] closeChat:[[(AIMessageTabViewItem *)tabViewItem messageViewController] chat]];
}

@end

