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

#define CONTACT_LIST_WINDOW_NIB				@"ContactListWindow"		//Filename of the contact list window nib
#define CONTACT_LIST_WINDOW_TRANSPARENT_NIB @"ContactListWindowTransparent" //Filename of the minimalist transparent version
#define CONTACT_LIST_TOOLBAR				@"ContactList"				//ID of the contact list toolbar
#define	KEY_DUAL_CONTACT_LIST_WINDOW_FRAME	@"Dual Contact List Frame"
#define TOOLBAR_CONTACT_LIST				@"ContactList"				//Toolbar identifier

#define EDGE_CATCH_X				10
#define EDGE_CATCH_Y				40
#define SCROLL_VIEW_PADDING_X		2
#define SCROLL_VIEW_PADDING_Y		2

#define PREF_GROUP_CONTACT_LIST		@"Contact List"
#define KEY_CLWH_ALWAYS_ON_TOP		@"Always on Top"
#define KEY_CLWH_HIDE				@"Hide While in Background"

@interface AIContactListWindowController (PRIVATE)
- (id)initWithInterface:(id <AIContainerInterface>)inInterface;
- (void)contactSelectionChanged:(NSNotification *)notification;
- (void)contactListDesiredSizeChanged:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (NSRect)_desiredWindowFrame;
- (void)_configureAutoResizing;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
@end

@implementation AIContactListWindowController

//Return a new contact list window controller
+ (AIContactListWindowController *)contactListWindowControllerForInterface:(id <AIContainerInterface>)inInterface
{
    return([[[self alloc] initWithInterface:inInterface] autorelease]);
}

//Init
- (id)initWithInterface:(id <AIContainerInterface>)inInterface
{
    interface = [inInterface retain];
	toolbarItems = nil;
    borderless = [[[[AIObject sharedAdiumInstance] preferenceController] preferenceForKey:KEY_SCL_BORDERLESS
																					group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];

    [super initWithWindowNibName:(borderless ? CONTACT_LIST_WINDOW_TRANSPARENT_NIB : CONTACT_LIST_WINDOW_NIB)];
	
    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    return(self);
}

//Dealloc
- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [interface release];
	[toolbarItems release];

    [super dealloc];
}

//Setup the window after it had loaded
- (void)windowDidLoad
{
    NSString	*savedFrame;
    
    //Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME];
    if(savedFrame) [[self window] setFrame:NSRectFromString(savedFrame) display:YES];            
	topLeftAnchorPoint.x = NSMinX([[self window] frame]);
	topLeftAnchorPoint.y = NSMaxY([[self window] frame]);
    minWindowSize = [[self window] minSize];
    
    //Swap in the contact list view
    contactListViewController = [[[adium interfaceController] contactListViewController] retain];
    contactListView = [[contactListViewController contactListView] retain];
    [scrollView_contactList setAndSizeDocumentView:contactListView];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];
    [[self window] makeFirstResponder:contactListView];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contactListDesiredSizeChanged:)
												 name:AIViewDesiredSizeDidChangeNotification
											   object:contactListView];
    
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
    
    //Toolbar (can not be added to a borderless window)
    if(!borderless) [self _configureToolbar];
    
    //Apply initial preference-based settings
    [self preferencesChanged:nil];
    
    //Tell the interface to open our window
    [interface containerDidOpen:self];
}

