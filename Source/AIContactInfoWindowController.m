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
#import "AIListOutlineView.h"

#define	CONTACT_INFO_NIB				@"ContactInfoWindow"			//Filename of the contact info nib
#define KEY_INFO_WINDOW_FRAME			@"Contact Info Window Frame"	//
#define KEY_INFO_SELECTED_CATEGORY		@"Selected Info Category"		//

#define	CONTACT_INFO_THEME				@"Contact Info List Theme"
#define	CONTACT_INFO_LAYOUT				@"Contact Info List Layout"

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)selectionChanged:(NSNotification *)notification;
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory;

- (void)configureDrawer;
- (void)setupMetaContactDrawer;

@end

@implementation AIContactInfoWindowController

static AIContactInfoWindowController *sharedContactInfoInstance = nil;

//Return the shared contact info window
+ (id)showInfoWindowForListObject:(AIListObject *)listObject
{
    //Create the window
    if(!sharedContactInfoInstance){
        sharedContactInfoInstance = [[self alloc] initWithWindowNibName:CONTACT_INFO_NIB];
		
		//Remove those buttons we don't want.  removeFromSuperview will confuse the window, so just make them invisible.
		NSButton *standardWindowButton = [[sharedContactInfoInstance window] standardWindowButton:NSWindowMiniaturizeButton];
		[standardWindowButton setFrame:NSMakeRect(0,0,0,0)];
		standardWindowButton = [[sharedContactInfoInstance window] standardWindowButton:NSWindowZoomButton];
		[standardWindowButton setFrame:NSMakeRect(0,0,0,0)];
    }
	
	//Configure and show window
	
	//Find the highest-up metaContact so our info is accurate
	
	AIListObject	*containingObject;
	while ([(containingObject = [listObject containingObject]) isKindOfClass:[AIMetaContact class]]){
		listObject = containingObject;
	}

	[sharedContactInfoInstance configureForListObject:listObject];
	[sharedContactInfoInstance showWindow:nil];
	
	return (sharedContactInfoInstance);
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
	[displayedObject release]; displayedObject = nil;
	[loadedPanes release]; loadedPanes = nil;
    [super dealloc];
}	

//Setup the window before it is displayed
- (void)windowDidLoad
{    
	[super windowDidLoad];
	
	int             selectedTab;
    NSTabViewItem   *tabViewItem;
	NSString		*savedFrame;

    //
	loadedPanes = [[NSMutableSet alloc] init];
	[[self window] setHidesOnDeactivate:NO];
	[(NSPanel *)[self window] setFloatingPanel:NO];
	
    //Select the previously selected category
    selectedTab = [[[adium preferenceController] preferenceForKey:KEY_INFO_SELECTED_CATEGORY
															group:PREF_GROUP_WINDOW_POSITIONS] intValue];
    if(selectedTab < 0 || selectedTab >= [tabView_category numberOfTabViewItems]) selectedTab = 0;
	
    tabViewItem = [tabView_category tabViewItemAtIndex:selectedTab];
	
	//NSTabView won't send the willSelectTabViewItem: properly when we call selectTabViewItem:
    [self tabView:tabView_category willSelectTabViewItem:tabViewItem];
    [tabView_category selectTabViewItem:tabViewItem];    
	
	if ([imageView_userIcon respondsToSelector:@selector(setAnimates:)]) [imageView_userIcon setAnimates:YES];
	[imageView_userIcon setImageFrameStyle:NSImageFramePhoto];
		
	//Monitor the selected contact
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(selectionChanged:)
									   name:Interface_ContactSelectionChanged 
									 object:nil];
    
	//Restore the window position
    savedFrame = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_INFO_WINDOW_FRAME];
    if(savedFrame){
        [[self window] setFrameFromString:savedFrame];
    }else{
        [[self window] center];
    }
	
	[self setupMetaContactDrawer];
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
	if (tabView == tabView_category){
		return([NSImage imageNamed:[NSString stringWithFormat:@"info%@",[tabViewItem identifier]] forClass:[self class]]);
	}
	
	return nil;
}

//
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (tabView == tabView_category){
		int	identifier = [[tabViewItem identifier] intValue];
		
		//Take focus away from any controls to ensure that they register changes and save
		//    [[self window] makeFirstResponder:tabView_category];
		[[self window] makeFirstResponder:nil];
		
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
	AIListObject	*object = [[adium contactController] selectedListObject];
	if(object) [self configureForListObject:[[adium contactController] selectedListObject]];
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
			[[self window] setTitle:[NSString stringWithFormat:AILocalizedString(@"%@'s Info",nil),[inObject displayName]]];
		}else{
			[[self window] setTitle:AILocalizedString(@"Contact Info",nil)];
		}
		
		//Account name
		if (inObject){
			NSString	*formattedUID = [inObject formattedUID];
			[textField_accountName setStringValue:(formattedUID ? formattedUID : [inObject displayName])];	
		}else{
			[textField_accountName setStringValue:@""];
		}
			
		//Service
		if([inObject isKindOfClass:[AIListContact class]]){
			NSString	*displayServiceID = [inObject displayServiceID];
			[textField_service setStringValue:(displayServiceID ? displayServiceID : META_SERVICE_STRING)];
		}
		
		//User Icon
		if(!(userImage = [displayedObject userIcon])){
			userImage = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
		}
		[imageView_userIcon setImageScaling:NSScaleProportionally];
		[imageView_userIcon setImage:userImage];
		[imageView_userIcon setTitle:(inObject ? 
									  [NSString stringWithFormat:AILocalizedString(@"%@'s Image",nil),[inObject displayName]] :
									  AILocalizedString(@"Image Picker",nil))];
		//Configure our subpanes
		[self configurePanes];
		
		//Confiugre the drawer
		[self configureDrawer];

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

