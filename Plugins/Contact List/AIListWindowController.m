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

#import "AIListWindowController.h"
#import "AIStatusSelectionView.h"

#import "AIListOutlineView.h"

#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"


#define CONTACT_LIST_WINDOW_NIB				@"ContactListWindow"		//Filename of the contact list window nib
#define CONTACT_LIST_WINDOW_TRANSPARENT_NIB @"ContactListWindowTransparent" //Filename of the minimalist transparent version
#define CONTACT_LIST_TOOLBAR				@"ContactList"				//ID of the contact list toolbar
#define	KEY_DUAL_CONTACT_LIST_WINDOW_FRAME	@"Dual Contact List Frame 2"

#define PREF_GROUP_CONTACT_LIST		@"Contact List"
#define KEY_CLWH_WINDOW_POSITION	@"Contact Window Position"
#define KEY_CLWH_HIDE				@"Hide While in Background"

#define TOOL_TIP_CHECK_INTERVAL				45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY						25.0	//Number of check intervals of no movement before a tip is displayed

#define MAX_DISCLOSURE_HEIGHT				13		//Max height/width for our disclosure triangles

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

#define PREF_GROUP_CONTACT_STATUS_COLORING	@"Contact Status Coloring"

@interface AIListWindowController (PRIVATE)
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (void)_configureAutoResizing;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
@end

@implementation AIListWindowController

//Return a new contact list window controller
+ (AIListWindowController *)listWindowController
{
    return([[[self alloc] init] autorelease]);
}

//Init
- (id)init
{	
    [super initWithWindowNibName:[self nibName]];
    return(self);
}

- (void)dealloc
{
	[contactListController release];
	[super dealloc];
}

//Our window nib name
- (NSString *)nibName
{
    return(@"");    
}

//
- (NSString *)adiumFrameAutosaveName
{
	return(KEY_DUAL_CONTACT_LIST_WINDOW_FRAME);
}

//Setup the window after it has loaded
- (void)windowDidLoad
{
	[super windowDidLoad];

	contactListController = [[AIListController alloc] initWithContactListView:contactListView
																 inScrollView:scrollView_contactList 
																	 delegate:self];
	
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];

	minWindowSize = [[self window] minSize];
	[contactListController setMinWindowSize:minWindowSize];
	    
    //Watch for resolution and screen configuration changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(screenParametersChanged:) 
															   name:NSApplicationDidChangeScreenParametersNotification 
															 object:nil];

    //Observe preference changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
    [self preferencesChanged:nil];
}

