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

#define EDGE_CATCH_X				10
#define EDGE_CATCH_Y				40
#define SCROLL_VIEW_PADDING_X		2
#define SCROLL_VIEW_PADDING_Y		2

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
- (void)contactSelectionChanged:(NSNotification *)notification;
- (void)contactListDesiredSizeChanged:(NSNotification *)notification;
- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (NSRect)_desiredWindowFrameUsingDesiredWidth:(BOOL)useDesiredWidth desiredHeight:(BOOL)useDesiredHeight;
- (void)_configureAutoResizing;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
- (void)contactListChanged:(NSNotification *)notification;

- (void)updateTransparency;
- (void)updateCellRelatedThemePreferences;

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
	
	[contactListView setDrawHighlightOnlyWhenMain:YES];
	
    NSString	*frameString;
    
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
    
    minWindowSize = [[self window] minSize];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contactListDesiredSizeChanged:)
												 name:AIViewDesiredSizeDidChangeNotification
											   object:contactListView];
    
    //Watch for resolution and screen configuration changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(screenParametersChanged:) 
															   name:NSApplicationDidChangeScreenParametersNotification 
															 object:nil];
	
	//Observe contact list content and display changes
	[[adium notificationCenter] addObserver:self selector:@selector(contactListChanged:) 
									   name:Contact_ListChanged
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactOrderChanged:)
									   name:Contact_OrderChanged 
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:nil];
    [self contactListChanged:nil];
	
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
		
		//
		autoResizeVertically = [[layoutDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue];
		autoResizeHorizontally = [[layoutDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_AUTOSIZE] boolValue];
		if (autoResizeHorizontally){
			//If autosizing, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the maximum width; no forced width.
			maxWindowWidth = [[layoutDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue];
			forcedWindowWidth = -1;
		}else{
			if (windowStyle == WINDOW_STYLE_STANDARD/* || windowStyle == WINDOW_STYLE_BORDERLESS*/){
				//In the non-transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH has no meaning
				maxWindowWidth = 1000000;
				forcedWindowWidth = -1;
			}else{
				//In the transparent non-autosizing modes, KEY_LIST_LAYOUT_HORIZONTAL_WIDTH determines the width of the window
				forcedWindowWidth = [[layoutDict objectForKey:KEY_LIST_LAYOUT_HORIZONTAL_WIDTH] intValue];
				maxWindowWidth = forcedWindowWidth;
			}
		}
		
		[[self window] setShowsResizeIndicator:!(autoResizeVertically && autoResizeHorizontally)];
		[self contactListDesiredSizeChanged:nil];
		
		[self updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];
		[self updateTransparencyFromLayoutDict:layoutDict themeDict:themeDict];

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
		[self updateCellRelatedThemePreferencesFromDict:themeDict];
		[self updateTransparencyFromLayoutDict:layoutDict themeDict:themeDict];
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

- (IBAction)performDefaultActionOnSelectedContact:(AIListObject *)selectedObject withSender:(id)sender
{	
    if([selectedObject isKindOfClass:[AIListGroup class]]){
        //Expand or collapse the group
        if([sender isItemExpanded:selectedObject]){
            [sender collapseItem:selectedObject];
        }else{
            [sender expandItem:selectedObject];
        }
		
    }else if([selectedObject isKindOfClass:[AIListContact class]]){
        //Open a new message with the contact
		AIListContact	*contact = (AIListContact *)selectedObject;
		
		/*
		//If the contact is a meta contact, find the preferred contact for it
		if([contact isKindOfClass:[AIMetaContact class]]){
			contact = [[adium contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
																 forListContact:contact];
		}
		*/
		[[adium interfaceController] setActiveChat:[[adium contentController] openChatWithContact:contact]];
		
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



//Resizing And Positioning ---------------------------------------------------------------------------------------------
#pragma mark Resizing And Positioning
//Dynamically resize the contact list
- (void)contactListDesiredSizeChanged:(NSNotification *)notification
{
    if(autoResizeVertically || autoResizeHorizontally){
		NSRect  currentFrame = [[self window] frame];
        NSRect	desiredFrame = [self _desiredWindowFrameUsingDesiredWidth:(autoResizeHorizontally || (forcedWindowWidth != -1))
															desiredHeight:autoResizeVertically];
		/*
		NSLog(@"DesiredSizeChanged:\nWas %f %f %f %f\nNow %f %f %f %f",
			  currentFrame.origin.x,
			  currentFrame.origin.y,
			  currentFrame.size.width,
			  currentFrame.size.height,
			  desiredFrame.origin.x,
			  desiredFrame.origin.y,
			  desiredFrame.size.width,
			  desiredFrame.size.height);
		*/
		if(!NSEqualRects(currentFrame, desiredFrame)){
			
			[[self window] setFrame:desiredFrame display:YES animate:NO];
			[[self window] setMinSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : minWindowSize.width),
												 (autoResizeVertically ? desiredFrame.size.height : minWindowSize.height))];
			[[self window] setMaxSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : 10000),
												 (autoResizeVertically ? desiredFrame.size.height : 10000))];
		}
    }
}

