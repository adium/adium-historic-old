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

// $Id: AIPreferenceWindowController.m,v 1.53 2004/06/04 15:23:49 adamiser Exp $

#import "AIPreferenceWindowController.h"
#import "AIPreferencePane.h"
#import "AIPreferenceController.h"

#define PREFERENCE_WINDOW_NIB					@"PreferenceWindow"	//Filename of the preference window nib
#define TOOLBAR_PREFERENCE_WINDOW				@"PreferenceWindow"	//Identifier for the preference toolbar
#define KEY_PREFERENCE_WINDOW_TOOLBAR_DISPLAY   @"Preference Window Toolbar Display Mode"
#define KEY_PREFERENCE_WINDOW_TOOLBAR_SIZE		@"Preference Window Toolbar Size Mode"
#define	KEY_PREFERENCE_WINDOW_FRAME				@"Preference Window Frame"
#define KEY_PREFERENCE_SELECTED_CATEGORY		@"Preference Selected Category"
#define KEY_ADVANCED_PREFERENCE_SELECTED_ROW    @"Preference Advanced Selected Row"
#define PREFERENCE_WINDOW_TITLE					@"Preferences"
#define PREFERENCE_PANE_ARRAY					@"PaneArray"
#define PREFERENCE_GROUP_NAME					@"GroupName"
#define ADVANCED_PANE_HEIGHT					350

@interface AIPreferenceWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)configureToolbarItems;
- (void)installToolbar;
- (void)_sizeWindowToFitTabView:(NSTabView *)tabView;
- (void)_sizeWindowToFitFlatView:(AIModularPaneCategoryView *)view;
- (void)_sizeWindowForContentHeight:(int)height;
- (IBAction)restoreDefaults:(id)sender;
- (NSDictionary *)_createGroupNamed:(NSString *)inName forCategory:(PREFERENCE_CATEGORY)category;
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory;
@end

@implementation AIPreferenceWindowController
//The shared instance guarantees (with as little work as possible) that only one preference controller can be open at a time.  It also makes handling releasing the window very simple.
static AIPreferenceWindowController *sharedPreferenceInstance = nil;
+ (AIPreferenceWindowController *)preferenceWindowController
{
    if(!sharedPreferenceInstance){
        sharedPreferenceInstance = [[self alloc] initWithWindowNibName:PREFERENCE_WINDOW_NIB];
    }
    
    return(sharedPreferenceInstance);
}

+ (void)closeSharedInstance
{
    if(sharedPreferenceInstance){
        [sharedPreferenceInstance closeWindow:nil];
    }
}

//Make the specified preference category visible
- (void)showCategory:(PREFERENCE_CATEGORY)inCategory
{
	int 			tabIdentifier;
	NSTabViewItem	*tabViewItem;
	
	//Ensure the window has loaded
	[self window];
	
	//Select the category
	switch(inCategory){
		case AIPref_Accounts: tabIdentifier = 1; break;
		case AIPref_ContactList_General:
		case AIPref_ContactList_Groups:
		case AIPref_ContactList_Contacts: tabIdentifier = 2; break;
		case AIPref_Messages: tabIdentifier = 3; break;
		case AIPref_Status_Away:
		case AIPref_Status_Idle: tabIdentifier = 4; break;
		case AIPref_Dock: tabIdentifier = 5; break;
		case AIPref_Sound: tabIdentifier = 6; break;
		case AIPref_Emoticons: tabIdentifier = 7; break;
		case AIPref_Advanced_ContactList:
		case AIPref_Advanced_Messages:
		case AIPref_Advanced_Status:
		case AIPref_Advanced_Other: tabIdentifier = 8; break;
		default: tabIdentifier = 1; break;
	}
	tabViewItem = [tabView_category tabViewItemWithIdentifier:[NSString stringWithFormat:@"%i",tabIdentifier]];
	[self tabView:tabView_category willSelectTabViewItem:tabViewItem];
	[tabView_category selectTabViewItem:tabViewItem];

}

