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

#import "AIContactListWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIStatusSelectionView.h"
#import "AISCLViewController.h"
#import "AISCLViewPlugin.h"

#define CONTACT_LIST_WINDOW_NIB				@"ContactListWindow"		//Filename of the contact list window nib
#define CONTACT_LIST_WINDOW_TRANSPARENT_NIB @"ContactListWindowTransparent" //Filename of the minimalist transparent version
#define CONTACT_LIST_TOOLBAR				@"ContactList"				//ID of the contact list toolbar
#define	KEY_DUAL_CONTACT_LIST_WINDOW_FRAME	@"Dual Contact List Frame 2"
#define TOOLBAR_CONTACT_LIST				@"ContactList"				//Toolbar identifier

#define EDGE_CATCH_X				10
#define EDGE_CATCH_Y				40
#define SCROLL_VIEW_PADDING_X		2
#define SCROLL_VIEW_PADDING_Y		2

#define PREF_GROUP_CONTACT_LIST		@"Contact List"
#define KEY_CLWH_WINDOW_POSITION	@"Contact Window Position"
#define KEY_CLWH_HIDE				@"Hide While in Background"

@interface AIContactListWindowController (PRIVATE)
- (id)initWithPlugin:(AISCLViewPlugin *)inPlugin;
- (void)contactSelectionChanged:(NSNotification *)notification;
- (void)contactListDesiredSizeChanged:(NSNotification *)notification;
- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (NSRect)_desiredWindowFrame;
- (void)_configureAutoResizing;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
@end

@implementation AIContactListWindowController

//Return a new contact list window controller
+ (AIContactListWindowController *)contactListWindowControllerWithPlugin:(AISCLViewPlugin *)inPlugin
{
    return([[[self alloc] initWithPlugin:inPlugin] autorelease]);
}

//Init
- (id)initWithPlugin:(AISCLViewPlugin *)inPlugin
{
	plugin = inPlugin;
	toolbarItems = nil;
	borderless = [[[[AIObject sharedAdiumInstance] preferenceController] preferenceForKey:KEY_SCL_BORDERLESS
																					group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];

    [super initWithWindowNibName:(borderless ? CONTACT_LIST_WINDOW_TRANSPARENT_NIB : CONTACT_LIST_WINDOW_NIB)];
	
    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
	//Watch for resolution and screen configuration changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(centerWindowOnMainScreenIfNeeded:) 
															   name:NSApplicationDidChangeScreenParametersNotification 
															 object:nil];
    return(self);
}

//Dealloc
- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	
	[toolbarItems release];

    [super dealloc];
}

//Setup the window after it had loaded
- (void)windowDidLoad
{
    NSString	*frameString;
    
    //Toolbar (can not be added to a borderless window)
    if(!borderless) [self _configureToolbar];
    
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
    
    //Restore the window position
    frameString = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME];
	if(frameString){
		NSRect		windowFrame = NSRectFromString(frameString);
		
		//Don't allow the window to shrink smaller than it's toolbar
		
		NSRect 		contentFrame = [NSWindow contentRectForFrameRect:windowFrame
														   styleMask:[[self window] styleMask]];
		
		if(contentFrame.size.height < [[self window] toolbarHeight]) windowFrame.size.height += [[self window] toolbarHeight] - contentFrame.size.height;
        
		[[self window] setFrame:windowFrame display:YES];
	}
	
	//Make sure our window is on a screen; if it isn't, center it on the main screen
	[self centerWindowOnMainScreenIfNeeded:nil];
	
    minWindowSize = [[self window] minSize];
	
    //Swap in the contact list view
    contactListViewController = [[AISCLViewController contactListViewController] retain];
    contactListView = [[contactListViewController contactListView] retain];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];
    [[self window] makeFirstResponder:contactListView];
	[scrollView_contactList setAndSizeDocumentView:contactListView];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contactListDesiredSizeChanged:)
												 name:AIViewDesiredSizeDidChangeNotification
											   object:contactListView];
    
	
    //Apply initial preference-based settings
    [self preferencesChanged:nil];
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
    
	//Save the window position
	[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
    //Tell the interface to unload our window
    [plugin contactListDidClose];
    
    return(YES);
}

