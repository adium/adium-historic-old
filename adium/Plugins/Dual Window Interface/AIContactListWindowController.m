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

#import "AIContactListWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIStatusSelectionView.h"

#define CONTACT_LIST_WINDOW_NIB			@"ContactListWindow"		//Filename of the contact list window nib
#define CONTACT_LIST_TOOLBAR			@"ContactList"			//ID of the contact list toolbar
#define	KEY_DUAL_CONTACT_LIST_WINDOW_FRAME	@"Dual Contact List Frame"

#define EDGE_CATCH_X 			10
#define EDGE_CATCH_Y 			40
#define SCROLL_VIEW_PADDING_X		2
#define SCROLL_VIEW_PADDING_Y		2

#define PREF_GROUP_CONTACT_LIST			@"Contact List"
#define KEY_CLWH_ALWAYS_ON_TOP			@"Always on Top"
#define KEY_CLWH_HIDE				@"Hide While in Background"

@interface AIContactListWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName interface:(id <AIContainerInterface>)inInterface owner:(id)inOwner;
- (void)contactSelectionChanged:(NSNotification *)notification;
- (void)contactListDesiredSizeChanged:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (NSRect)_desiredWindowFrame;
- (void)_configureAutoResizing;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIContactListWindowController

//Return a new contact list window controller
+ (AIContactListWindowController *)contactListWindowControllerForInterface:(id <AIContainerInterface>)inInterface owner:(id)inOwner
{
    return([[[self alloc] initWithWindowNibName:CONTACT_LIST_WINDOW_NIB interface:inInterface owner:inOwner] autorelease]);
}

//Make this container active
- (void)makeActive:(id)sender
{
    [self showWindow:nil];
}

//Close this container
- (void)close:(id)sender
{
    //In response to windowShouldClose, the interface controller releases us.  At that point, noone would be retaining this instance of AIContactListWindowController, and we would be deallocated.  The call to [self window] will crash if we are deallocated.  A dirty, but functional fix is to temporarily retain ourself here.
    [self retain];
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
    [self release];
}


//Private ----------------------------------------------------------------
//init the contact list window controller
- (id)initWithWindowNibName:(NSString *)windowNibName interface:(id <AIContainerInterface>)inInterface owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    owner = [inOwner retain];
    interface = [inInterface retain];

    //Observe preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    return(self);
}

//dealloc
- (void)dealloc
{
    //Remove observers (general)
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [owner release];
    [interface release];
        
    [super dealloc];
}

