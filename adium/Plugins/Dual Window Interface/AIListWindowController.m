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
#import "AIListGroupGradientCell.h"
#import "AIListContactCell.h"
#import "AIListContactBubbleCell.h"
#import "AIListGroupMockieCell.h"
#import "AIListContactMockieCell.h"
#import "AIListContactBrickCell.h"
#import "AIListContactBubbleToFitCell.h"

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

//#define BACKGROUND_COLOR		[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]

#define TOOL_TIP_CHECK_INTERVAL				45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY						25.0	//Number of check intervals of no movement before a tip is displayed

#define MAX_DISCLOSURE_HEIGHT				13		//Max height/width for our disclosure triangles

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

#define PREF_GROUP_CONTACT_STATUS_COLORING	@"Contact Status Coloring"

//#define BACKGROUND_ALPHA	1.0


//#define CONTACTS_USE_MOCKIE_CELL NO
//#define CONTACTS_USE_BUBBLE_CELL NO
//
//#define GROUPS_USE_MOCKIE_CELL		YES 
//#define GROUPS_USE_GRADIENT_CELL	YES
//#define DRAW_ALTERNATING_GRID	YES
//#define ALTERNATING_GRID_COLOR	[NSColor colorWithCalibratedRed:0.926 green:0.949 blue:0.992 alpha:1.0]


@interface AIListWindowController (PRIVATE)
- (void)contactSelectionChanged:(NSNotification *)notification;
- (void)contactListDesiredSizeChanged:(NSNotification *)notification;
- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (NSRect)_desiredWindowFrame;
- (void)_configureAutoResizing;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
- (void)contactListChanged:(NSNotification *)notification;
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
	NSLog(@"%@ initWithWindowNibName",self);
    return(self);
}

//Dealloc
- (void)dealloc
{
	[groupCell release];
	[contentCell release];

	NSLog(@"%@ dealloc",self);
    [super dealloc];
}

//Our window nib name
- (NSString *)nibName
{
    return(@"");    
}

//Setup the window after it has loaded
- (void)windowDidLoad
{
    NSString	*frameString;
    
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
    
    //Restore the window position
    frameString = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME];
	if(frameString){
		NSRect		windowFrame = NSRectFromString(frameString);
		
		//Don't allow the window to shrink smaller than its toolbar
		
		NSRect 		contentFrame = [NSWindow contentRectForFrameRect:windowFrame
														   styleMask:[[self window] styleMask]];
		
		if(contentFrame.size.height < [[self window] toolbarHeight]) windowFrame.size.height += [[self window] toolbarHeight] - contentFrame.size.height;
        
		[[self window] setFrame:windowFrame display:YES];
	}
	
    minWindowSize = [[self window] minSize];
	
    //Configure the contact list view
	tooltipTracker = [[AISmoothTooltipTracker smoothTooltipTrackerForView:scrollView_contactList withDelegate:self] retain];
	[[[contactListView tableColumns] objectAtIndex:0] setDataCell:[[AIListContactCell alloc] init]];	


	
	//Targeting
    [contactListView setTarget:self];
	[contactListView setDoubleAction:@selector(performDefaultActionOnSelectedContact:)];
	
	
