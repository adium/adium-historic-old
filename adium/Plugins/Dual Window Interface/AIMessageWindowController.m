/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

//The tabbed window that contains messages

@interface AIMessageWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner interface:(id <AIContainerInterface>)inInterface;
- (void)dealloc;
- (BOOL)windowShouldClose:(id)sender;
- (BOOL)shouldCascadeWindows;
- (void)windowDidLoad;
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
/*    NSLog(@"closeWindow:");
    if([self windowShouldClose:nil]){
        [[self window] orderOut:nil]; //Order out (as opposed to close)
    }*/
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

    //observe
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabViewDidChangeOrderOfItems:) name:AITabView_DidChangeOrderOfItems object:tabView_messages];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabViewDidChangeSelectedItem:) name:AITabView_DidChangeSelectedItem object:tabView_messages];
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
        [[owner notificationCenter] postNotificationName:Interface_CloseMessage
                                                  object:[[tabViewItem messageViewController] contact]
                                                userInfo:nil];
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


//Notifications ---------------------------------------------------------------
//We relay these notifications from the tab view to the interface
- (void)tabViewDidChangeOrderOfItems:(NSNotification *)notification
{
    [interface containerOrderDidChange];
}

- (void)tabViewDidChangeSelectedItem:(NSNotification *)notification
{
    id <AIInterfaceContainer>	container = [[notification userInfo] objectForKey:@"TabViewItem"];

    if(container != nil){
        [(AIMessageTabViewItem *)container tabViewItemWasSelected]; //Let the tab know it was selected
        [interface containerDidBecomeActive:container];
    }
}

@end

