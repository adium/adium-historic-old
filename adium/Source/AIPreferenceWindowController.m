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
#import <Adium/Adium.h>
#import "AIPreferenceWindowController.h"
#import "AIPreferencePane.h"
#import "AIPreferenceController.h"

#define PREFERENCE_WINDOW_NIB			@"PreferenceWindow"	//Filename of the preference window nib
#define TOOLBAR_PREFERENCE_WINDOW		@"PreferenceWindow"	//Identifier for the preference toolbar
#define	KEY_PREFERENCE_WINDOW_FRAME		@"Preference Window Frame"
#define KEY_PREFERENCE_SELECTED_CATEGORY	@"Preference Selected Category"
#define FLAT_PADDING_OFFSET 45

@interface AIPreferenceWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)configureToolbarItems;
- (void)installToolbar;
- (void)_insertPanesForCategory:(PREFERENCE_CATEGORY)inCategory intoView:(AIFlippedCategoryView *)inView showContainers:(BOOL)includeContainers;
- (void)_sizeWindowToFitTabView:(NSTabView *)tabView;
- (void)_sizeWindowToFitFlatView:(AIFlippedCategoryView *)view;
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
    loadedPanes = [[NSMutableArray alloc] init];

    return(self);    
}

- (void)dealloc
{
    [owner release];
    [toolbarItems release];
    [loadedPanes release];
    
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSString	*savedFrame;
//    NSArray	*categoryArray;
    int		selectedTab;
    
    //Remember the amount of vertical padding to our window's frame
    yPadding = [[self window] frame].size.height;

    //
    [self installToolbar];
 
    //Select the previously selected category
    selectedTab = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PREFERENCE_SELECTED_CATEGORY] intValue];
    if(selectedTab < 0 || selectedTab > [tabView_category numberOfTabViewItems]) selectedTab = 0;
    [self tabView:tabView_category willSelectTabViewItem:[[tabView_category tabViewItems] objectAtIndex:selectedTab]];
    [tabView_category selectTabViewItemAtIndex:selectedTab];    

    //Restore the window position
    savedFrame = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PREFERENCE_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }

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
    NSEnumerator	*enumerator;
    AIPreferencePane	*pane;
    
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];

    //Save the selected category
    [[owner preferenceController] setPreference:[NSNumber numberWithInt:[tabView_category indexOfTabViewItem:[tabView_category selectedTabViewItem]]] forKey:KEY_PREFERENCE_SELECTED_CATEGORY group:PREF_GROUP_WINDOW_POSITIONS];
    
    //Save the window position
    [[owner preferenceController] setPreference:[[self window] stringWithSavedFrame] forKey:KEY_PREFERENCE_WINDOW_FRAME group:PREF_GROUP_WINDOW_POSITIONS];

    //Close all open panes
    enumerator = [loadedPanes objectEnumerator];
    while(pane = [enumerator nextObject]){
        [pane closeView];
    }
    
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
    [toolbar setSizeMode: NSToolbarSizeModeRegular];

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

    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];

    if(tabView == tabView_category){
        switch(identifier){
            case 1:
                [self _insertPanesForCategory:AIPref_Accounts_Connections intoView:view_Accounts_Connections showContainers:NO];
                [self _sizeWindowToFitFlatView:view_Accounts_Connections];
            break;
            case 2:
                [self _insertPanesForCategory:AIPref_ContactList_General intoView:view_ContactList_General showContainers:YES];
                [self _insertPanesForCategory:AIPref_ContactList_Groups intoView:view_ContactList_Groups showContainers:YES];
                [self _insertPanesForCategory:AIPref_ContactList_Contacts intoView:view_ContactList_Contacts showContainers:YES];
                [self _sizeWindowToFitTabView:tabView_contactList];
            break;
            case 3:
                [self _insertPanesForCategory:AIPref_Messages_Display intoView:view_Messages_Display showContainers:YES];
                [self _insertPanesForCategory:AIPref_Messages_Sending intoView:view_Messages_Sending showContainers:YES];
                [self _insertPanesForCategory:AIPref_Messages_Receiving intoView:view_Messages_Receiving showContainers:YES];
                [self _insertPanesForCategory:AIPref_Emoticons intoView:view_Messages_Emoticons showContainers:YES];
                [self _sizeWindowToFitTabView:tabView_messages];
            break;
            case 4:
                [self _insertPanesForCategory:AIPref_Status_Away intoView:view_Status_Away showContainers:YES];
                [self _insertPanesForCategory:AIPref_Status_Idle intoView:view_Status_Idle showContainers:YES];
                [self _sizeWindowToFitTabView:tabView_status];
            break;
            case 5:
                [self _insertPanesForCategory:AIPref_Dock_General intoView:view_Dock_General showContainers:YES];
                [self _insertPanesForCategory:AIPref_Dock_Icon intoView:view_Dock_Icon showContainers:YES];
                [self _sizeWindowToFitTabView:tabView_dock];
            break;
            case 6:
                [self _insertPanesForCategory:AIPref_Sound intoView:view_Sound showContainers:YES];
                [self _sizeWindowToFitFlatView:view_Sound];
            break;
            case 7:
                [self _insertPanesForCategory:AIPref_Alerts intoView:view_Alerts showContainers:NO];
                [self _sizeWindowToFitFlatView:view_Alerts];
            break;
        }
    }

}

