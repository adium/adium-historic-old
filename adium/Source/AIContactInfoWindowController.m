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

#import "AIContactInfoWindowController.h"
#import "AIPreferenceCategory.h"

#define	CONTACT_INFO_NIB	@"ContactInfoWindow"		//Filename of the contact info nib

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName category:(AIPreferenceCategory *)inCategory;
@end

@implementation AIContactInfoWindowController

//Return the shared contact info window
static AIContactInfoWindowController *sharedContactInfoInstance = nil;
+ (AIContactInfoWindowController *)contactInfoWindowControllerWithCategory:(AIPreferenceCategory *)inCategory
{
    //Create the window
    if(!sharedContactInfoInstance){
        sharedContactInfoInstance = [[self alloc] initWithWindowNibName:CONTACT_INFO_NIB category:inCategory];
    }
    
    return(sharedContactInfoInstance);
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}


// Internal --------------------------------------------------------------------
//init
- (id)initWithWindowNibName:(NSString *)windowNibName category:(AIPreferenceCategory *)inCategory
{    
    [super initWithWindowNibName:windowNibName];
    mainCategory = [inCategory retain];
	displayedObject = nil;
        
    return(self);    
}

- (void)dealloc
{
    [mainCategory release];
	[displayedObject release];
    
    [super dealloc];
}

//When the contact list selection changes, then configure the window for the new contact
- (void)selectionChanged:(NSNotification *)notification
{
	[self configureForListObject:[[adium contactController] selectedListObject]];
}

//Configure our views for the specified list object
- (void)configureForListObject:(AIListObject *)inObject
{
	if(inObject == nil || displayedObject != inObject){
		[displayedObject release];
		displayedObject = [inObject retain];
		
		if(inObject == nil){
			[[self window] setContentView:view_noContact];
			[[self window] setTitle:@"Contact Info"];

		}else{
			[mainCategory configureForObject:inObject];
			[scrollView_contents setDocumentView:[mainCategory contentView]];
			[[self window] setContentView:view_contact];
			[[self window] setTitle:[NSString stringWithFormat:@"%@ Info",[inObject longDisplayName]]];

		}
	}
}

//Setup the window before it is displayed
- (void)windowDidLoad
{    
    NSString	*savedFrame;
    
	//Initial selection
    [[self window] setLevel:NSNormalWindowLevel];
    [[adium notificationCenter] addObserver:self selector:@selector(selectionChanged:) name:Interface_ContactSelectionChanged object:nil];
	[self selectionChanged:nil];
    
	//Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_CONTACT_INSPECTOR_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
}

//prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
	[[adium notificationCenter] removeObserver:self];
	
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_CONTACT_INSPECTOR_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
	//Close down our shared instance
    [sharedContactInfoInstance autorelease]; sharedContactInfoInstance = nil;

    return(YES);
}

@end