//Preferences have changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST])){
		NSDictionary 	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
		int				windowPosition = [[prefDict objectForKey:KEY_CLWH_WINDOW_POSITION] intValue];
		int				level;
		
		switch(windowPosition){
			case 1: level = NSFloatingWindowLevel; break;
			case 2: level = kCGDesktopWindowLevel; break;
			default: level = NSNormalWindowLevel; break;
		}
		[[self window] setLevel:level];
		[[self window] setIgnoresExpose:(windowPosition == 2)]; //Ignore expose while on the desktop


		[[self window] setHidesOnDeactivate:[[prefDict objectForKey:KEY_CLWH_HIDE] boolValue]];
    }
	
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY])){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
		
		//Force auto-resizing on for borderless lists
		if(!borderless){
			autoResizeVertically = [[prefDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue];
			autoResizeHorizontally = [[prefDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];
		}else{
			autoResizeVertically = YES;
			autoResizeHorizontally = YES;
		}
		
        [self _configureAutoResizing];
    }

    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]){
		if([(NSString *)[[notification userInfo] objectForKey:@"Key"] isEqualToString:KEY_SCL_BORDERLESS]){
			[self retain];
			[[adium interfaceController] closeContactList:nil];
			[[adium interfaceController] showContactList:nil];
			[self autorelease];
		}
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
//    [interface containerDidBecomeActive:self];
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//Contact list sent back
- (void)windowDidResignKey:(NSNotification *)notification
{
//    [interface containerDidBecomeActive:nil];
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
				
				//Resize the window
				[[self window] setFrame:newFrame display:YES animate:NO];
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
	NSWindow    *theWindow = [self window];
	NSRect      currentFrame = [theWindow frame];
    NSRect		newFrame = currentFrame;
	
    if([contactListView conformsToProtocol:@protocol(AIAutoSizingView)]){
		NSScreen	*activeScreen;
		NSSize      contactViewPadding, desiredSize;
		NSRect      screenFrame, totalScreenFrame;

        //Get screen frame (We'll need to stay within it)
		activeScreen = [theWindow screen];
        if(!activeScreen) activeScreen = [[NSScreen screens] objectAtIndex:0];
        screenFrame = [activeScreen visibleFrame];
        totalScreenFrame = [activeScreen frame];
		
		//Remember the padding around the contact list view
		contactViewPadding.height = currentFrame.size.height - [scrollView_contactList frame].size.height;
		contactViewPadding.width = currentFrame.size.width - [scrollView_contactList frame].size.width;

        //Calculate desired width and height
		desiredSize = [(NSView<AIAutoSizingView> *)contactListView desiredSize];
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
		
        //If the window is near the right edge of the screen, keep it near that edge
        if(autoResizeHorizontally &&
		   (currentFrame.origin.x + currentFrame.size.width) + EDGE_CATCH_X > (screenFrame.origin.x + screenFrame.size.width)){

			newFrame.origin.x = currentFrame.origin.x + (currentFrame.size.width - newFrame.size.width);
			if((newFrame.origin.x + newFrame.size.width) < (screenFrame.origin.x + EDGE_CATCH_X)){
				newFrame.origin.x = screenFrame.origin.x - newFrame.size.width + EDGE_CATCH_X;
			}
		}
        
		//If the window is not near the bottom edge of the screen, keep its titlebar in place
		if(currentFrame.origin.y > screenFrame.origin.y + EDGE_CATCH_Y ||
		   currentFrame.origin.y + currentFrame.size.height + EDGE_CATCH_Y > screenFrame.origin.y + screenFrame.size.height){
			newFrame.origin.y += currentFrame.size.height - newFrame.size.height;
		}
		
	}
	
	return(newFrame);
}

- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification
{
	if (![[self window] screen]){
		[[self window] setFrameOrigin:[[NSScreen mainScreen] frame].origin];
		[[self window] center];
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
    return([NSArray arrayWithObjects:@"ShowPreferences",@"NewMessage",@"ShowInfo",nil]);
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
