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

#import "AIMessageWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"

#define AIMessageTabDragCompleteNotification    @"AIMessageTabDragCompleteNotification"
#define	MESSAGE_WINDOW_NIB                      @"MessageWindow"		//Filename of the message window nib
#define TAB_BAR_FPS                             20.0
#define TAB_BAR_STEP                            0.6

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
- (void)updateTabBarVisibilityAndAnimate:(BOOL)animate;
- (void)_resizeTabBarTimer:(NSTimer *)inTimer;
- (BOOL)_resizeTabBarAbsolute:(BOOL)absolute;
- (void)_supressTabBarHiding:(BOOL)supress;
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
    [self addTabViewItemContainer:inTabViewItem atIndex:-1];
}

//Add a tab view item container (without changing the current selection)
- (void)addTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem atIndex:(int)index
{    
    NSString	*savedFrame;
    
    [self window]; //Ensure our window has loaded
    if([tabView_messages numberOfTabViewItems] == 0) {
        //Restore the window position for the object about to have its chat added as the first in this window
        savedFrame = [[owner preferenceController] preferenceForKey:KEY_DUAL_MESSAGE_WINDOW_FRAME
                                                              group:PREF_GROUP_WINDOW_POSITIONS
                                                             object:[[[(AIMessageTabViewItem *)inTabViewItem messageViewController] chat] listObject]];

        if(savedFrame){
            [[self window] setFrameFromString:savedFrame];
        }   
    }
    if (index == -1) {
        [tabView_messages addTabViewItem:inTabViewItem];    //Add the tab
    } else {
        [tabView_messages insertTabViewItem:inTabViewItem atIndex:index]; //Add the tab at the specified index
    }
    
    [interface containerDidOpen:inTabViewItem]; //Let the interface know it opened
    
    [self showWindow:nil]; //Show the window
}

//Remove a tab view item container
- (void)removeTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem
{
    //Before closing a container, we must set active to nil
    [interface containerDidBecomeActive:nil];

    //If the tab is selected, select the next tab.
    if(inTabViewItem == [tabView_messages selectedTabViewItem]){
	[tabView_messages selectNextTabViewItem:nil];
    }

    //Remove the tab and let the interface know a container closed
    [tabView_messages removeTabViewItem:inTabViewItem];
    [interface containerDidClose:inTabViewItem];

    //If that was our last container, save the position for its contact
    if([tabView_messages numberOfTabViewItems] == 0){
        //Save the window position
        [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                             forKey:KEY_DUAL_MESSAGE_WINDOW_FRAME
                                            group:PREF_GROUP_WINDOW_POSITIONS
                                             object:[[[(AIMessageTabViewItem *)inTabViewItem messageViewController] chat] listObject]];

        //close the window (unless we're already closing)
        if(!windowIsClosing){
            [self closeWindow:nil];
        }
    }
}

//Private -----------------------------------------------------------------------------
//init
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner interface:(AIDualWindowInterfacePlugin<AIContainerInterface> *)inInterface
{
    NSParameterAssert(windowNibName != nil && [windowNibName length] != 0);

    owner = [inOwner retain];
    interface = [inInterface retain];
    windowIsClosing = NO;
    tabIsShowing = YES;
    supressHiding = NO;
    
    [[owner notificationCenter] addObserver:self selector:@selector(messageTabDragCompleteNotification:) name:AIMessageTabDragCompleteNotification object:nil];
    
    //Load our window
    [super initWithWindowNibName:windowNibName owner:self];
    [self window];	

    //Prefs
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

    //register as a drag observer:
    [[self window] registerForDraggedTypes:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];

    return(self);
}

//dealloc
- (void)dealloc
{
    //During a drag, the tabs will not get deallocated on occasion, so we must make sure that we are no longer set as their delegate
    [tabView_customTabs setDelegate:nil];
        
    [owner release];
    [interface release];

    [super dealloc];
}

//Setup our window before it is displayed
- (void)windowDidLoad
{
    //Remember the initial tab height
    tabHeight = [tabView_customTabs frame].size.height;

    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];

    //Remove any tabs from our tab view, it needs to start out empty
    while([tabView_messages numberOfTabViewItems] > 0){
        [tabView_messages removeTabViewItem:[tabView_messages tabViewItemAtIndex:0]];
    }

    [[self window] setBottomCornerRounded:NO]; //Sneaky lil private method
    [[self window] useOptimizedDrawing:YES]; //should be set to YES unless subviews overlap... we should be good to go.  check the docs on this for more info.
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
    [interface containerDidBecomeActive:nil];

    return(YES);
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
	[tabView_customTabs setAllowsInactiveTabClosing:[[preferenceDict objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE] boolValue]];
	
        [self updateTabBarVisibilityAndAnimate:(notification != nil)];
    }
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
- (void)customTabViewDidChangeNumberOfTabViewItems:(AICustomTabsView *)tabView
{       
    [self updateTabBarVisibilityAndAnimate:([[tabView window] isVisible])];
    [self _updateWindowTitle];
}