//Close the contact list window
- (BOOL)windowShouldClose:(id)sender
{
	[super windowShouldClose:sender];
	
    //Stop observing
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

    //Tell the interface to unload our window
	[[adium notificationCenter] postNotificationName:Interface_ContactListDidClose object:self];

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
	
//    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY])){
//        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
//		
//		//Force auto-resizing on for borderless lists
//		if(!borderless){
//			autoResizeVertically = [[prefDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue];
//			autoResizeHorizontally = [[prefDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];
//		}else{
//			autoResizeVertically = YES;
//			autoResizeHorizontally = YES;
//		}
//		
//        [self _configureAutoResizing];
//    }

    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]){
		if([(NSString *)[[notification userInfo] objectForKey:@"Key"] isEqualToString:KEY_SCL_BORDERLESS]){
			[self retain];
			[[adium interfaceController] closeContactList:nil];
			[[adium interfaceController] showContactList:nil];
			[self autorelease];
		}
	}

	//Layout ------------
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_LIST_LAYOUT])){
        NSDictionary	*layoutDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
		NSDictionary	*themeDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_THEME];
		int				windowStyle = [[layoutDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
		BOOL			autoResizeVertically = [[layoutDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue];
		BOOL			autoResizeHorizontally = [[layoutDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
		
		int				forcedWindowWidth, maxWindowWidth;
		
		//User icon cache size
		int iconSize = [[layoutDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue];
		[AIUserIcons setListUserIconSize:NSMakeSize(iconSize,iconSize)];

		
		if (autoResizeHorizontally){
			//If autosizing, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the maximum width; no forced width.
			maxWindowWidth = [[layoutDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue];
			forcedWindowWidth = -1;
		}else{
			if (windowStyle == WINDOW_STYLE_STANDARD/* || windowStyle == WINDOW_STYLE_BORDERLESS*/){
				//In the non-transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH has no meaning
				maxWindowWidth = 10000;
				forcedWindowWidth = -1;
			}else{
				//In the transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the width of the window
				forcedWindowWidth = [[layoutDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue];
				maxWindowWidth = forcedWindowWidth;
			}
		}
		
		//Show the resize indicator if either or both of the autoresizing options is NO
		[[self window] setShowsResizeIndicator:!(autoResizeVertically && autoResizeHorizontally)];
		
		/*
		 Reset the minimum and maximum sizes in case [self contactListDesiredSizeChanged:nil]; doesn't cause a sizing change
		 (and therefore the min and max sizes aren't set there).
		 */
							  
		NSSize	thisMinimumSize = minWindowSize;
		NSSize	thisMaximumSize = NSMakeSize(maxWindowWidth, 10000);
		NSRect	currentFrame = [[self window] frame];
	
		if (forcedWindowWidth != -1){
			/*
			 If we have a forced width but we are doing no autoresizing, set our frame now so we don't have t be doing checks every time
			contactListDesiredSizeChanged is called.
			 */
			
			if(!(autoResizeVertically || autoResizeHorizontally)){
				thisMinimumSize.width = forcedWindowWidth;
				
				[[self window] setFrame:NSMakeRect(currentFrame.origin.x,currentFrame.origin.y,forcedWindowWidth,currentFrame.size.height) 
								display:YES
								animate:NO];
			}
		}
		
		//If vertically resizing, make the minimum and maximum heights the current height
		if (autoResizeVertically){
			thisMinimumSize.height = currentFrame.size.height;
			thisMaximumSize.height = currentFrame.size.height;
		}

		//If horizontally resizing, make the minimum and maximum widths the current width
		if (autoResizeHorizontally){
			thisMinimumSize.width = currentFrame.size.width;
			thisMaximumSize.width = currentFrame.size.width;			
		}
				
		[[self window] setMinSize:thisMinimumSize];
		[[self window] setMaxSize:thisMaximumSize];

		[contactListController setAutoresizeHorizontally:autoResizeHorizontally];
		[contactListController setAutoresizeVertically:autoResizeVertically];
		[contactListController setForcedWindowWidth:forcedWindowWidth];
		[contactListController setMaxWindowWidth:maxWindowWidth];
		
		[contactListController contactListDesiredSizeChanged:nil];


		
		[contactListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];
		[contactListController updateTransparencyFromLayoutDict:layoutDict themeDict:themeDict];

		[contactListController contactListDesiredSizeChanged];
	}
	
	//Theme
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_LIST_THEME])){
        NSDictionary	*themeDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_THEME];
		NSDictionary	*layoutDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];

		NSString		*imagePath = [themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH];
		
		//Background Image
		if(imagePath && [imagePath length] && [[themeDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED] boolValue]){
			[contactListView setBackgroundImage:[[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease]];
		}else{
			[contactListView setBackgroundImage:nil];
		}
		
		//Background
#warning only a temporary solution
//		[contactListController updateCellRelatedThemePreferencesFromDict:themeDict];
		[contactListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];
		[contactListController updateTransparencyFromLayoutDict:layoutDict themeDict:themeDict];
	}
}


//- (float)backgroundAlpha
//{
//#warning hmm, need?
//	if([[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE
//												 group:PREF_GROUP_LIST_LAYOUT] intValue] != WINDOW_STYLE_MOCKIE){
//		return([[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY
//														 group:PREF_GROUP_LIST_LAYOUT] floatValue]);
//	}else{
//		return(0.0);
//	}
//}
//

- (IBAction)performDefaultActionOnSelectedObject:(AIListObject *)selectedObject sender:(NSOutlineView *)sender
{	
    if([selectedObject isKindOfClass:[AIListGroup class]]){
        //Expand or collapse the group
        if([sender isItemExpanded:selectedObject]){
            [sender collapseItem:selectedObject];
        }else{
            [sender expandItem:selectedObject];
        }
		
    }else if([selectedObject isKindOfClass:[AIListContact class]]){
		//Hide any tooltip the contactListController is currently showing
		[contactListController hideTooltip];

		//Open a new message with the contact
		[[adium interfaceController] setActiveChat:[[adium contentController] openChatWithContact:(AIListContact *)selectedObject]];
		
    }
}


//Interface Container --------------------------------------------------------------------------------------------------
#pragma mark Interface Container
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
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//Contact list sent back
- (void)windowDidResignKey:(NSNotification *)notification
{
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidResignMain object:self];
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

//Prevent the system from altering our window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

// Auto-resizing support ------------------------------------------------------------------------------------------------
#pragma mark Auto-resizing support

- (void)screenParametersChanged:(NSNotification *)notification
{
	[contactListController contactListDesiredSizeChanged:nil];
}

@end