- (void)showAdvancedPane:(NSString *)paneName inCategory:(PREFERENCE_CATEGORY)category
{
	NSArray				*advancedPrefArray;
	NSEnumerator		*enumerator;
	AIPreferencePane	*pane;
	NSTabViewItem		*tabViewItem;
	BOOL				shouldContinue = YES;
	int					row;
	
	advancedPrefArray = [self _panesInCategory:category];
	enumerator = [advancedPrefArray objectEnumerator];
	
	[self window];
	
	while( shouldContinue && (pane = [enumerator nextObject]) ) {
		if( [paneName caseInsensitiveCompare:[pane label]] == 0 ) {
			shouldContinue = NO;
		}
	}
	
	if( shouldContinue == NO ) {
		
		// Open the Advanced Prefs category
		tabViewItem = [tabView_category tabViewItemWithIdentifier:[NSString stringWithFormat:@"8"]];
		[self tabView:tabView_category willSelectTabViewItem:tabViewItem];
		[tabView_category selectTabViewItem:tabViewItem];
		
		// Open the pane
		[self configureAdvancedPreferencesForPane:pane];
		
		// Select the correct row in the outline view
		row = [outlineView_advanced rowForItem:pane];
		[outlineView_advanced selectRow:row byExtendingSelection:NO];
	}
}


//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}





//Internal -------------------------------------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    //Retain our owner
    loadedPanes = [[NSMutableArray alloc] init];
    _advancedCategoryArray = nil;
    loadedAdvancedPanes = nil;

    return(self);    
}

- (void)dealloc
{
	[self configureAdvancedPreferencesForPane:nil];

    [loadedPanes release];

    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    int             selectedTab;
    NSTabViewItem   *tabViewItem;

    //
    [outlineView_advanced setIndentationPerLevel:10];
    [coloredBox_advancedTitle setColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.15]];
 
    //Select the previously selected category
    selectedTab = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_PREFERENCE_SELECTED_CATEGORY] intValue];
    if(selectedTab < 0 || selectedTab >= [tabView_category numberOfTabViewItems]) selectedTab = 0;

    tabViewItem = [tabView_category tabViewItemAtIndex:selectedTab];
    [self tabView:tabView_category willSelectTabViewItem:tabViewItem];
    [tabView_category selectTabViewItem:tabViewItem];    

	//Enable the "Restore Defaults" Button
	[button_restoreDefaults setEnabled:YES];
	
    //Center the window
	[[self window] center];
	
    //Let everyone know we will open
    [[adium notificationCenter] postNotificationName:Preference_WindowWillOpen object:nil];
}

//prevent the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
	//Save toolbar state
	NSToolbar *toolbar = [[self window] toolbar];

	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[toolbar displayMode]]
										 forKey:KEY_PREFERENCE_WINDOW_TOOLBAR_DISPLAY
										  group:PREF_GROUP_GENERAL];
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[toolbar sizeMode]]
										 forKey:KEY_PREFERENCE_WINDOW_TOOLBAR_SIZE
										  group:PREF_GROUP_GENERAL];
	
	//Save selection
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[outlineView_advanced selectedRow]]
										 forKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
										  group:PREF_GROUP_WINDOW_POSITIONS];
	
    NSEnumerator	*enumerator;
    AIPreferencePane	*pane;
    
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];

    //Save the selected category
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[tabView_category indexOfTabViewItem:[tabView_category selectedTabViewItem]]] forKey:KEY_PREFERENCE_SELECTED_CATEGORY group:PREF_GROUP_WINDOW_POSITIONS];
    
    //Close all open panes
    enumerator = [loadedPanes objectEnumerator];
    while(pane = [enumerator nextObject]){
        [pane closeView];
    }
    
    //Let everyone know we will close
    [[adium notificationCenter] postNotificationName:Preference_WindowDidClose object:nil];

    //autorelease the shared instance
    [sharedPreferenceInstance autorelease]; sharedPreferenceInstance = nil;

    return(YES);
}