//Close the contact list window
- (BOOL)windowShouldClose:(id)sender
{
    //Stop observing
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Close the contact list view
    [contactListViewController release];
    [contactListView release];
    
	//If we are auto-resizing, force the top-left point to topLeftAnchorPoint, so this value will be loaded next launch
	if(autoResizeVertically){
		NSRect windowFrame = [[self window] frame];
		windowFrame.origin.y = topLeftAnchorPoint.y - windowFrame.size.height;
		[[self window] setFrame:windowFrame display:NO];
	}
	[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
    //Tell the interface to unload our window
    [interface containerDidClose:self];
    
    return(YES);
}

//Preferences have changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST] == 0)){
		NSDictionary 	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
		BOOL			alwaysOnTop = [[prefDict objectForKey:KEY_CLWH_ALWAYS_ON_TOP] boolValue];
		
		[[self window] setLevel:(alwaysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel)];
		[[self window] setHidesOnDeactivate:[[prefDict objectForKey:KEY_CLWH_HIDE] boolValue]];
    }
	
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DUAL_WINDOW_INTERFACE] == 0)){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		
        autoResizeVertically = [[prefDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue];
        autoResizeHorizontally = [[prefDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];
		
        [self _configureAutoResizing];
    }
}


//Interface Container --------------------------------------------------------------------------------------------------
#pragma mark Interface Container
//Make this container active
- (void)makeActive:(id)sender
{
    [self showWindow:nil];
}

//Close this container
- (void)close:(id)sender
{
    //In response to windowShouldClose, the interface controller releases us.  At that point, no one would be retaining
	//this instance of AIContactListWindowController, and we would be deallocated.  The call to [self window] will
	//crash if we are deallocated.  A dirty, but functional fix is to temporarily retain ourself here.
    [self retain];
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
    [self release];
}

//Contact list brought to front
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [interface containerDidBecomeActive:self];
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//Contact list sent back
- (void)windowDidResignKey:(NSNotification *)notification
{
    [interface containerDidBecomeActive:nil];
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidResignMain object:self];
}


//Resizing And Positioning ---------------------------------------------------------------------------------------------
#pragma mark Resizing And Positioning
//Configure auto-resizing
- (void)_configureAutoResizing
{
    //Hide the resize indicator if all sizing is being controlled programatically
    [[self window] setShowsResizeIndicator:!(autoResizeVertically && autoResizeHorizontally)];
    
    //Configure the maximum and minimum sizes
    NSRect  currentFrame = [[self window] frame];
    NSSize targetMin = minWindowSize;
    NSSize targetMax = NSMakeSize(10000, 10000);
    
    if(autoResizeHorizontally){
        targetMin.width = currentFrame.size.width;
        targetMax.width = currentFrame.size.width;
    }
    if(autoResizeVertically){
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
        if((desiredFrame.size.width != 0) && (desiredFrame.size.height != 0)){
			NSRect  newFrame = desiredFrame;
			NSRect  oldFrame = [[self window] frame];
			
			if(!NSEqualRects(oldFrame, newFrame)){
				NSSize targetMin = minWindowSize;
				NSSize targetMax = NSMakeSize(10000, 10000);
				if(autoResizeHorizontally) {    
					targetMin.width = newFrame.size.width;
					targetMax.width = newFrame.size.width;
				}else{
					newFrame.size.width = oldFrame.size.width; //no horizontal resize so use old width
					newFrame.origin.x = oldFrame.origin.x;
				}
				
				if(autoResizeVertically){
					targetMin.height = newFrame.size.height;  
					targetMax.height = newFrame.size.height;  
				}else{
					newFrame.size.height = oldFrame.size.height; //no vertical resize so use old height
					newFrame.origin.y = oldFrame.origin.y;
				}
				
#warning Evan: I disabled contact list resizing animation. IMO, the animation does not look better and is much slower.
				//Resize the window
				[[self window] setFrame:newFrame display:YES animate:NO];
				
				/*
				//Resize the window (We animate only if the window is main)
				if([[self window] isMainWindow] && [NSApp isOnPantherOrBetter]){
					[scrollView_contactList setAutoHideScrollBar:NO]; //Prevent scrollbar from appearing during animation
					
					//Force the scrollbar to disappear if the target frame is such that it will not be desired
					//This prevents some odd flickering as the view and window sync up
					if(autoResizeVertically){
						//Hide the scrollbar if the new frame is smaller than the maximum allowable height
						if(newFrame.size.height < [[[self window] screen] visibleFrame].size.height){ 
							[scrollView_contactList setHasVerticalScroller:NO]; 
						}
					}else{
						//Hide the scrollbar if the required frame is smaller than the user-set one, as a scrollbar will not be needed
						if(desiredFrame.size.height < newFrame.size.height){
							[scrollView_contactList setHasVerticalScroller:NO]; 
						}
					}
					
					[[self window] setFrame:newFrame display:YES animate:YES];
					[scrollView_contactList setAutoHideScrollBar:YES];
					
				}else{
					[[self window] setFrame:newFrame display:YES animate:NO];
					
				}
				 */
				
				[[self window] setMinSize:targetMin];
				[[self window] setMaxSize:targetMax];
			}
		}
    }
}