//
- (void)customTabViewDidChangeOrderOfTabViewItems:(AICustomTabsView *)TabView
{
    //Refresh interface menus
    [interface containerOrderDidChange];
}

- (void)customTabView:(AICustomTabsView *)tabView didMoveTabViewItem:(NSTabViewItem *)tabViewItem toCustomTabView:(AICustomTabsView *)destTabView index:(int)index screenPoint:(NSPoint)point
{
    [[owner notificationCenter] postNotificationName:AIMessageTabDragCompleteNotification object:nil];

    [interface transferMessageTabContainer:tabViewItem
                                  toWindow:[[destTabView window] windowController]
                                   atIndex:index
                         withTabBarAtPoint:point];
}

//
- (void)customTabView:(AICustomTabsView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
    //Close the message tab
    [[owner interfaceController] closeChat:[[(AIMessageTabViewItem *)tabViewItem messageViewController] chat]];
}

//
- (NSArray *)customTabViewAcceptableDragTypes:(AICustomTabsView *)tabView
{
    return([NSArray arrayWithObject:NSRTFPboardType]);
}

//
- (BOOL)customTabView:(AICustomTabsView *)tabView didAcceptDragPasteboard:(NSPasteboard *)pasteboard onTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSString    *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:NSRTFPboardType,TAB_CELL_IDENTIFIER,nil]];

    if([type isEqualToString:NSRTFPboardType]){ //got RTF data
        [[(AIMessageTabViewItem *)tabViewItem messageViewController] addToTextEntryView:[NSAttributedString stringWithData:[pasteboard dataForType:NSRTFPboardType]]];
        return(YES);
    }
    
    return(NO);
}



//Tab Bar Visibility --------------------------------------------------------------------------------------------------
//Update the visibility of our tab bar (Tab bar is visible if autohide is off, or if there are 2 or more tabs present)
- (void)updateTabBarVisibilityAndAnimate:(BOOL)animate
{
    if(tabView_messages != nil){    //Ignore if our tabs haven't loaded yet
        BOOL    shouldShowTabs = (supressHiding || !autohide_tabBar || ([tabView_customTabs numberOfTabViewItems] > 1) );

        if(shouldShowTabs != tabIsShowing){
            tabIsShowing = shouldShowTabs;
            
            if(animate){
                [self _resizeTabBarTimer:nil];
            }else{
                [self _resizeTabBarAbsolute:YES];
            }
        }
    }    
}

//Smoothly resize the tab bar (Calls itself with a timer until the tabbar is correctly positioned)
- (void)_resizeTabBarTimer:(NSTimer *)inTimer
{
    //If the tab bar isn't at the right height, we set ourself to adjust it again
    if(inTimer == nil || ![self _resizeTabBarAbsolute:NO]){ //Do nothing when called from outside a timer.  This prevents the tabs from jumping when set from show to hide, and back rapidly.
        [NSTimer scheduledTimerWithTimeInterval:(1.0/TAB_BAR_FPS) target:self selector:@selector(_resizeTabBarTimer:) userInfo:nil repeats:NO];
    }
}

//Resize the tab bar towards it's desired height
- (BOOL)_resizeTabBarAbsolute:(BOOL)absolute
{   
    NSSize              tabSize = [tabView_customTabs frame].size;
    double              destHeight;
    NSRect              newFrame;

    //Determine the desired height
    destHeight = (tabIsShowing ? tabHeight : 0);
    
    //Move the tab view's height towards this desired height
    int distance = (destHeight - tabSize.height) * TAB_BAR_STEP;
    if(absolute || (distance > -1 && distance < 1)) distance = destHeight - tabSize.height;

    tabSize.height += distance;
    [tabView_customTabs setFrameSize:tabSize];
    
    //Adjust other views
    newFrame = [tabView_messages frame];
    newFrame.size.height -= distance;
    newFrame.origin.y += distance;
    [tabView_messages setFrame:newFrame];
    [[self window] display];
    
    //Return YES when the desired height is reached
    return(tabSize.height == destHeight);
}


//Tab Bar Hiding Suppression ----------------------------------------------------------------------------------------------------
//Make sure auto-hide suppression is off after a drag completes
- (void)messageTabDragCompleteNotification:(NSNotification *)notification
{
    [self _supressTabBarHiding:NO];
}

//Drag entered, enable suppression
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSString 		*type = [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];
    NSDragOperation	operation = NSDragOperationNone;

    if(sender == nil || type){
        //Show the tab bar
        [self _supressTabBarHiding:YES];
        
        //Bring our window to the front
        if(![[self window] isKeyWindow]){
            [[self window] makeKeyAndOrderFront:nil];
        }
        
        operation = NSDragOperationPrivate;
    }

    return (operation);
}

//Drag exited, disable suppression
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    NSString 		*type = [[sender draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];

    if(sender == nil || type){
        //Hide the tab bar
        [self _supressTabBarHiding:NO];
    }
}

//Temporarily suppress bar hiding
- (void)_supressTabBarHiding:(BOOL)supress
{
    supressHiding = supress;
    [self updateTabBarVisibilityAndAnimate:YES];
}

@end