//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return([self _desiredWindowFrameUsingDesiredWidth:YES desiredHeight:YES]);
}

//Desired frame of our window - if one of the BOOL values is NO, don't modify that value from the current frame
- (NSRect)_desiredWindowFrameUsingDesiredWidth:(BOOL)useDesiredWidth desiredHeight:(BOOL)useDesiredHeight
{
	NSRect      windowFrame, viewFrame, newWindowFrame, screenFrame, visibleScreenFrame;
	NSScreen	*currentScreen = [[self window] screen];

	windowFrame = [[self window] frame];
	newWindowFrame = windowFrame;//NSMakeRect(windowFrame, 0, windowFrame.size.width, windowFrame.size.height);
	viewFrame = [scrollView_contactList frame];

	screenFrame = [currentScreen frame];
	visibleScreenFrame = [currentScreen visibleFrame];
	
	//Width
	if(useDesiredWidth){
		if (forcedWindowWidth != -1){
			newWindowFrame.size.width = forcedWindowWidth;
		}else{
			//Subtract the current size of the view from our frame
			//newWindowSize.width -= viewFrame.size.width;
			newWindowFrame.size.width -= viewFrame.size.width;
			
			//Now, figure out how big the view wants to be and add that to our frame
			//newWindowSize.width += desiredViewSize.width;
			newWindowFrame.size.width += [contactListView desiredWidth];
			
			//Don't get bigger than our maxWindowWidth
			if (newWindowFrame.size.width > maxWindowWidth) newWindowFrame.size.width = maxWindowWidth;
			
			if ((windowFrame.origin.x + windowFrame.size.width) + EDGE_CATCH_X > (visibleScreenFrame.origin.x + visibleScreenFrame.size.width)){
				
				newWindowFrame.origin.x = windowFrame.origin.x + (windowFrame.size.width - newWindowFrame.size.width);
				if((newWindowFrame.origin.x + newWindowFrame.size.width) < (visibleScreenFrame.origin.x + EDGE_CATCH_X)){
					newWindowFrame.origin.x = visibleScreenFrame.origin.x - newWindowFrame.size.width + EDGE_CATCH_X;
				}
			}
		}
	}
	
	//Height
	if(useDesiredHeight){
		NSRect		applicableScreenFrame;
		
		//Subtract the current size of the view from our frame
		//newWindowSize.width -= viewFrame.size.width;
		newWindowFrame.size.height -= viewFrame.size.height;
		
		//Now, figure out how big the view wants to be and add that to our frame
		//newWindowSize.width += desiredViewSize.width;
		newWindowFrame.size.height += [contactListView desiredHeight];
		
		/* If the window is against the left or right edges of the screen, 
			use the screenFrame rather than the visibleScreenFrame as most users' docks do not extend all the way across
			the bottom. */
		if ((newWindowFrame.origin.x < screenFrame.origin.x + EDGE_CATCH_X) ||
			((newWindowFrame.origin.x + newWindowFrame.size.width) < (screenFrame.origin.x + screenFrame.size.width - EDGE_CATCH_X))){
			applicableScreenFrame = screenFrame;
		}else{
			applicableScreenFrame = visibleScreenFrame;
		}
		
		//Don't let the new frame be taller than the applicable screen frame's height.
//		if (newWindowFrame.size.height > applicableScreenFrame.size.height){
//			newWindowFrame.size.height = applicableScreenFrame.size.height;
//		}
		
		//If the window is not near the bottom edge of the screen, or the titlebar is near the top,
		//keep the titlebar in place
		if((windowFrame.origin.y > applicableScreenFrame.origin.y + EDGE_CATCH_Y) ||
		   (windowFrame.origin.y + windowFrame.size.height > applicableScreenFrame.origin.y + applicableScreenFrame.size.height - EDGE_CATCH_Y)){
			newWindowFrame.origin.y = windowFrame.origin.y + (windowFrame.size.height - newWindowFrame.size.height);
		}else{
			newWindowFrame.origin.y = windowFrame.origin.y;
		}
		
		//If the new window frame has an origin below the applicable screen frame, correct the situation
		if (newWindowFrame.origin.y < applicableScreenFrame.origin.y + 1){
			newWindowFrame.origin.y = applicableScreenFrame.origin.y + 1;
		}
		
		//Keep the window from going off the top of the visible area (which means not under the menu bar, too)
		float visibleScreenTop = (visibleScreenFrame.origin.y+visibleScreenFrame.size.height);

		if((newWindowFrame.origin.y + newWindowFrame.size.height) > visibleScreenTop){
			//If the window would go above the top of the screen (the menu bar), set the origin to the origin of
			//whichever is our applicable screen...
			newWindowFrame.origin.y = applicableScreenFrame.origin.y + 1;
			//...and set our height to the maximal height which will fit on the visible screen from that origin.
			newWindowFrame.size.height = visibleScreenTop - newWindowFrame.origin.y;
		}

		/*
		NSLog(@"\nnew: %f %f %f %f\nvisible: %f %f %f %f\nscreen: %f %f %f %f\napplicable: %f %f %f %f",
			  newWindowFrame.origin.x,
			  newWindowFrame.origin.y,
			  newWindowFrame.size.width,
			  newWindowFrame.size.height,
			  screenFrame.origin.x,
			  screenFrame.origin.y,
			  screenFrame.size.width,
			  screenFrame.size.height,
			  visibleScreenFrame.origin.x,
			  visibleScreenFrame.origin.y,
			  visibleScreenFrame.size.width,
			  visibleScreenFrame.size.height,
			  applicableScreenFrame.origin.x,
			  applicableScreenFrame.origin.y,
			  applicableScreenFrame.size.width,
			  applicableScreenFrame.size.height);
		 */
	}
	
	return(newWindowFrame);
}

	//	NSWindow    *theWindow = [self window];