#warning grr

	[scrollView_contactList setDrawsBackground:NO];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];
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
    //Stop observing
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[tooltipTracker release];
    
	//Save the window position
	[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
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
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
		int				windowStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
		float			backgroundAlpha	= [[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY] floatValue];

		//
		autoResizeVertically = [[prefDict objectForKey:KEY_LIST_LAYOUT_VERTICAL_AUTOSIZE] boolValue];
		autoResizeHorizontally = NO;
        [self _configureAutoResizing];
		
		//Cells
		[groupCell release];
		[contentCell release];
		if(windowStyle == WINDOW_STYLE_MOCKIE){
			groupCell = [[AIListGroupMockieCell alloc] init];	
			contentCell = [[AIListContactMockieCell alloc] init];
		}else{
			Class	cellClass;
			
			switch([[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_CELL_STYLE] intValue]){
				case CELL_STYLE_STANDARD: 	cellClass = [AIListGroupCell class]; break;
				case CELL_STYLE_BRICK: 		cellClass = [AIListGroupGradientCell class]; break;
				case CELL_STYLE_BUBBLE: 	cellClass = [AIListGroupGradientCell class]; break;
				default: /*case CELL_STYLE_BUBBLE_FIT:*/ cellClass = [AIListGroupGradientCell class]; break;
			}
			groupCell = [[cellClass alloc] init];	
			
			switch([[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_CELL_STYLE] intValue]){
				case CELL_STYLE_STANDARD: 	cellClass = [AIListContactCell class]; break;
				case CELL_STYLE_BRICK: 		cellClass = [AIListContactBrickCell class]; break;
				case CELL_STYLE_BUBBLE: 	cellClass = [AIListContactBubbleCell class]; break;
				default: /*case CELL_STYLE_BUBBLE_FIT:*/ cellClass = [AIListContactBubbleToFitCell class]; break;
			}
			contentCell = [[cellClass alloc] init];
		}
		[contactListView setGroupCell:groupCell];
		[contactListView setContentCell:contentCell];
		
		//Alignment
		[contentCell setTextAlignment:[[prefDict objectForKey:KEY_LIST_LAYOUT_ALIGNMENT] intValue]];
		[groupCell setTextAlignment:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_ALIGNMENT] intValue]];
		[contentCell setUserIconSize:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_SIZE] intValue]];

		[contentCell setUserIconVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_ICON] boolValue]];
		[contentCell setExtendedStatusVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_EXT_STATUS] boolValue]];
		[contentCell setStatusIconsVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_STATUS_ICONS] boolValue]];
		[contentCell setServiceIconsVisible:[[prefDict objectForKey:KEY_LIST_LAYOUT_SHOW_SERVICE_ICONS] boolValue]];
		
		[contentCell setUserIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_USER_ICON_POSITION] intValue]];
		[contentCell setStatusIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_STATUS_ICON_POSITION] intValue]];
		[contentCell setServiceIconPosition:[[prefDict objectForKey:KEY_LIST_LAYOUT_SERVICE_ICON_POSITION] intValue]];

		//Bubbles special cases
		LIST_CELL_STYLE	contactCellStyle = [[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_CELL_STYLE] intValue];
		if(contactCellStyle == CELL_STYLE_BUBBLE || contactCellStyle == CELL_STYLE_BUBBLE_FIT){
			[contentCell setSplitVerticalSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
		}else{
			[contentCell setSplitVerticalPadding:[[prefDict objectForKey:KEY_LIST_LAYOUT_CONTACT_SPACING] intValue]];
		}

		//Mockie special cases
		if(windowStyle == WINDOW_STYLE_MOCKIE){
			[groupCell setTopSpacing:[[prefDict objectForKey:KEY_LIST_LAYOUT_GROUP_TOP_SPACING] intValue]];
			[contentCell setBackgroundOpacity:backgroundAlpha];
		}
		[contactListView setDrawsBackground:(windowStyle != WINDOW_STYLE_MOCKIE)];

		//Shadow
		[[self window] setHasShadow:[[prefDict objectForKey:KEY_LIST_LAYOUT_WINDOW_SHADOWED] boolValue]];
		
		//Outline View
		[self updateTransparency];
		[contactListView setGroupCell:groupCell];
		[contactListView setContentCell:contentCell];
		[contactListView setDrawsAlternatingRows:[[prefDict objectForKey:KEY_LIST_LAYOUT_GRID_ENABLED] boolValue]];
		[contactListView setNeedsDisplay:YES];
	}
	
	//Theme
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_LIST_THEME])){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_THEME];
		NSString		*imagePath = [prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_PATH];
		float			backgroundAlpha	= [[[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY
																					group:PREF_GROUP_LIST_LAYOUT] floatValue];

		//Background Image
		if(imagePath && [imagePath length] && [[prefDict objectForKey:KEY_LIST_THEME_BACKGROUND_IMAGE_ENABLED] boolValue]){
			[contactListView setBackgroundImage:[[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease]];
		}else{
			[contactListView setBackgroundImage:nil];
		}
		
		//Background
		[self updateTransparency];
	}
}