//
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    int	identifier = [[tabViewItem identifier] intValue];

    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:tabView_category];
    
    if(tabView == tabView_category){
        switch(identifier){
            case 1:
                [view_Accounts setPanes:[self _panesInCategory:AIPref_Accounts]];
            break;
            case 2:
                [view_ContactList_General setPanes:[self _panesInCategory:AIPref_ContactList_General]];
                [view_ContactList_Groups setPanes:[self _panesInCategory:AIPref_ContactList_Groups]];
                [view_ContactList_Contacts setPanes:[self _panesInCategory:AIPref_ContactList_Contacts]];
            break;
            case 3:
                [view_Messages setPanes:[self _panesInCategory:AIPref_Messages]];
            break;
            case 4:
				[view_Status_Away setPanes:[self _panesInCategory:AIPref_Status_Away]];
                [view_Status_Idle setPanes:[self _panesInCategory:AIPref_Status_Idle]];
            break;
            case 5:
				[view_Dock setPanes:[self _panesInCategory:AIPref_Dock]];
            break;
            case 6:
				[view_Sound setPanes:[self _panesInCategory:AIPref_Sound]];
            break;
            case 7:
				[view_Emoticons setPanes:[self _panesInCategory:AIPref_Emoticons]];
			break;
            case 8:
                [outlineView_advanced reloadData];

                //Select the previously selected row
				int row = [[[adium preferenceController] preferenceForKey:KEY_ADVANCED_PREFERENCE_SELECTED_ROW
																	group:PREF_GROUP_WINDOW_POSITIONS] intValue];
				if([self outlineView:outlineView_advanced shouldSelectItem:[outlineView_advanced itemAtRow:row]]){
					[outlineView_advanced selectRow:row byExtendingSelection:NO];
				}
            break;
			case 9:
				[view_Keys setPanes:[self _panesInCategory:AIPref_Keys]];
			break;
        }

		//Update the selected toolbar item (10.3 or higher)
		if([[[self window] toolbar] respondsToSelector:@selector(setSelectedItemIdentifier:)]){
			[[[self window] toolbar] setSelectedItemIdentifier:[tabViewItem identifier]];
		}
    }

    //Update the window title
    [[self window] setTitle:[NSString stringWithFormat:@"%@ : %@",PREFERENCE_WINDOW_TITLE,[tabViewItem label]]];    	
}

- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem
{
	return([NSImage imageNamed:[NSString stringWithFormat:@"pref%@",[tabViewItem identifier]] forClass:[self class]]);
}

- (int)tabView:(NSTabView *)tabView heightForTabViewItem:(NSTabViewItem *)tabViewItem
{
	switch([[tabViewItem identifier] intValue]){
		case 1: return([view_Accounts desiredHeight]); break;
		case 2: return([AIModularPaneCategoryView heightForTabView:tabView_contactList]); break;
		case 3: return([view_Messages desiredHeight]); break;
		case 4: return([AIModularPaneCategoryView heightForTabView:tabView_status]); break;
		case 5: return([view_Dock desiredHeight]); break;
		case 6: return([view_Sound desiredHeight]); break;
		case 7: return([view_Emoticons desiredHeight]); break;
		case 8: return(ADVANCED_PANE_HEIGHT); break;
		case 9: return([view_Keys desiredHeight]); break;
		default: return(0); break;
	}
}


//Dynamic Content ------------------------------------------------------------------------------------------------------
//#pragma mark Toolbar
//Insert all the preference panes for the category into the passed view
//- (void)_insertPanesForCategory:(PREFERENCE_CATEGORY)inCategory
//					   intoView:(AIPreferenceCategoryView *)inView
//{
//    [self _insertPanes:[self _prefsInCategory:inCategory] intoView:inView];    
//}
//
//Insert the passed preference panes into a view
//- (void)_insertPanes:(NSArray *)paneArray
//			intoView:(AIPreferenceCategoryView *)inView
//{
//    NSEnumerator		*enumerator;
//    AIPreferencePane	*pane;
//    int					yPos = 0;
//    
//    //Add their views
//    enumerator = [paneArray objectEnumerator];
//    while(pane = [enumerator nextObject]){
//        NSView	*paneView = [pane view];
//        
//        //Add the view
//        if([paneView superview] != inView){
//            [inView addSubview:paneView];
//            [paneView setFrameOrigin:NSMakePoint(0,yPos)];
//        }
//        
//        //Move down for the next view
//        yPos += [paneView frame].size.height;
//    }
//    
//    //Set the desired height of this view
//    [inView setDesiredHeight:yPos+2];
//}
//
//- (int)_heightForTabView:(NSTabView *)tabView
//{
//    NSEnumerator	*enumerator;
//    NSTabViewItem	*tabViewItem;
//    int				maxHeight = 0;
//
//    //Determine the tallest view contained within this tab view.
//    enumerator = [[tabView tabViewItems] objectEnumerator];
//    while(tabViewItem = [enumerator nextObject]){
//        NSEnumerator	*subViewEnumerator;
//        NSView		*subView;
//
//        subViewEnumerator = [[[tabViewItem view] subviews] objectEnumerator];
//        while(subView = [subViewEnumerator nextObject]){
//            int		height = [(AIPreferenceCategoryView *)subView desiredHeight];
//
//            if(height > maxHeight){
//                maxHeight = height;
//            }
//        }
//    }
//
//	return(maxHeight + TAB_PADDING_OFFSET + FRAME_PADDING_OFFSET);
//}
//
//Resize our window to fit the specified non-tabbed view
//- (int)_heightForFlatView:(AIPreferenceCategoryView *)view
//{
//	return([view desiredHeight] + FRAME_PADDING_OFFSET);
//}