//Preferences have changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST] == 0)){
	//Handle window ordering
	NSDictionary * prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
	if ([[prefDict objectForKey:KEY_CLWH_ALWAYS_ON_TOP] boolValue]) {
	    [[self window] setLevel:NSFloatingWindowLevel]; //always on top
	} else {
	    [[self window] setLevel:NSNormalWindowLevel]; //normal
	}
        
	[[self window] setHidesOnDeactivate:[[prefDict objectForKey:KEY_CLWH_HIDE] boolValue]];  //hides in background
    }

    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DUAL_WINDOW_INTERFACE] == 0)){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
        autoResizeVertically = [[prefDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue];
        autoResizeHorizontally = [[prefDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];

        [self _configureAutoResizing];
    }
}

//Called when the user selects a new contact object
- (void)contactSelectionChanged:(NSNotification *)notification
{
    AIListObject	*object = [[notification userInfo] objectForKey:@"Object"];

    //Configure our toolbar for the new object
    [toolbar_bottom configureForObjects:[NSDictionary dictionaryWithObjectsAndKeys:object,@"ContactObject",nil]];
}

//Configure auto-resizing
- (void)_configureAutoResizing
{
    //Hide the resize indicator if all sizing is being controlled programatically
    [[self window] setShowsResizeIndicator:!(autoResizeVertically && autoResizeHorizontally)];
    
    //Configure the maximum and minimum sizes
    NSRect  currentFrame = [[self window] frame];
    NSSize targetMin = minWindowSize;
    NSSize targetMax = NSMakeSize(10000, 10000);
    
    if (autoResizeHorizontally) {
        targetMin.width = currentFrame.size.width;
        targetMax.width = currentFrame.size.width;
    }
    if (autoResizeVertically) {
        targetMin.height = currentFrame.size.height;
        targetMax.height = currentFrame.size.height;
    }
    
    [[self window] setMinSize:targetMin];
    [[self window] setMaxSize:targetMax];
    
    //Update the size as necessary
    [self contactListDesiredSizeChanged:nil];
}

//Dynamically resize the contact list
- (void)contactListDesiredSizeChanged:(NSNotification *)notification
{
    if(autoResizeVertically || autoResizeHorizontally){
        NSRect	desiredFrame = [self _desiredWindowFrame];
        NSRect  newFrame = desiredFrame;
        NSRect  oldFrame = [[self window] frame];

        if (!NSEqualRects(oldFrame, newFrame)) {
            NSSize targetMin = minWindowSize;
            NSSize targetMax = NSMakeSize(10000, 10000);
            if (autoResizeHorizontally) {    
                targetMin.width = newFrame.size.width;
                targetMax.width = newFrame.size.width;
            } else {
                newFrame.size.width = oldFrame.size.width; //no horizontal resize so use old width
                newFrame.origin.x = oldFrame.origin.x;
            }
            
            if (autoResizeVertically) {
                targetMin.height = newFrame.size.height;  
                targetMax.height = newFrame.size.height;  
            } else {
                newFrame.size.height = oldFrame.size.height; //no vertical resize so use old height
                newFrame.origin.y = oldFrame.origin.y;
            }
                        
            //Resize the window (We animate only if the window is main)
            if([[self window] isMainWindow]){
                
                [scrollView_contactList setAutoHideScrollBar:NO]; //Prevent scrollbar from appearing during animation
                
                //Force the scrollbar to disappear if the target frame is such that it will not be desired
                //This prevents some odd flickering at the view and window sync up
                if (autoResizeVertically) {
                    //Hide the scrollbar if the new frame is smaller than the maximum allowable height
                    if (newFrame.size.height < [[[self window] screen] visibleFrame].size.height) { 
                        [scrollView_contactList setHasVerticalScroller:NO]; 
                    }
                } else {
                    //Hide the scrollbar if the required frame is smaller than the user-set one, as a scrollbar will not be needed
                    if (desiredFrame.size.height < newFrame.size.height) {
                        [scrollView_contactList setHasVerticalScroller:NO]; 
                    }
                }
                
                [[self window] setFrame:newFrame display:YES animate:YES];
                [scrollView_contactList setAutoHideScrollBar:YES];
            }else{
                [[self window] setFrame:newFrame display:YES animate:NO];
            }
            
        
            [[self window] setMinSize:targetMin];
            [[self window] setMaxSize:targetMax];
        }
    }
}

//
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return([self _desiredWindowFrame]);
}

