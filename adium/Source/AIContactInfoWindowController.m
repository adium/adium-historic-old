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

#define	CONTACT_INFO_NIB	@"ContactInfoWindow"		//Filename of the contact info nib

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)selectionChanged:(NSNotification *)notification;
@end

@implementation AIContactInfoWindowController

//Return the shared contact info window
static AIContactInfoWindowController *sharedContactInfoInstance = nil;
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
	[[adium notificationCenter] removeObserver:self];
	
    //Save the window position
    [[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_CONTACT_INSPECTOR_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
	//Close down our shared instance
    [sharedContactInfoInstance autorelease]; sharedContactInfoInstance = nil;
	
    return(YES);
}

//prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}






- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem
{
	return([NSImage imageNamed:[NSString stringWithFormat:@"pref%@",[tabViewItem identifier]] forClass:[self class]]);
}

//- (int)tabView:(NSTabView *)tabView heightForTabViewItem:(NSTabViewItem *)tabViewItem
//{
//	
//}
	

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
		
		if(inObject){
			[[self window] setTitle:[NSString stringWithFormat:@"%@'s Info",[inObject displayName]]];
		}else{
			[[self window] setTitle:@"Contact Info"];
		}
		
	}
}
















@end
