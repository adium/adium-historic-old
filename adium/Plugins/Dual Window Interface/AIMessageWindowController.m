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
#import "AIAdium.h"
#import "AIDualWindowInterface.h"

#define	MESSAGE_WINDOW_NIB	@"MessageWindow"		//Filename of the message window nib

// The tabbed window that contains messages

@interface AIMessageWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner interface:(AIDualWindowInterface *)inInterface;
- (void)dealloc;
- (void)tabViewDidChangeOrderOfTabViewItems:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (BOOL)shouldCascadeWindows;
@end

@implementation AIMessageWindowController

//Create a new message window controller
+ (AIMessageWindowController *)messageWindowControllerWithOwner:(id)inOwner interface:(AIDualWindowInterface *)inInterface
{
    return([[[self alloc] initWithWindowNibName:MESSAGE_WINDOW_NIB owner:inOwner interface:inInterface] autorelease]);
}

//select a message
- (void)selectMessageViewController:(id <AIMessageView>)inController
{
    NSTabViewItem	*tabViewItem = [tabView_messages tabViewItemWithIdentifier:inController];

    if(tabViewItem){
        [tabView_messages selectTabViewItem:tabViewItem];

        [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:AIMessageWindow_SelectedControllerChanged
                                                                        object:self
                                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:inController,@"Controller",nil]];
    }
}

//Selects the next message view.  If the current selection is last, NO is returned, and the selected tab is not changed.  Otherwise returns YES
- (BOOL)selectNextController
{
    int		selectedIndex = [tabView_messages indexOfTabViewItem:[tabView_messages selectedTabViewItem]];
    BOOL	selectionChanged;
    
    if(selectedIndex < ([tabView_messages numberOfTabViewItems] - 1)){ //Select the next tab
        [tabView_messages selectNextTabViewItem:nil];
        selectionChanged = YES;
    }else{ //were at the last tab, return NO
        selectionChanged = NO;        
    }

    return(selectionChanged);
}

//Selects the previous message view.  If the current selection is first, NO is returned, and the selected tab is not changed.  Otherwise returns YES
- (BOOL)selectPreviousController
{
    int		selectedIndex = [tabView_messages indexOfTabViewItem:[tabView_messages selectedTabViewItem]];
    BOOL	selectionChanged;

    if(selectedIndex > 0){ //Select the previous tab
        [tabView_messages selectPreviousTabViewItem:nil];
        selectionChanged = YES;
    }else{ //were at the first tab, return NO
        selectionChanged = NO;
    }

    return(selectionChanged);
}

- (void)selectFirstController
{
    [tabView_messages selectTabViewItemAtIndex:0];
}

- (void)selectLastController
{
    [tabView_messages selectTabViewItemAtIndex:[tabView_messages numberOfTabViewItems]-1 ];
}

//add a message
- (void)addMessageViewController:(id <AIMessageView>)inController
{
    NSTabViewItem	*tabViewItem;
    AIContactHandle	*handle;

    //Make sure our window is loaded
    [self window];
    
    //Setup the view
    tabViewItem = [[[NSTabViewItem alloc] initWithIdentifier:inController] autorelease];
    [tabViewItem setView:[inController view]];
    
    handle = [inController handle];
    if(handle){
        [tabViewItem setLabel:[handle displayName]];
    }else{
        [tabViewItem setLabel:[[inController title] string]];
    }

    //Add the Controller
    [tabView_messages addTabViewItem:tabViewItem];
    [messageViewArray addObject:inController];
    [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:AIMessageWindow_ControllersChanged
                                                                    object:self
                                                                  userInfo:nil];
}

//remove a message
- (void)removeMessageViewController:(id <AIMessageView>)inController
{
    NSTabViewItem	*tabViewItem;

    tabViewItem = [tabView_messages tabViewItemWithIdentifier:inController];
    if(tabViewItem){
        //Remove the controller
        [tabView_messages removeTabViewItem:tabViewItem];
        [messageViewArray removeObject:inController];
        [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:AIMessageWindow_ControllersChanged
                                                                        object:self
                                                                      userInfo:nil];        
    }
}

//number of contained message controllers
- (int)count
{
    return([messageViewArray count]);
}

//return the contained message controllers
- (NSArray *)messageViewArray
{
    return(messageViewArray);
}

//Returns the selected message view
- (id <AIMessageView>)selectedMessageView
{
    return([[tabView_messages selectedTabViewItem] identifier]);
}

//Close the message window (closing the window does not unload it - it is just hidden)
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] orderOut:nil]; //Order out (as opposed to close)
    }
}


//Private -----------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner interface:(AIDualWindowInterface *)inInterface
{
    NSParameterAssert(windowNibName != nil && [windowNibName length] != 0);

    owner = [inOwner retain];
    interface = [inInterface retain];
    messageViewArray = [[NSMutableArray alloc] init];

    [super initWithWindowNibName:windowNibName owner:self];
        
    return(self);
}

- (void)dealloc
{
    [owner release];
    [interface release];
    [messageViewArray release];

    [super dealloc];
}

- (void)tabViewDidChangeOrderOfTabViewItems:(NSNotification *)notification
{
    NSEnumerator 	*enumerator;
    NSTabViewItem	*tabViewItem;

    //Rebuild / Reorder our array
    [messageViewArray release]; messageViewArray = [[NSMutableArray alloc] init];
    enumerator = [[tabView_messages tabViewItems] objectEnumerator];
    while((tabViewItem = [enumerator nextObject])){
        [messageViewArray addObject:[tabViewItem identifier]];
    }
    
    //Post a 'Controller order changed' notification so the interface can update its window menu
    [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:AIMessageWindow_ControllerOrderChanged
                                                                    object:self
                                                                  userInfo:nil];
}

- (void)windowDidLoad
{
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];

    //Remove any tabs from our tab view, it needs to start out empty
    while([tabView_messages numberOfTabViewItems] > 0){
        [tabView_messages removeTabViewItem:[tabView_messages tabViewItemAtIndex:0]];
    }

    //observe
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabViewDidChangeOrderOfTabViewItems:) name:AITabViewDidChangeOrderOfTabViewItemsNotification object:tabView_messages];
}

// called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
/*    NSArray		*viewArrayCopy = [[[tabView_messages tabViewItems] copy] autorelease]; //the array will change as we remove views, so we must work with a copy
    NSEnumerator 	*enumerator;
    NSTabViewItem	*tabViewItem;

    //close all our tabs
    enumerator = [viewArrayCopy objectEnumerator];
    while((tabViewItem = [enumerator nextObject])){
        [interface closeMessageViewController:[tabViewItem identifier]];
    }
*/
    return(YES);
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

@end