//
- (NSRect)_desiredWindowFrame
{
    NSRect	newFrame;

    if([contactListView conformsToProtocol:@protocol(AIAutoSizingView)]){
        NSRect	currentFrame = [[self window] frame];
        NSSize	desiredSize = [(NSView<AIAutoSizingView> *)contactListView desiredSize];
        NSRect	screenFrame = [[[self window] screen] visibleFrame];

        //Calculate desired width and height
        if(autoResizeHorizontally){
            newFrame.size.width = desiredSize.width + contactViewPadding.width + SCROLL_VIEW_PADDING_X;
        }else{
            newFrame.size.width = currentFrame.size.width;
        }
        newFrame.size.height = desiredSize.height + contactViewPadding.height + SCROLL_VIEW_PADDING_Y;
        
        //Adjust the Y Origin
        if(newFrame.size.height > screenFrame.size.height){
            newFrame.size.height = screenFrame.size.height; //Max Height
            if(autoResizeHorizontally){
                newFrame.size.width += 16; //Factor scrollbar into width
            }
        }
        if((currentFrame.origin.y - EDGE_CATCH_Y > screenFrame.origin.y) || ((currentFrame.origin.y + currentFrame.size.height) + EDGE_CATCH_Y > (screenFrame.origin.y + screenFrame.size.height))){
            newFrame.origin.y = currentFrame.origin.y + (currentFrame.size.height - newFrame.size.height); //Expand down
        }else{
            newFrame.origin.y = currentFrame.origin.y; //Expand up
        }

        //Adjust the X Origin
        if(autoResizeHorizontally){
            if((currentFrame.origin.x + currentFrame.size.width) + EDGE_CATCH_X > (screenFrame.origin.x + screenFrame.size.width)){
                newFrame.origin.x = currentFrame.origin.x + (currentFrame.size.width - newFrame.size.width); //Expand Left
            }else{
                newFrame.origin.x = currentFrame.origin.x; //Expand Right
            }
        }else{
            newFrame.origin.x = currentFrame.origin.x;
        }
    }

    return(newFrame);
}

//Setup the window after it had loaded
- (void)windowDidLoad
{
    NSString	*savedFrame;
    NSRect	contactListFrame;
    
    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }

    //Remember the mininum size set for our list within interface builder
    minWindowSize = [[self window] minSize];
    
    //Add the status selection view
/*    contactListFrame = [scrollView_contactList frame];
    view_statusSelection = [[[AIStatusSelectionView alloc] initWithFrame:NSMakeRect(contactListFrame.origin.x, contactListFrame.origin.y + contactListFrame.size.height - 16 + 1, contactListFrame.size.width, 16) owner:owner] autorelease];
    
    [view_statusSelection setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin | NSViewWidthSizable)];
    [[[self window] contentView] addSubview:view_statusSelection];

    [scrollView_contactList setFrameSize:NSMakeSize(contactListFrame.size.width, contactListFrame.size.height - 16)];
*/
    //Swap in the contact list view
    contactListViewController = [[[owner interfaceController] contactListViewController] retain];
    contactListView = [[contactListViewController contactListView] retain];
    [scrollView_contactList setAndSizeDocumentView:contactListView];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];
    [[self window] makeFirstResponder:contactListView];
    
    //Grrr
    //[scrollView_contactList setHasVerticalScroller:YES];
    //[[scrollView_contactList verticalScroller] setControlSize:NSSmallControlSize];

    //Remember how much padding we have around the contact list view, and observe desired size changes
    contactViewPadding = NSMakeSize([[self window] frame].size.width - [scrollView_contactList frame].size.width,
                                    [[self window] frame].size.height - [scrollView_contactList frame].size.height);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactListDesiredSizeChanged:) name:AIViewDesiredSizeDidChangeNotification object:contactListView];
    
    //Register for the selection notification
    [[owner notificationCenter] addObserver:self selector:@selector(contactSelectionChanged:) name:Interface_ContactSelectionChanged object:contactListView];

    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];

    //
    [toolbar_bottom setIdentifier:CONTACT_LIST_TOOLBAR];

    //Apply initial preference-based settings
    [self preferencesChanged:nil];

    //Tell the interface to open our window
    [interface containerDidOpen:self];
}

//Close the contact list window
- (BOOL)windowShouldClose:(id)sender
{
    //Before closing a container, we must set active to nil
    [interface containerDidBecomeActive:nil];

    //Stop observing
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Close the contact list view
    [contactListViewController release];
    [contactListView release];
    
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];

    //Tell the interface to unload our window
    [interface containerDidClose:self];
    
    return(YES);
}

//
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//
- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [interface containerDidBecomeActive:self];
    [[owner notificationCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//
- (void)windowDidResignMain:(NSNotification *)notification
{
    [interface containerDidBecomeActive:nil];
    [[owner notificationCenter] postNotificationName:Interface_ContactListDidResignMain object:self];
}

@end