//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return([self _desiredWindowFrame]);
}

//Desired frame of our window
- (NSRect)_desiredWindowFrame
{
    NSRect	newFrame;
	
    if([contactListView conformsToProtocol:@protocol(AIAutoSizingView)]){
		NSSize      contactViewPadding;
        NSWindow    *theWindow = [self window];
        NSRect      currentFrame = [theWindow frame];
        NSSize      desiredSize = [(NSView<AIAutoSizingView> *)contactListView desiredSize];
        NSScreen     *activeScreen = [theWindow screen];
        if (!activeScreen)
            activeScreen = [[NSScreen screens] objectAtIndex:0];
        NSRect      screenFrame = [activeScreen visibleFrame];
        NSRect      totalScreenFrame = [activeScreen frame];
        
		//Keep track of padding around the contact view
		contactViewPadding.height = currentFrame.size.height - [scrollView_contactList frame].size.height;
		contactViewPadding.width = currentFrame.size.width - [scrollView_contactList frame].size.width;
		
        //Calculate desired width and height
        if(autoResizeHorizontally){
            newFrame.size.width = desiredSize.width + contactViewPadding.width + SCROLL_VIEW_PADDING_X;
        }else{
            newFrame.size.width = currentFrame.size.width;
        }
        newFrame.size.height = desiredSize.height + contactViewPadding.height + SCROLL_VIEW_PADDING_Y;
        
        if(newFrame.size.height > screenFrame.size.height){
            newFrame.size.height = screenFrame.size.height;
            if(autoResizeHorizontally){
                newFrame.size.width += 16; //Factor scrollbar into width
            }
        }
        
        //Adjust the X Origin
        if(autoResizeHorizontally){
            if((currentFrame.origin.x + currentFrame.size.width) + EDGE_CATCH_X > (screenFrame.origin.x + screenFrame.size.width)){
                newFrame.origin.x = currentFrame.origin.x + (currentFrame.size.width - newFrame.size.width); //Expand Left
                if((newFrame.origin.x + newFrame.size.width) < (screenFrame.origin.x + EDGE_CATCH_X)){
                   newFrame.origin.x = screenFrame.origin.x - newFrame.size.width + EDGE_CATCH_X;
                }
            }else{
                newFrame.origin.x = currentFrame.origin.x; //Expand Right
            }
        }else{
            newFrame.origin.x = currentFrame.origin.x;
        }
        
        //Adjust the Y Origin: Maintain the topLeftAnchorPoint corner if possible
        BOOL useTotalScreenFrame = ((newFrame.origin.x < EDGE_CATCH_X) || (newFrame.origin.x+newFrame.size.width) > (screenFrame.size.width-EDGE_CATCH_X)) && (screenFrame.size.width == totalScreenFrame.size.width);
        float screenOriginY;
        
        //Use the full screen if the x origin is along the edges and the dock is at the bottom; otherwise use the system-provided screen frame which does not include the dock and menubar
		screenOriginY = (useTotalScreenFrame ? totalScreenFrame.origin.y : screenFrame.origin.y);
		newFrame.origin.y = topLeftAnchorPoint.y - newFrame.size.height;
		if(newFrame.origin.y < screenOriginY){
			newFrame.origin.y = screenOriginY;
		}
	}
	
	return(newFrame);
}

//Remember the top-left anchor point when user moves the window.
- (void)windowDidMove:(NSNotification *)aNotification{
	if(autoResizeVertically){
		topLeftAnchorPoint.x = NSMinX([[self window] frame]);
		topLeftAnchorPoint.y = NSMaxY([[self window] frame]);
	}
}

//Prevent the system from altering our window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}


//Toolbar --------------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Install our toolbar
- (void)_configureToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_CONTACT_LIST] autorelease];

    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setVisible:NO];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];

    //
    toolbarItems = [[[adium toolbarController] toolbarItemsForToolbarTypes:[NSArray arrayWithObjects:@"General", @"ListObject", nil]] retain];
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return([NSArray arrayWithObjects:@"EditContactList",@"ShowInfo",nil]);
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