//	NSRect      currentFrame = [theWindow frame];
//    NSRect		newFrame = currentFrame;
/*	
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
		
	}*/
//	
//	return(newFrame);
//}

	
//Prevent the system from altering our window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//Auto-resizing support ------------------------------------------------------------------------------------------------
//#pragma mark Auto-resizing support
//
//- (void)screenParametersChanged:(NSNotification *)notification
//{
//#warning ###    [contactListView _performFullRecalculation];
//}

//Content Updating -----------------------------------------------------------------------------------------------------
#pragma mark Content Updating
//Reload the contact list
- (void)contactListChanged:(NSNotification *)notification
{
	id		object = [notification object];

	//Redisplay and resize
	if(!object || object == contactList){
		[self setContactListRoot:[[adium contactController] contactList]];
	}else{
		NSDictionary	*userInfo = [notification userInfo];
		AIListGroup		*containingGroup = [userInfo objectForKey:@"ContainingGroup"];
		
		if(!containingGroup || containingGroup == contactList){
			//Reload the whole tree if the containing group is our root
			[contactListView reloadData];
		}else{
			//We need to reload the contaning group since this notification is posted when adding and removing objects.
			//Reloading the actual object that changed will produce no results since it may not be on the list.
			[contactListView reloadItem:containingGroup reloadChildren:YES];
		}
	}
	
	[self contactListDesiredSizeChanged:nil];
}

