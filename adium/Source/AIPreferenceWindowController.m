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

#import <AIUtilities/AIUtilities.h>
#import "AIPreferenceWindowController.h"
#import "AIPreferencePane.h"
#import "AIPreferenceController.h"

#define PREFERENCE_WINDOW_NIB		@"PreferenceWindow"	//Filename of the preference window nib
#define TOOLBAR_PREFERENCE_WINDOW	@"PreferenceWindow"	//Identifier for the preference toolbar
#define	KEY_PREFERENCE_WINDOW_FRAME	@"Preference Window Frame"

@interface AIPreferenceWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)configureToolbarItems;
- (void)installToolbar;
//- (void)showCategory:(AIPreferenceCategory *)inCategory;
- (void)_insertPanesForCategory:(PREFERENCE_CATEGORY)inCategory intoView:(NSView *)inView;
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

+ (void)closeSharedInstance
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

//Make the specified preference view visible
- (void)showView:(AIPreferenceViewController *)inView
{
/*    NSEnumerator 		*enumerator;
    AIPreferenceCategory	*category;

    [self window]; //make sure the window has loaded

    //Show the category that was selected
    enumerator = [[[owner preferenceController] categoryArray] objectEnumerator];
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
    }*/
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
//    NSArray	*categoryArray;

    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PREFERENCE_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
    
    //
    [self installToolbar];
 
    //select the default category
/*    categoryArray = [[owner preferenceController] categoryArray];
    if([categoryArray count]){
        [self showCategory:[categoryArray objectAtIndex:0]];
    }*/

    //Let everyone know we will open
    [[owner notificationCenter] postNotificationName:Preference_WindowWillOpen object:nil];
}

//prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];

    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame]
                  forKey:KEY_PREFERENCE_WINDOW_FRAME
                   group:PREF_GROUP_WINDOW_POSITIONS];

    //Let everyone know we did close
    [[owner notificationCenter] postNotificationName:Preference_WindowDidClose object:nil];

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
    NSEnumerator	*enumerator;
    NSTabViewItem	*tabViewItem;
    
    enumerator = [[tabView_category tabViewItems] objectEnumerator];
    
    while((tabViewItem = [enumerator nextObject])){
        NSString 	*identifier = [tabViewItem identifier];
        NSString	*label = [tabViewItem label];
    
        if(![toolbarItems objectForKey:identifier]){
            [AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                    withIdentifier:identifier
                                             label:label
                                      paletteLabel:label
                                           toolTip:label
                                            target:self
                                   settingSelector:@selector(setImage:)
                                       itemContent:[AIImageUtilities imageNamed:@"Placeholder" forClass:[self class]]
                                            action:@selector(selectCategory:)
                                              menu:NULL];
        }
    }

    [[[self window] toolbar] setConfigurationFromDictionary:toolbarItems];
}

//Select the category that invoked this method
- (IBAction)selectCategory:(id)sender
{
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];
    
    //Select the corresponding tab
    [tabView_category selectTabViewItemWithIdentifier:[sender itemIdentifier]];
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    int	identifier = [[tabViewItem identifier] intValue];

    switch(identifier){
        case 1:
            [self _insertPanesForCategory:AIPref_Accounts_Connections intoView:view_Accounts_Connections];
            [self _insertPanesForCategory:AIPref_Accounts_Profile intoView:view_Accounts_Profile];
            [self _insertPanesForCategory:AIPref_Accounts_Hosts intoView:view_Accounts_Hosts];
        break;
        case 2:
            [self _insertPanesForCategory:AIPref_ContactList_General intoView:view_ContactList_General];
            [self _insertPanesForCategory:AIPref_ContactList_Display intoView:view_ContactList_Display];
        break;
        case 3:
            [self _insertPanesForCategory:AIPref_Messages_Display intoView:view_Messages_Display];
            [self _insertPanesForCategory:AIPref_Messages_Sending intoView:view_Messages_Sending];
            [self _insertPanesForCategory:AIPref_Messages_Receiving intoView:view_Messages_Receiving];
        break;
        case 4:
            [self _insertPanesForCategory:AIPref_Status_Away intoView:view_Status_Away];
            [self _insertPanesForCategory:AIPref_Status_Idle intoView:view_Status_Idle];
        break;
        case 5:
            [self _insertPanesForCategory:AIPref_Dock intoView:view_Dock];
        break;
        case 6:
            [self _insertPanesForCategory:AIPref_Sound intoView:view_Sound];
        break;
    }
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    
}

- (void)_insertPanesForCategory:(PREFERENCE_CATEGORY)inCategory intoView:(NSView *)inView
{
    NSEnumerator	*enumerator;
    AIPreferencePane	*pane;
    NSMutableArray	*paneArray = [NSMutableArray array];
    int			yPos = 0;

    //Get the panes for this category
    enumerator = [[[owner preferenceController] paneArray] objectEnumerator];
    while(pane = [enumerator nextObject]){
        if([pane category] == inCategory){
            [paneArray addObject:pane];
        }
    }

    //Alphabetize them
    [paneArray sortUsingSelector:@selector(compare:)];

    //Add their views
    enumerator = [paneArray objectEnumerator];
    while(pane = [enumerator nextObject]){
        NSView	*paneView = [pane view];
    
        //Add the view
        [inView addSubview:paneView];
        [paneView setFrameOrigin:NSMakePoint(0,yPos)];
    
        //Move down for the next view
        yPos += [paneView frame].size.height;
    }

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
    NSMutableArray	*defaultArray;
    NSEnumerator	*enumerator;
    NSToolbarItem	*toolbarItem;
    
    defaultArray = [[NSMutableArray alloc] init];

    //Build a list of all our toolbar item identifiers
    enumerator = [toolbarItems objectEnumerator];
    while((toolbarItem = [enumerator nextObject])){
        [defaultArray addObject:[toolbarItem itemIdentifier]];
    }

    //Sort
    [defaultArray sortUsingSelector:@selector(compare:)];
    
    return([defaultArray autorelease]);
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return([self toolbarDefaultItemIdentifiers:toolbar]);
}

@end
