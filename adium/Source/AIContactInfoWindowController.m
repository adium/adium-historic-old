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

#import "AIContactInfoWindowController.h"

#define	CONTACT_INFO_NIB				@"ContactInfoWindow"			//Filename of the contact info nib
#define KEY_INFO_WINDOW_FRAME			@"Contact Info Window Frame"	//
#define KEY_INFO_SELECTED_CATEGORY		@"Selected Info Category"		//

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)selectionChanged:(NSNotification *)notification;
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory;
@end

@implementation AIContactInfoWindowController

static AIContactInfoWindowController *sharedContactInfoInstance = nil;

//Return the shared contact info window
+ (void)showInfoWindowForListObject:(AIListObject *)listObject
{

    //Create the window
    if(!sharedContactInfoInstance){
        sharedContactInfoInstance = [[self alloc] initWithWindowNibName:CONTACT_INFO_NIB];
    }
	
	//Configure and show window
	[sharedContactInfoInstance configureForListObject:listObject];
	[sharedContactInfoInstance showWindow:nil];
}

//Close the info window
+ (void)closeInfoWindow
{
    if(sharedContactInfoInstance){
        [sharedContactInfoInstance closeWindow:nil];
    }
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName
{    
    [super initWithWindowNibName:windowNibName];
	displayedObject = nil;
	
    return(self);    
}

- (void)dealloc
{
	[displayedObject release];
    [super dealloc];
}	

//Setup the window before it is displayed
- (void)windowDidLoad
{    
	int             selectedTab;
    NSTabViewItem   *tabViewItem;
	NSString		*savedFrame;

    //
	loadedPanes = [[NSMutableArray alloc] init];
	
    //Select the previously selected category
    selectedTab = [[[adium preferenceController] preferenceForKey:KEY_INFO_SELECTED_CATEGORY
															group:PREF_GROUP_WINDOW_POSITIONS] intValue];
    if(selectedTab < 0 || selectedTab >= [tabView_category numberOfTabViewItems]) selectedTab = 0;
	
    tabViewItem = [tabView_category tabViewItemAtIndex:selectedTab];
    [self tabView:tabView_category willSelectTabViewItem:tabViewItem];
    [tabView_category selectTabViewItem:tabViewItem];    
	
	//Monitor the selected contact
    [[adium notificationCenter] addObserver:self selector:@selector(selectionChanged:) name:Interface_ContactSelectionChanged object:nil];
	[self selectionChanged:nil];
    
	//Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_INFO_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{	
	NSEnumerator 		*enumerator;
    AIContactInfoPane	*pane;
	
	//Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];
	
    //Close all open panes
    enumerator = [loadedPanes objectEnumerator];
    while(pane = [enumerator nextObject]){
        [pane closeView];
    }
    
    //Save the selected category
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[tabView_category indexOfSelectedTabViewItem]]
										 forKey:KEY_INFO_SELECTED_CATEGORY
										  group:PREF_GROUP_WINDOW_POSITIONS];
	
	
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_INFO_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
	//Close down
	[[adium notificationCenter] removeObserver:self];
    [self autorelease]; sharedContactInfoInstance = nil;
	
    return(YES);
}

//prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}






- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem
{
	return([NSImage imageNamed:[NSString stringWithFormat:@"info%@",[tabViewItem identifier]] forClass:[self class]]);
}



//
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    int	identifier = [[tabViewItem identifier] intValue];
	
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];
    
    if(tabView == tabView_category){
        switch(identifier){
            case AIInfo_Profile:
                [view_Profile setPanes:[self _panesInCategory:AIInfo_Profile]];
			break;
            case AIInfo_Accounts:
                [view_Accounts setPanes:[self _panesInCategory:AIInfo_Accounts]];
			break;
            case AIInfo_Alerts:
                [view_Alerts setPanes:[self _panesInCategory:AIInfo_Alerts]];
			break;
            case AIInfo_Settings:
                [view_Settings setPanes:[self _panesInCategory:AIInfo_Settings]];
			break;
        }
		
		//Update the selected toolbar item (10.3 or higher)
		if([[[self window] toolbar] respondsToSelector:@selector(setSelectedItemIdentifier:)]){
			[[[self window] toolbar] setSelectedItemIdentifier:[tabViewItem identifier]];
		}
		
		//Configure the loaded panes
		[self configurePanes];
    }
}

//Loads, alphabetizes, and caches prefs for the speficied category
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory
{
    NSMutableArray		*paneArray = [NSMutableArray array];
    NSEnumerator		*enumerator = [[[adium contactController] contactInfoPanes] objectEnumerator];
    AIContactInfoPane	*pane;
    
    //Get the panes for this category
    while(pane = [enumerator nextObject]){
        if([pane contactInfoCategory] == inCategory){
            [paneArray addObject:pane];
            [loadedPanes addObject:pane];
        }
    }
	
    //Alphabetize them
    [paneArray sortUsingSelector:@selector(compare:)];

    return(paneArray);
}

//When the contact list selection changes, then configure the window for the new contact
- (void)selectionChanged:(NSNotification *)notification
{
	[self configureForListObject:[[adium contactController] selectedListObject]];
}

//Change the list object
- (void)configureForListObject:(AIListObject *)inObject
{
	if(inObject == nil || displayedObject != inObject){
		NSImage				*userImage;

		//Update our displayed object
		[displayedObject release];
		displayedObject = [inObject retain];
		
		//Update our window title
		if(inObject){
			[[self window] setTitle:[NSString stringWithFormat:@"%@'s Info",[inObject displayName]]];
		}else{
			[[self window] setTitle:@"Contact Info"];
		}
		
		//Account name
		[textField_accountName setStringValue:(inObject ? [inObject formattedUID] : @"")];	
			
		//Service
		if([inObject isKindOfClass:[AIListContact class]]){
			[textField_service setStringValue:[inObject displayServiceID]];
		}
		
		//User Icon
		if(userImage = [[displayedObject displayArrayForKey:@"UserIcon"] objectValue]){
			//MUST make a copy, since resizing and flipping the original image here breaks it everywhere else
			userImage = [[userImage copy] autorelease];		
			//Resize to a fixed size for consistency
			[userImage setScalesWhenResized:YES];
			[userImage setSize:NSMakeSize(48,48)];
		}else{
			userImage = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
		}
		[imageView_userIcon setImage:userImage];
		
		//Configure our subpanes
		[self configurePanes];
	}
}

//Configure our views
- (void)configurePanes
{
	if(displayedObject){
		NSEnumerator		*enumerator = [loadedPanes objectEnumerator];
		AIContactInfoPane	*pane;
		
		while(pane = [enumerator nextObject]){
			[pane configureForListObject:displayedObject];
		}
	}
}

@end
