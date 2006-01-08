/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactAccountsPane.h"
#import "AIContactInfoWindowController.h"
#import "AIContactProfilePane.h"
#import "AIContactSettingsPane.h"
#import "AIInterfaceController.h"
#import "AIListOutlineView.h"
#import "AIPreferenceController.h"
#import "AIAccountController.h"
#import "ESContactAlertsPane.h"
#import "ESContactInfoListController.h"
#import "ESContactAlertsController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AITabViewAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIModularPaneCategoryView.h>
#import <Adium/AIService.h>

#define	CONTACT_INFO_NIB				@"ContactInfoWindow"			//Filename of the contact info nib
#define KEY_INFO_WINDOW_FRAME			@"Contact Info Window Frame"	//
#define KEY_INFO_SELECTED_CATEGORY		@"Selected Info Category"		//

#define	CONTACT_INFO_THEME				@"Contact Info List Theme"
#define	CONTACT_INFO_LAYOUT				@"Contact Info List Layout"

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)selectionChanged:(NSNotification *)notification;
- (NSArray *)_panesInCategory:(PREFERENCE_CATEGORY)inCategory;

- (void)localizeTabViewItemTitles;
- (void)configureDrawer;
- (void)setupMetaContactDrawer;

@end

@implementation AIContactInfoWindowController

static AIContactInfoWindowController *sharedContactInfoInstance = nil;

//Return the shared contact info window
+ (id)showInfoWindowForListObject:(AIListObject *)listObject
{
	static BOOL didLoadPanes = NO;
	if (!didLoadPanes) {
		//Install our panes
		[AIContactAccountsPane contactInfoPane];
		[AIContactProfilePane contactInfoPane];
		[AIContactSettingsPane contactInfoPane];
		[ESContactAlertsPane contactInfoPane];

		didLoadPanes = YES;
	}

	//Create the window
	if (!sharedContactInfoInstance) {
		sharedContactInfoInstance = [[self alloc] initWithWindowNibName:CONTACT_INFO_NIB];
	}

	//Configure and show window

	if ([listObject isKindOfClass:[AIListContact class]]) {
		AIListContact *parentContact = [(AIListContact *)listObject parentContact];
		
		/* Use the parent contact if it is a valid meta contact which contains contacts
		 * If this contact is within a metacontact but not currently listed on any buddy list, we don't want to 
		 * display the effectively-invisible metacontact's info but rather the info of this contact itself.
		 */
		if (![parentContact isKindOfClass:[AIMetaContact class]] ||
			[[(AIMetaContact *)parentContact listContacts] count]) {
			listObject = parentContact;
		}
	}

	[sharedContactInfoInstance configureForListObject:listObject];
	[[sharedContactInfoInstance window] makeKeyAndOrderFront:nil];

	return (sharedContactInfoInstance);
}

//Close the info window
+ (void)closeInfoWindow
{
	if (sharedContactInfoInstance) {
		[sharedContactInfoInstance closeWindow:nil];
	}
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
	self = [super initWithWindowNibName:windowNibName];

	return self;
}

- (void)dealloc
{
	[displayedObject release]; displayedObject = nil;
	[loadedPanes release]; loadedPanes = nil;

	[super dealloc];
}