- (void)updateTransparency
{
	NSDictionary	*layoutDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_LAYOUT];
	NSDictionary	*layoutTheme = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LIST_THEME];
	float			backgroundAlpha	= [[layoutDict objectForKey:KEY_LIST_LAYOUT_WINDOW_TRANSPARENCY] floatValue];
	int				windowStyle = [[layoutDict objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue];
		
	[contactListView setBackgroundFade:([[layoutTheme objectForKey:KEY_LIST_THEME_BACKGROUND_FADE] floatValue] * backgroundAlpha)];
	[contactListView setBackgroundColor:[[[layoutTheme objectForKey:KEY_LIST_THEME_BACKGROUND_COLOR] representedColor] colorWithAlphaComponent:backgroundAlpha]];
	[contactListView setAlternatingRowColor:[[[layoutTheme objectForKey:KEY_LIST_THEME_GRID_COLOR] representedColor] colorWithAlphaComponent:backgroundAlpha]];

	if(windowStyle == WINDOW_STYLE_MOCKIE) backgroundAlpha = 0.0;

	//Transparency.  Bye bye CPU cycles, I'll miss you!
	[[self window] setOpaque:(backgroundAlpha == 1.0)];
	[contactListView setUpdateShadowsWhileDrawing:(backgroundAlpha < 0.8)];
	//--
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









//Double click in outline view
- (IBAction)performDefaultActionOnSelectedContact:(id)sender
{
    AIListObject	*selectedObject = [sender itemAtRow:[sender selectedRow]];
	
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
		
		//If the contact is a meta contact, find the preferred contact for it
		if([contact isKindOfClass:[AIMetaContact class]]){
			contact = [[adium contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
																 forListContact:contact];
		}
		
		[[adium interfaceController] setActiveChat:[[adium contentController] openChatWithContact:contact]];
		
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
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//Contact list sent back
- (void)windowDidResignKey:(NSNotification *)notification
{
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
	NSRect      windowFrame = [[self window] frame];
	NSRect		viewFrame = [scrollView_contactList frame];
	NSSize		desiredViewSize = [contactListView desiredSize];
	NSRect		screenFrame = [[[self window] screen] visibleFrame];
	NSRect		newWindowFrame = NSMakeRect(0, 0, windowFrame.size.width, windowFrame.size.height);
	
	//Subtract the current size of the view from our frame
	//newWindowSize.width -= viewFrame.size.width;
	newWindowFrame.size.height -= viewFrame.size.height;
	
	//Now, figure out how big the view wants to be and add that to our frame
	//newWindowSize.width += desiredViewSize.width;
	newWindowFrame.size.height += desiredViewSize.height;
	
	//If the window is not near the bottom edge of the screen, keep its titlebar in place
	if(windowFrame.origin.y > screenFrame.origin.y + EDGE_CATCH_Y ||
	   windowFrame.origin.y + windowFrame.size.height + EDGE_CATCH_Y > screenFrame.origin.y + screenFrame.size.height){
		newWindowFrame.origin.y = windowFrame.origin.y + (windowFrame.size.height - newWindowFrame.size.height);
	}else{
		newWindowFrame.origin.y = windowFrame.origin.y;
	}
	newWindowFrame.origin.x = windowFrame.origin.x;
	
	//And adjust if we've fallen off the screen
	//windowFrame = NSIntersectionRect(windowFrame, visibleScreenFrame);
	
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
		[contactList release]; contactList = [[[adium contactController] contactList] retain];
		[contactListView reloadData];
#warning ###		[contactListView _performFullRecalculation];
	}else{
		NSDictionary	*userInfo = [notification userInfo];
		AIListGroup		*containingGroup = [userInfo objectForKey:@"ContainingGroup"];
		
		if(!containingGroup || containingGroup == contactList){
			//Reload the whole tree if the containing group is our root
			[contactListView reloadData];
#warning ###			[contactListView _performFullRecalculation];
		}else{
			//We need to reload the contaning group since this notification is posted when adding and removing objects.
			//Reloading the actual object that changed will produce no results since it may not be on the list.
			[contactListView reloadItem:containingGroup reloadChildren:YES];
		}
		
		//Factor the width of this item into our total
#warning ###		[contactListView updateHorizontalSizeForObject:object];
	}
	
	[self contactListDesiredSizeChanged:nil];
}

//Reload the contact list (if updates aren't delayed)
- (void)contactOrderChanged:(NSNotification *)notification
{
	id		object = [notification object];
	
	if(!object || (object == contactList)){ //Treat a nil object as equivalent to the contact list
		[contactListView reloadData];
#warning ###		[contactListView _performFullRecalculation];
	}else{
		if([object containingObject]) [contactListView reloadItem:[object containingObject] reloadChildren:YES];
	}
}

//Redisplay the modified object (Attribute change)
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*object = [notification object];
    NSArray			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
    //Redraw the modified object
	[contactListView redisplayItem:[notification object]];
	
    //Resize the contact list horizontally
    if(horizontalResizingEnabled){
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

//Outline View data source ---------------------------------------------------------------------------------------------
#pragma mark Outline View data source
//
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
		return((index >= 0 && index < [contactList containedObjectsCount]) ? [contactList objectAtIndex:index] : nil);
    }else{
        return((index >= 0 && index < [item containedObjectsCount]) ? [item objectAtIndex:index] : nil);
    }
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[AIListGroup class]]){
        return(YES);
    }else{
        return(NO);
    }
}

//
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
        return([contactList visibleCount]);
    }else{
        return([item visibleCount]);
    }
}

