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

#import <AIUtilities/AIUtilities.h>
#import "AIPreferenceWindowController.h"
#import "AIPreferenceCategory.h"
#import "AIPreferenceController.h"

#define PREFERENCE_WINDOW_NIB		@"PreferenceWindow"	//Filename of the preference window nib
#define TOOLBAR_PREFERENCE_WINDOW	@"PreferenceWindow"	//Identifier for the preference toolbar
#define	KEY_PREFERENCE_WINDOW_FRAME	@"Preference Window Frame"

@interface AIPreferenceWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)configureToolbarItems;
- (void)installToolbar;
- (void)showCategory:(AIPreferenceCategory *)inCategory;
@end

@implementation AIPreferenceWindowController
//The shared instance guarantees (with as little work as possible) that only one preference controller can be open at a time.  It also makes handling releasing the window very simple.
static AIPreferenceWindowController *sharedInstance = nil;
+ (AIPreferenceWindowController *)preferenceWindowControllerWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:PREFERENCE_WINDOW_NIB owner:inOwner];
    }
    
    return(sharedInstance);
}

//Make the specified preference view visible
- (void)showView:(AIPreferenceViewController *)inView
{
    NSEnumerator 		*enumerator;
    AIPreferenceCategory	*category;

    [self window]; //make sure the window has loaded

    //Show the category that was selected
    enumerator = [[owner categoryArray] objectEnumerator];
    while((category = [enumerator nextObject])){
        NSEnumerator 			*viewEnumerator;
        AIPreferenceViewController	*view;
        
        viewEnumerator = [[category viewArray] objectEnumerator];
        while((view = [viewEnumerator nextObject])){
            if(inView == view){
                [self showCategory:category];
                break;
            }    
        }
    }
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

// Internal --------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    //Retain our owner
    owner = [inOwner retain];
    toolbarItems = [[NSMutableDictionary dictionary] retain];

    return(self);    
}

- (void)dealloc
{
    [owner release];
    [toolbarItems release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;
    NSArray	*categoryArray;

    //Restore the window position
    savedFrame = [[owner preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PREFERENCE_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
    
    //
    [self installToolbar];
 
    //select the default category
    categoryArray = [owner categoryArray];
    if([categoryArray count]){
        [self showCategory:[categoryArray objectAtIndex:0]];
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
    //Save the window position
    [owner setPreference:[[self window] stringWithSavedFrame]
                  forKey:KEY_PREFERENCE_WINDOW_FRAME
                   group:PREF_GROUP_WINDOW_POSITIONS];

    //autorelease the shared instance
    [sharedInstance autorelease]; sharedInstance = nil;

    return(YES);
}

//Install our toolbar
- (void)installToolbar
{
    NSToolbar *toolbar;

    //init the toolbar
    toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_PREFERENCE_WINDOW] autorelease];
    [self configureToolbarItems];
    
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode: NSToolbarSizeModeSmall];

    //install it
    [[self window] setToolbar:toolbar];
}

//Configure the toolbar items
- (void)configureToolbarItems
{
    NSArray			*categoryArray;
    NSEnumerator		*enumerator;
    AIPreferenceCategory	*category;
    
    categoryArray = [owner categoryArray];
    enumerator = [categoryArray objectEnumerator];
    
    while((category = [enumerator nextObject])){
        NSString 	*name = [category name];
    
        if(![toolbarItems objectForKey:name]){
            [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                    withIdentifier:name
                                             label:name
                                      paletteLabel:name
                                           toolTip:name
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[category image]
                                            action:@selector(selectCategory:)
                                              menu:NULL];
        }
    }

    [[[self window] toolbar] setConfigurationFromDictionary:toolbarItems];
}

//Select the category that invoked this method
- (IBAction)selectCategory:(id)sender
{
    NSArray			*categoryArray;
    NSEnumerator		*enumerator;
    AIPreferenceCategory	*category = nil;
    NSString			*clickedName;
    
    //Get the name of the clicked category
    clickedName = [sender itemIdentifier];

    //Find this category
    categoryArray = [owner categoryArray];
    enumerator = [categoryArray objectEnumerator];
    
    while((category = [enumerator nextObject])){
        if([clickedName compare:[category name]] == 0){
            break;
        }
    }

    //Show the category that was selected
    [self showCategory:category];
}

- (void)showCategory:(AIPreferenceCategory *)inCategory
{
    [scrollView_contents setDocumentView:[inCategory contentView]];
}


//Toolbar item methods
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return(YES);
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    NSMutableArray		*defaultArray;
    NSArray			*categoryArray;
    NSEnumerator		*enumerator;
    AIPreferenceCategory	*category;
    
    defaultArray = [[NSMutableArray alloc] init];
    toolbar = [[self window] toolbar];
    categoryArray = [owner categoryArray];
    enumerator = [categoryArray objectEnumerator];
    
    while((category = [enumerator nextObject])){
        [defaultArray addObject:[category name]];
    }
    
    return([defaultArray autorelease]);
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return([self toolbarDefaultItemIdentifiers:toolbar]);
}

@end
