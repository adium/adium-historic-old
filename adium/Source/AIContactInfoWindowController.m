/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
- (id)initWithWindowNibName:(NSString *)windowNibName category:(AIPreferenceCategory *)inCategory contact:(AIContactHandle *)inContact;
- (void)configureForContact:(AIContactHandle *)inContact;
@end

@implementation AIContactInfoWindowController

//Return the shared contact info window
static AIContactInfoWindowController *sharedInstance = nil;
+ (AIContactInfoWindowController *)contactInfoWindowControllerWithCategory:(AIPreferenceCategory *)inCategory forContact:(AIContactHandle *)inContact
{
    //Create the window
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:CONTACT_INFO_NIB category:inCategory contact:inContact];
    }
    
    //Configure
    [sharedInstance configureForContact:inContact];


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
- (id)initWithWindowNibName:(NSString *)windowNibName category:(AIPreferenceCategory *)inCategory contact:(AIContactHandle *)inContact
{
    [super initWithWindowNibName:windowNibName owner:self];

    //Retain our owner
    mainCategory = [inCategory retain];

    return(self);    
}

- (void)dealloc
{
    [mainCategory release];

    [super dealloc];
}

//Configure our views for the specified contact
- (void)configureForContact:(AIContactHandle *)inContact
{
    //Configure the preference views
    [mainCategory configureForObject:inContact];

    [[self window] setTitle:[inContact UID]];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    //install the category
    [scrollView_contents setDocumentView:[mainCategory contentView]];

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
    //save
    
    //autorelease the shared instance
    [sharedInstance autorelease]; sharedInstance = nil;

    return(YES);
}

@end