//Advanced Preferences -------------------------------------------------------------------------------------------------
#pragma mark Advanced Preferences
//Restore everything the AIPreferencePane wants restored
- (IBAction)restoreDefaults:(id)sender
{
	int	selectedRow = [outlineView_advanced selectedRow];
	[[adium preferenceController] resetPreferencesInPane:[outlineView_advanced itemAtRow:selectedRow]];
}

//Set the displayed advanced pane
- (void)configureAdvancedPreferencesForPane:(AIPreferencePane *)preferencePane
{
	NSEnumerator		*enumerator;
	AIPreferencePane	*pane;
	
	//Close open panes
	enumerator = [loadedAdvancedPanes objectEnumerator];
	while(pane = [enumerator nextObject]){
		[pane closeView];
	}
	[view_Advanced removeAllSubviews];
	[loadedAdvancedPanes release]; loadedAdvancedPanes = nil;
	
	//Load new panes
	if(preferencePane){
		loadedAdvancedPanes = [[NSArray arrayWithObject:preferencePane] retain];
		[view_Advanced setPanes:loadedAdvancedPanes];
		[textField_advancedTitle setStringValue:[preferencePane label]];
	}

	//Disable the "Restore Defaults" button if there's nothing to restore
	[button_restoreDefaults setEnabled:([preferencePane restorablePreferences] != nil)];
}

//Returns the advanced preference categories
- (NSArray *)advancedCategoryArray
{
    if(!_advancedCategoryArray){
        _advancedCategoryArray = [[NSMutableArray alloc] init];
        
        //Load our advanced categories
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Contact List" forCategory:AIPref_Advanced_ContactList]];
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Messages" forCategory:AIPref_Advanced_Messages]];
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Status" forCategory:AIPref_Advanced_Status]];
        [_advancedCategoryArray addObject:[self _createGroupNamed:@"Other" forCategory:AIPref_Advanced_Other]];
    }
    
    return(_advancedCategoryArray);
}

//
- (NSDictionary *)_createGroupNamed:(NSString *)inName forCategory:(PREFERENCE_CATEGORY)category
{
    return([NSDictionary dictionaryWithObjectsAndKeys:
		inName, PREFERENCE_GROUP_NAME,
		[self _panesInCategory:category], PREFERENCE_PANE_ARRAY,
		nil]);
}

//Loads, alphabetizes, and caches prefs for the speficied category
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory
{
    NSMutableArray		*paneArray = [NSMutableArray array];
    NSEnumerator		*enumerator = [[[adium preferenceController] paneArray] objectEnumerator];
    AIPreferencePane	*pane;
    
    //Get the panes for this category
    while(pane = [enumerator nextObject]){
        if([pane category] == inCategory){
            [paneArray addObject:pane];
            [loadedPanes addObject:pane];
        }
    }
    
    //Alphabetize them
    [paneArray sortUsingSelector:@selector(compare:)];
    
    return(paneArray);
}


//Advanced Preferences (Outline View) ----------------------------------------------------------------------------------
#pragma mark Advanced Preferences (Outline View)
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){ //Root
        return([[self advancedCategoryArray] objectAtIndex:index]);
    }else{
        return([[item objectForKey:PREFERENCE_PANE_ARRAY] objectAtIndex:index]);
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[NSDictionary class]]){ //Only groups are expandable
        return(YES);
    }else{
        return(NO);
    }
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){ //Root
        return([[self advancedCategoryArray] count]);
    }else{
        return([[item objectForKey:PREFERENCE_PANE_ARRAY] count]);
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if([item isKindOfClass:[NSDictionary class]]){
        return([[[NSAttributedString alloc] initWithString:[item objectForKey:PREFERENCE_GROUP_NAME]
                                                attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:11]
																					   forKey:NSFontAttributeName]] autorelease]);
        
    }else if([item isKindOfClass:[AIPreferencePane class]]){
        float	cellWidth = [outlineView frameOfCellAtColumn:[outlineView indexOfTableColumn:tableColumn]
														 row:[outlineView rowForItem:item]].size.width - 4;
        return([[(AIPreferencePane *)item label] stringByTruncatingTailToWidth:cellWidth]);
    }
    
    return(nil);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if([item isKindOfClass:[AIPreferencePane class]]){
		[self configureAdvancedPreferencesForPane:item];
        return(YES);
    }else{
        return(NO);
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    return(YES);
}

@end
