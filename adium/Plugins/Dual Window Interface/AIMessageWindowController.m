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
#import "AIMessageTabViewItem.h"
#import "AIAdium.h"

#define	MESSAGE_WINDOW_NIB		@"MessageWindow"		//Filename of the message window nib
#define KEY_DUAL_MESSAGE_WINDOW_FRAME	@"Dual Message Window Frame"

// The tabbed window that contains messages

@interface AIMessageWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner interface:(id <AITabHoldingInterface>)inInterface;
- (void)dealloc;
- (void)tabViewDidChangeOrderOfTabViewItems:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (BOOL)shouldCascadeWindows;
@end

@implementation AIMessageWindowController

//Create a new message window controller
+ (AIMessageWindowController *)messageWindowControllerWithOwner:(id)inOwner interface:(id <AITabHoldingInterface>)inInterface
{
    return([[[self alloc] initWithWindowNibName:MESSAGE_WINDOW_NIB owner:inOwner interface:inInterface] autorelease]);
}

//Close the message window (closing the window does not unload it, it is just hidden)
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] orderOut:nil]; //Order out (as opposed to close)
    }
}


//Controller selection ------------------------------------------------------------------
//select a message controller
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

//Select the next message controller.
//If the current selection is last, NO is returned, and the selected tab is not changed.  Otherwise returns YES
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

//Select the previous message controller.
//If the current selection is first, NO is returned, and the selected tab is not changed.  Otherwise returns YES
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

//Select the first message controller
- (void)selectFirstController
{
    [tabView_messages selectTabViewItemAtIndex:0];
}

//Select the last message controller
- (void)selectLastController
{
    [tabView_messages selectTabViewItemAtIndex:[tabView_messages numberOfTabViewItems]-1 ];
}

//Returns the selected message controller
- (id <AIMessageView>)selectedMessageView
{
    return([[tabView_messages selectedTabViewItem] identifier]);
}



//Add/Remove/Access controllers --------------------------------------------------------------------
//add a message controller
- (void)addMessageViewController:(id <AIMessageView>)inController
{
    AIMessageTabViewItem	*tabViewItem;
    AIContactHandle		*handle;

    //Make sure our window is loaded
    [self window];
    
    //Setup the view
    tabViewItem = [[[AIMessageTabViewItem alloc] initWithIdentifier:inController] autorelease];
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

//remove a message controller
- (BOOL)removeMessageViewController:(id <AIMessageView>)inController
{
    NSTabViewItem	*tabViewItem;

    tabViewItem = [tabView_messages tabViewItemWithIdentifier:inController];
    if(tabViewItem){
        //Remove the controller
        [tabView_messages removeTabViewItem:tabViewItem];
        [messageViewArray removeObject:inController];
        [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:AIMessageWindow_ControllersChanged object:self userInfo:nil];
    }

    return([messageViewArray count] == 0); //Return YES if that was our last controller    
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





//Private -----------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner interface:(id <AITabHoldingInterface>)inInterface
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabViewDidChangeOrderOfTabViewItems:) name:AITabViewDidChangeOrderOfTabViewItemsNotification object:tabView_messages];
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    if([messageViewArray count]){ //Only close the window for real if it's empty
        //Save the window position
        [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                             forKey:KEY_DUAL_MESSAGE_WINDOW_FRAME
                                              group:PREF_GROUP_WINDOW_POSITIONS];
    }
    
    return(YES);
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

@end