- (void)_insertPanesForCategory:(PREFERENCE_CATEGORY)inCategory intoView:(AIFlippedCategoryView *)inView showContainers:(BOOL)includeContainers
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
            [loadedPanes addObject:pane];
        }
    }

    //Alphabetize them
    [paneArray sortUsingSelector:@selector(compare:)];

    //Add their views
    enumerator = [paneArray objectEnumerator];
    while(pane = [enumerator nextObject]){
        NSView	*paneView = [pane viewWithContainer:includeContainers];

        //Add the view
        if([paneView superview] != inView){
            [inView addSubview:paneView];
            [paneView setFrameOrigin:NSMakePoint(0,yPos)];
        }
    
        //Move down for the next view
        yPos += [paneView frame].size.height;
    }

    //Set the desired height of this view
    [inView setDesiredHeight:yPos];
}

//Resize our window to fit the specified tabview
- (void)_sizeWindowToFitTabView:(NSTabView *)tabView
{
    BOOL		isVisible = [[self window] isVisible];
    NSEnumerator	*enumerator;
    NSTabViewItem	*tabViewItem;
    int			maxHeight = 0;
    NSRect 		frame = [[self window] frame];

    //Determine the tallest view contained within this tab view.
    enumerator = [[tabView tabViewItems] objectEnumerator];
    while(tabViewItem = [enumerator nextObject]){
        NSEnumerator	*subViewEnumerator;
        NSView		*subView;

        subViewEnumerator = [[[tabViewItem view] subviews] objectEnumerator];
        while(subView = [subViewEnumerator nextObject]){
            int		height = [(AIFlippedCategoryView *)subView desiredHeight];

            if(height > maxHeight){
                maxHeight = height;
            }
        }
    }

    //Add in window frame padding
    maxHeight += yPadding;

    //Adjust our window's frame
    frame.origin.y += frame.size.height - maxHeight;
    frame.size.height = maxHeight;
    [[self window] setFrame:frame display:isVisible animate:isVisible];
}

- (void)_sizeWindowToFitFlatView:(AIFlippedCategoryView *)view
{
    BOOL	isVisible = [[self window] isVisible];
    NSRect 	frame = [[self window] frame];
    int		height = [(AIFlippedCategoryView *)view desiredHeight];

    //Add in window frame padding
    height += yPadding - FLAT_PADDING_OFFSET;

    //Adjust our window's frame
    frame.origin.y += frame.size.height - height;
    frame.size.height = height;
    [[self window] setFrame:frame display:isVisible animate:isVisible];
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
