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

#import <Adium/Adium.h>
#import "AIContactInfoWindowController.h"
#import "AIPreferenceCategory.h"
#import "AIAdium.h"

#define	CONTACT_INFO_NIB	@"ContactInfoWindow"		//Filename of the contact info nib

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName category:(AIPreferenceCategory *)inCategory  owner:(AIAdium*)inOwner;
- (void)configureForContact:(AIListContact *)inContact;
- (void)configureForNoContact;
@end

@implementation AIContactInfoWindowController

//Return the shared contact info window
static AIContactInfoWindowController *sharedInstance = nil;
+ (AIContactInfoWindowController *)contactInfoWindowControllerWithCategory:(AIPreferenceCategory *)inCategory owner:(AIAdium*)inOwner
{
    //Create the window
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:CONTACT_INFO_NIB category:inCategory owner:inOwner];
    }
    

    return(sharedInstance);
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
- (id)initWithWindowNibName:(NSString *)windowNibName category:(AIPreferenceCategory *)inCategory owner:(AIAdium*)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    //Retain our owner
    mainCategory = [inCategory retain];
    owner = [inOwner retain];

    [[self window] setLevel:NSNormalWindowLevel];
    [[owner notificationCenter] addObserver:self selector:@selector(selectionChanged:) name:Interface_ContactSelectionChanged object:nil];
    
    return(self);    
}

- (void)dealloc
{
    [mainCategory release];
    [sharedInstance autorelease]; sharedInstance = nil;
    
    [super dealloc];
}

//When the contact list selection changes, then configure the window for the new contact
- (void)selectionChanged:(NSNotification *)notification
{
    if ([[owner contactController] selectedContact] != nil) {
        //install the category
        [scrollView_contents setDocumentView:[mainCategory contentView]];
        [[self window] setContentView:view_contact];

        [self configureForContact:[[owner contactController] selectedContact]];
    }else{
        [self configureForNoContact];
    }
}

//Configure our views for the specified contact
- (void)configureForContact:(AIListContact *)inContact
{
    //Configure the preference views
    [mainCategory configureForObject:inContact];

    [[self window] setTitle:[NSString stringWithFormat:@"%@ (%@) Info",[inContact UID], [inContact serviceID]]];
}

- (void)configureForNoContact
{
    //show the "No Contact Selected" view
    [[self window] setContentView:view_noContact];

    [[self window] setTitle:@"Contact Info"];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    if ([[owner contactController] selectedContact]) {
        //install the category
        [scrollView_contents setDocumentView:[mainCategory contentView]];
        [[self window] setContentView:view_contact];
        
        [self configureForContact:[[owner contactController] selectedContact]];
    }else{
        [self configureForNoContact];
    }
    
    [[self window] center];
}

//prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    return(YES);
}

@end