//Before one of our cells gets told to draw, we need to make sure it knows what contact it's drawing for.
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[(AIListCell *)cell setListObject:item];
	[(AIListCell *)cell setControlView:outlineView];
}

//
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return(@"");
}

//
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{    
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
- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    NSMutableArray      *contactArray = [[adium contactController] allContactsInGroup:item subgroups:YES onAccount:nil];

    [item setExpanded:state];
#warning ###	[contactListView updateHorizontalSizeForObjects:contactArray]; 
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    return([item isExpanded]);
}

//
- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent
{
    NSPoint	location;
    int		row;
    id		item;

    //Get the clicked item
    location = [outlineView convertPoint:[theEvent locationInWindow] fromView:[[outlineView window] contentView]];
    row = [outlineView rowAtPoint:location];
    item = [outlineView itemAtRow:row];

    //Select the clicked row and bring the window forward
    [outlineView selectRow:row byExtendingSelection:NO];
    [[outlineView window] makeKeyAndOrderFront:nil];

    //Hide any open tooltip
    [self hideTooltip];

    //Return the context menu
	AIListObject	*listObject = (AIListObject *)[contactListView firstSelectedItem];
	BOOL			isGroup = [listObject isKindOfClass:[AIListGroup class]];
	NSArray			*locationsArray = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:(isGroup ? Context_Group_Manage : Context_Contact_Manage)],
		[NSNumber numberWithInt:Context_Contact_Action],
		[NSNumber numberWithInt:Context_Contact_ListAction],
		[NSNumber numberWithInt:Context_Contact_NegativeAction],
		[NSNumber numberWithInt:Context_Contact_Additions], nil];
	
    return([[adium menuController] contextualMenuWithLocations:locationsArray
												 forListObject:listObject]);
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
/*	float	capHeight = [[contactListView groupFont] capHeight];
	NSImage	*image, *altImage;
	
	//The triangle can only get so big before it starts to get clipped, so we restrict it's size as necessary
	if(capHeight > MAX_DISCLOSURE_HEIGHT) capHeight = MAX_DISCLOSURE_HEIGHT;

	//Apply this new size to the images
	image = [cell image];
	altImage = [cell alternateImage];
	
	//Resize the iamges
	[image setScalesWhenResized:YES];
	[image setSize:NSMakeSize(capHeight, capHeight)];
	[altImage setScalesWhenResized:YES];
	[altImage setSize:NSMakeSize(capHeight, capHeight)];

	//Set them back and center
	[cell setAlternateImage:altImage];
	[cell setImage:image];
	[cell setImagePosition:NSImageOnly];
	[cell setHighlightsBy:NSContentsCellMask];*/
} 


- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
	//Kill any selections
	[outlineView deselectAll:nil];

	//Begin the drag
	if(dragItems) [dragItems release];
	dragItems = [items retain];

	[pboard declareTypes:[NSArray arrayWithObjects:@"AIListObject",nil] owner:self];
	[pboard setString:@"Private" forType:@"AIListObject"];

	return(YES);
}
//
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
	//No longer in a drag, so allow tooltips again
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
		
		//Move the list object to it's new location
		if([item isKindOfClass:[AIListGroup class]]){
			[[adium contactController] moveListObjects:dragItems toGroup:item index:index];
		}
	}

    return(YES);
}


- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	[self contactListDesiredSizeChanged:nil];
//	[self performSelector:@selector(contactListDesiredSizeChanged:) withObject:nil afterDelay:0.000001];
//    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification
//														object:contactListView];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	[self contactListDesiredSizeChanged:nil];
//	[self performSelector:@selector(contactListDesiredSizeChanged:) withObject:nil afterDelay:0.000001];
//    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification
//														object:contactListView];
}
	






//Tooltip --------------------------------------------------------------------------------------------------------------
#pragma mark Tooltip
//Show tooltip
- (void)showTooltipAtPoint:(NSPoint)screenPoint
{
	NSPoint			viewPoint = [contactListView convertPoint:[[self window] convertScreenToBase:screenPoint] fromView:nil];
	AIListObject	*hoveredObject = [contactListView itemAtRow:[contactListView rowAtPoint:viewPoint]];
	
	if([hoveredObject isKindOfClass:[AIListContact class]]){
		[[adium interfaceController] showTooltipForListObject:hoveredObject
												atScreenPoint:screenPoint
													 onWindow:[self window]];
	}else{
		[self hideTooltip];
	}
}

//Hide tooltip
- (void)hideTooltip
{
	[[adium interfaceController] showTooltipForListObject:nil atScreenPoint:NSMakePoint(0,0) onWindow:nil];
}


@end