//Update the contact list (if updates aren't delayed)
- (void)contactOrderChanged:(NSNotification *)notification
{
	id		object = [[notification object] containingObject];

	//The notification passes the contact who's order changed.  This means that we must reload the group containing
	//that contact in order to correctly update the list.
	if(!object || (object == contactList)){ //Treat a nil object as equivalent to the contact list
		[contactListView reloadData];
	}else{
		[contactListView reloadItem:object reloadChildren:YES];
	}
}

//Redisplay the modified object (Attribute change)
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*object = [notification object];
    NSArray			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
    //Redraw the modified object
	[contactListView redisplayItem:object];
	
    //Resize the contact list horizontally
    if(autoResizeHorizontally){
		if (object){
			if([keys containsObject:@"Display Name"] || [keys containsObject:@"Left View"] ||
			   [keys containsObject:@"Right View"] || [keys containsObject:@"Right Text"] ||
			   [keys containsObject:@"Left Text"]){
#warning ###				[contactListView updateHorizontalSizeForObject:object];
			}
		}else{
#warning ###			[contactListView _performFullRecalculation];	
		}
    }
}

//
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{    
	//Reftesh
	[contactListView setNeedsDisplay:YES];
	
    //Post a 'contact list selection changed' notification on the interface center
	//If we post this notification immediately, our outline view may not yet be key, and contact controller
	//will return nil for 'selectedListObject'.  If we wait until we're back in the main run loop, the
	//outline view will be set as key for certain, and everything will work as expected.
	[self performSelector:@selector(_delayedNotify) withObject:nil afterDelay:0.0001];
}
- (void)_delayedNotify{
	[[adium notificationCenter] postNotificationName:Interface_ContactSelectionChanged object:nil];
}

//
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
	//No dropping into contacts
    if([avaliableType isEqualToString:@"AIListObject"]){
		id	primaryDragItem = [dragItems objectAtIndex:0];
		
		if([primaryDragItem isKindOfClass:[AIListGroup class]]){
			//Disallow dragging groups into or onto other objects
			if(item != nil){
				if([item isKindOfClass:[AIListGroup class]]){
					[outlineView setDropItem:nil dropChildIndex:[[item containingObject] indexOfObject:item]];
				}else{
					[outlineView setDropItem:nil dropChildIndex:[[[item containingObject] containingObject] indexOfObject:[item containingObject]]];
				}
			}
			
		}else{
			//Disallow dragging contacts onto anything besides a group
			if(index == -1 && ![item isKindOfClass:[AIListGroup class]]){
				[outlineView setDropItem:[item containingObject] dropChildIndex:[[item containingObject] indexOfObject:item]];
			}
			
		}

		if(index == -1 && ![item isKindOfClass:[AIListGroup class]]){
			return(NSDragOperationNone);
		}
	}
	
	return(NSDragOperationPrivate);
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
    NSString	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
    
	//No longer in a drag, so allow tooltips again
    if([availableType isEqualToString:@"AIListObject"]){
		//The tree root is not associated with our root contact list group, so we need to make that association here
		if(item == nil) item = contactList;
		
		//Move the list object to its new location
		if([item isKindOfClass:[AIListGroup class]]){
			[[adium contactController] moveListObjects:dragItems toGroup:item index:index];
		}
	}

    return(YES);
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	[self contactListDesiredSizeChanged:nil];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	[self contactListDesiredSizeChanged:nil];
}


@end