//
- (NSString *)adiumFrameAutosaveName
{
	return KEY_INFO_WINDOW_FRAME;
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[super windowDidLoad];

	int				 selectedTab;
	NSTabViewItem   *tabViewItem;

	//
	loadedPanes = [[NSMutableSet alloc] init];

	//Localization
	[self localizeTabViewItemTitles];
	[button_removeContact setToolTip:AILocalizedString(@"Disassociate the selected contact from this meta contact. This does not remove the contact from your contact list.",nil)];
	[button_removeContact setEnabled:NO];

	//Select the previously selected category
	selectedTab = [[[adium preferenceController] preferenceForKey:KEY_INFO_SELECTED_CATEGORY
															group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	if (selectedTab < 0 || selectedTab >= [tabView_category numberOfTabViewItems]) selectedTab = 0;

	tabViewItem = [tabView_category tabViewItemAtIndex:selectedTab];

	//NSTabView won't send the willSelectTabViewItem: properly when we call selectTabViewItem:
	[self tabView:tabView_category willSelectTabViewItem:tabViewItem];
	[tabView_category selectTabViewItem:tabViewItem];

	[imageView_userIcon setAnimates:YES];

	//Monitor the selected contact
	[[adium notificationCenter] addObserver:self
								   selector:@selector(selectionChanged:)
									   name:Interface_ContactSelectionChanged
									 object:nil];

	contactListController = [[ESContactInfoListController alloc] initWithContactListView:contactListView
																			inScrollView:scrollView_contactList
																				delegate:self];
	[self setupMetaContactDrawer];
}

- (void)localizeTabViewItemTitles
{
	NSEnumerator	*enumerator = [[tabView_category tabViewItems] objectEnumerator];
	NSTabViewItem	*tabViewItem;
	while ((tabViewItem = [enumerator nextObject])) {
		NSString	*label = nil;
		int			identifier = [[tabViewItem identifier] intValue];

		switch (identifier) {
			case AIInfo_Profile:
				label = AILocalizedString(@"Info","short form of tab view item title for Contact Info window's first tab");
				break;
			case AIInfo_Accounts:
				label = ACCOUNTS_TITLE;
				break;
			case AIInfo_Alerts:
				label = EVENTS_TITLE;
				break;
			case AIInfo_Settings:
				label = AILocalizedString(@"Settings","tab view item title for Contact Settings (Settings)");
				break;
		}

		[tabViewItem setLabel:label];
	}
}

//called as the window closes
- (void)windowWillClose:(id)sender
{
	NSEnumerator 		*enumerator;
	AIContactInfoPane	*pane;

	[super windowWillClose:sender];

	//Take focus away from any controls to ensure that they register changes and save
	[[self window] makeFirstResponder:tabView_category];

	//Close all open panes
	enumerator = [loadedPanes objectEnumerator];
	while ((pane = [enumerator nextObject])) {
		[pane closeView];
	}

	//Save the selected category
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[tabView_category indexOfSelectedTabViewItem]]
										 forKey:KEY_INFO_SELECTED_CATEGORY
										  group:PREF_GROUP_WINDOW_POSITIONS];

	//Close down
	[[adium notificationCenter] removeObserver:self];
	[self autorelease]; sharedContactInfoInstance = nil;
}

- (NSImage *)tabView:(NSTabView *)tabView imageForTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (tabView == tabView_category) {
		return [NSImage imageNamed:[NSString stringWithFormat:@"info%@",[tabViewItem identifier]] forClass:[self class]];
	}

	return nil;
}