#pragma mark ESImageViewWithImagePicker Delegate
// ESImageViewWithImagePicker Delegate ---------------------------------------------------------------------
- (void)imageViewWithImagePicker:(ESImageViewWithImagePicker *)sender didChangeToImage:(NSImage *)image
{
	if (displayedObject){
		[displayedObject setUserIconData:[image PNGRepresentation]];
	}
}

- (void)deleteInImageViewWithImagePicker:(ESImageViewWithImagePicker *)sender
{
	if (displayedObject){
		NSImage *userImage;
		
		//Remove the preference
		[displayedObject setUserIconData:nil];
	
		//User Icon
		if(!(userImage = [displayedObject userIcon])){
			userImage = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
		}
		[imageView_userIcon setImage:userImage];
	}
}

#pragma mark Contact List (metaContact)
- (void)setupMetaContactDrawer
{
	NSDictionary	*themeDict = [NSDictionary dictionaryNamed:CONTACT_INFO_THEME forClass:[self class]];
	NSDictionary	*layoutDict = [NSDictionary dictionaryNamed:CONTACT_INFO_LAYOUT forClass:[self class]];

	[self updateLayoutFromPrefDict:layoutDict];
	[self updateCellRelatedThemePreferencesFromDict:themeDict];
	[self updateTransparencyFromLayoutDict:layoutDict themeDict:themeDict];	

	[self setHideRoot:NO];
}

- (void)configureDrawer
{
	AIListObject	*listObject = displayedObject;
	
	//Find the highest-up metaContact
	AIListObject	*containingObject;
	while ([(containingObject = [listObject containingObject]) isKindOfClass:[AIMetaContact class]]){
		listObject = containingObject;
	}	
	
	if ([listObject isKindOfClass:[AIMetaContact class]] &&
		![(AIMetaContact *)listObject containsOnlyOneUniqueContact]){
		[self setContactListRoot:listObject];
		[drawer_metaContact open];
	
	}else{
		[drawer_metaContact close];	
		[self setContactListRoot:nil];
	}
}

//The superclass's implementation does not expand metaContacts
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
		if (hideRoot){
			if ([contactList isKindOfClass:[AIMetaContact class]]){
				return((index >= 0 && index < [(AIMetaContact *)contactList uniqueContainedObjectsCount]) ?
					   [(AIMetaContact *)contactList uniqueObjectAtIndex:index] : 
					   nil);
			}else{
				return((index >= 0 && index < [contactList containedObjectsCount]) ? [contactList objectAtIndex:index] : nil);
			}
		}else{
			return contactList;
		}
    }else{
		if ([item isKindOfClass:[AIMetaContact class]]){
			return((index >= 0 && index < [(AIMetaContact *)item uniqueContainedObjectsCount]) ? 
				   [(AIMetaContact *)item uniqueObjectAtIndex:index] : 
				   nil);
		}else{
			return((index >= 0 && index < [item containedObjectsCount]) ? [item objectAtIndex:index] : nil);
		}
    }
}

//The superclass's implementation does not expand metaContacts
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
		if (hideRoot){
			if ([contactList isKindOfClass:[AIMetaContact class]]){
				return([(AIMetaContact *)contactList uniqueContainedObjectsCount]);
			}else{
				return([contactList containedObjectsCount]);
			}
		}else{
			return(1);
		}
    }else{
		if ([item isKindOfClass:[AIMetaContact class]]){
			return([(AIMetaContact *)item uniqueContainedObjectsCount]);
		}else{
			return([item containedObjectsCount]);
		}
    }
}

//The superclass's implementation does not expand metaContacts
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[AIMetaContact class]] || [item isKindOfClass:[AIListGroup class]]){
        return(YES);
    }else{
        return(NO);
    }
}

//Change the info window as the selection changes
- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == contactListView){
		[sharedContactInfoInstance configureForListObject:[contactListView itemAtRow:[contactListView selectedRow]]];
	}
}

//Due to a bug in NSDrawer, convertPoint:fromView reports a point too low by the trailingOffset 
//when our contact list is in a drawer.
- (AIListObject *)contactListItemAtScreenPoint:(NSPoint)screenPoint
{
	NSPoint			viewPoint = [contactListView convertPoint:[[self window] convertScreenToBase:screenPoint] fromView:nil];
	
	viewPoint.y += [drawer_metaContact trailingOffset];
	
	AIListObject	*hoveredObject = [contactListView itemAtRow:[contactListView rowAtPoint:viewPoint]];
	
	return(hoveredObject);
}

//We want to just show UIDs whereever possible
- (BOOL)useAliasesInContactListAsRequested
{
	return NO;
}
@end