//
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (tabView == tabView_category) {
		int	identifier = [[tabViewItem identifier] intValue];

		//Take focus away from any controls to ensure that they register changes and save
		//	[[self window] makeFirstResponder:tabView_category];
		[[self window] makeFirstResponder:nil];

		switch (identifier) {
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
		if ([[[self window] toolbar] respondsToSelector:@selector(setSelectedItemIdentifier:)]) {
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
	while ((pane = [enumerator nextObject])) {
		if ([pane contactInfoCategory] == inCategory) {
			[paneArray addObject:pane];
			[loadedPanes addObject:pane];
		}
	}

	//Alphabetize them
	[paneArray sortUsingSelector:@selector(compare:)];

	return paneArray;
}

//When the contact list selection changes, then configure the window for the new contact
- (void)selectionChanged:(NSNotification *)notification
{
	AIListObject	*object = [[adium contactController] selectedListObject];
	if (object) [self configureForListObject:[[adium contactController] selectedListObject]];
}

//Change the list object
- (void)configureForListObject:(AIListObject *)inObject
{
	if (inObject == nil || displayedObject != inObject) {
		NSImage		*userIcon;
		NSSize		userIconSize, imageView_userIconSize;
		BOOL		useDisplayName = NO;

		//Update our displayed object
		[displayedObject release];
		displayedObject = [inObject retain];

		//Update our window title
		if (inObject) {
			[[self window] setTitle:[NSString stringWithFormat:AILocalizedString(@"%@'s Info",nil),[inObject displayName]]];
		} else {
			[[self window] setTitle:AILocalizedString(@"Contact Info",nil)];
		}

		//Service
		if ([inObject isKindOfClass:[AIListContact class]]) {
			NSString	*displayServiceID;
			if ([inObject isKindOfClass:[AIMetaContact class]]) {
				if ([[(AIMetaContact *)inObject listContacts] count] > 1) {
					displayServiceID = META_SERVICE_STRING;
					useDisplayName = YES;
				} else {
					displayServiceID = [[[(AIMetaContact *)inObject preferredContact] service] shortDescription];
				}

			} else {
				displayServiceID = [[inObject service] shortDescription];
			}

			[textField_service setStringValue:(displayServiceID ? displayServiceID : @"")];

		} else if ([inObject isKindOfClass:[AIListGroup class]]) {
			[textField_service setLocalizedString:AILocalizedString(@"Group",nil)];
		} else {
			[textField_service setStringValue:@""];
		}

		//Account name
		if (inObject) {
			NSString	*formattedUID;

			if (!useDisplayName && (formattedUID = [inObject formattedUID])) {
				[textField_accountName setStringValue:formattedUID];
			} else {
				NSString	*displayName;

				if ((displayName = [inObject displayName])) {
					[textField_accountName setStringValue:displayName];
				} else {
					[textField_accountName setStringValue:[inObject UID]];
				}
			}

		} else {
			[textField_accountName setStringValue:@""];
		}

		//User Icon
		if (!(userIcon = [displayedObject userIcon])) {
			userIcon = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
		}

		//NSScaleProportionally will lock an animated GIF into a single frame.  We therefore use NSScaleNone if
		//we are already at the right size or smaller than the right size; otherwise we scale proportionally to
		//fit the frame.
		userIconSize = [userIcon size];
		imageView_userIconSize = [imageView_userIcon frame].size;

		[imageView_userIcon setImageScaling:(((userIconSize.width <= imageView_userIconSize.width) && (userIconSize.height <= imageView_userIconSize.height)) ?
											 NSScaleNone :
											 NSScaleProportionally)];
		[imageView_userIcon setImage:userIcon];
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
	if (displayedObject) {
		NSEnumerator		*enumerator = [loadedPanes objectEnumerator];
		AIContactInfoPane	*pane;

		while ((pane = [enumerator nextObject])) {
			[pane configureForListObject:displayedObject];
		}
	}
}

#pragma mark AIImageViewWithImagePicker Delegate
// AIImageViewWithImagePicker Delegate ---------------------------------------------------------------------
- (void)imageViewWithImagePicker:(AIImageViewWithImagePicker *)sender didChangeToImageData:(NSData *)imageData
{
	if (displayedObject) {
		[displayedObject setUserIconData:imageData];
	}
}

- (void)deleteInImageViewWithImagePicker:(AIImageViewWithImagePicker *)sender
{
	if (displayedObject) {
		NSImage *userImage;

		//Remove the preference
		[displayedObject setUserIconData:nil];

		//User Icon
		if (!(userImage = [displayedObject userIcon])) {
			userImage = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
		}
		[imageView_userIcon setImage:userImage];
	}
}

/*
 If the userIcon was bigger than our image view's frame, it will have been clipped before being passed
 to the AIImageViewWithImagePicker.  This delegate method lets us pass the original, unmodified userIcon.
 */
- (NSImage *)imageForImageViewWithImagePicker:(AIImageViewWithImagePicker *)picker
{
	return ([displayedObject userIcon]);
}

#pragma mark Contact List (metaContact)
- (void)setupMetaContactDrawer
{
	NSDictionary	*themeDict = [NSDictionary dictionaryNamed:CONTACT_INFO_THEME forClass:[self class]];
	NSDictionary	*layoutDict = [NSDictionary dictionaryNamed:CONTACT_INFO_LAYOUT forClass:[self class]];

	[contactListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];

	[contactListController setHideRoot:YES];
}

- (void)configureDrawer
{
	AIListObject	*listObject = ([displayedObject isKindOfClass:[AIListContact class]] ?
								   [(AIListContact *)displayedObject parentContact] :
								   displayedObject);
	
	if ([listObject isKindOfClass:[AIMetaContact class]] &&
		([[(AIMetaContact *)listObject listContacts] count] > 1)) {
		[contactListController setContactListRoot:(AIMetaContact *)listObject];
		[drawer_metaContact open];

		NSRect	outlineFrame = [contactListView frame];
		int		totalHeight = [contactListView totalHeight];

		if (outlineFrame.size.height != totalHeight) {
			outlineFrame.size.height = totalHeight;
			[contactListView setFrame:outlineFrame];
			[contactListView setNeedsDisplay:YES];
		}

	} else {
		[drawer_metaContact close];
		[contactListController setContactListRoot:nil];
	}
}

- (IBAction)addContact:(id)sender
{

}

- (IBAction)removeContact:(id)sender
{
	NSEnumerator	*enumerator;
	AIListObject	*aListObject;
	AIMetaContact	*contactListRoot = (AIMetaContact *)[contactListController contactListRoot];

	enumerator = [[contactListView arrayOfSelectedItems] objectEnumerator];
	while ((aListObject = [enumerator nextObject])) {
		[[adium contactController] removeAllListObjectsMatching:aListObject
												fromMetaContact:contactListRoot];
	}

	//The contents of the metaContact have now changed; reload
	[contactListView reloadData];

	[contactListController outlineViewSelectionDidChange:nil];
}

- (float)drawerTrailingOffset
{
	return [drawer_metaContact trailingOffset];
}

- (void)performDefaultActionOnSelectedObject:(AIListObject *)listObject sender:(NSOutlineView *)sender
{

}

- (void)contactInfoListControllerSelectionDidChangeToListObject:(AIListObject *)listObject
{
	AILog(@"Configuring Info List for %@",listObject);
	[self configureForListObject:listObject];

	//Only enable the remove contact button if a contact within the metacontact is selected
	[button_removeContact setEnabled:(listObject && (listObject != (AIListObject *)[contactListController contactListRoot]))];
}

@end
