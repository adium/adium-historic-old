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

#import "AIContactInfoWindowController.h"
#import "AIContactAccountsPane.h"
#import "AIContactProfilePane.h"
#import "AIContactSettingsPane.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIListOutlineView.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import "ESContactAlertsPane.h"
#import "ESContactInfoListController.h"
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AITabViewAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import "AIListOutlineView.h"
#import <Adium/AIMetaContact.h>
#import "AIModularPaneCategoryView.h"
#import <Adium/AIService.h>

#define	CONTACT_INFO_NIB				@"ContactInfoWindow"			//Filename of the contact info nib
#define KEY_INFO_WINDOW_FRAME			@"Contact Info Window Frame"	//
#define KEY_INFO_SELECTED_CATEGORY		@"Selected Info Category"		//

#define	CONTACT_INFO_THEME				@"Contact Info List Theme"
#define	CONTACT_INFO_LAYOUT				@"Contact Info List Layout"

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)selectionChanged:(NSNotification *)notification;

- (void)localizeTabViewItemTitles;
- (void)configureDrawer;
- (void)configureVisiblityOfTabViewItemsForListObject:(AIListObject *)inObject;
- (void)configurePane:(AIContactInfoPane *)inPane;
- (void)setupMetaContactDrawer;

@end

@implementation AIContactInfoWindowController

static AIContactInfoWindowController *sharedContactInfoInstance = nil;

//Return the shared contact info window
+ (id)showInfoWindowForListObject:(AIListObject *)listObject
{
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

- (void)dealloc
{
	//If we removed the account and info tab view items, we're currently also retaining them
	if ([tabView_category indexOfTabViewItem:tabViewItem_info] == NSNotFound) {
		[tabViewItem_accounts release]; tabViewItem_accounts = nil;
		[tabViewItem_info release]; tabViewItem_info = nil;
	}

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
	loadedPanes = [[NSMutableDictionary alloc] init];

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
				label = AILocalizedString(@"Accounts",nil);
				break;
			case AIInfo_Alerts:
				label = AILocalizedString(@"Events", "Name of preferences and tab for specifying what Adium should do when events occur - for example, when display a Growl alert when John signs on.");
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
		AIContactInfoPane *pane = nil;
		
		//Take focus away from any textual controls to ensure that they register changes and save
		if ([[[self window] firstResponder] isKindOfClass:[NSText class]]) {
			[[self window] makeFirstResponder:nil];
		}
		
		int identifier = [[tabViewItem identifier] intValue];
		if (!(pane = [loadedPanes objectForKey:[NSNumber numberWithInt:identifier]])) {
			switch (identifier) {
				case AIInfo_Profile:
					pane = [AIContactProfilePane contactInfoPane];
					[view_Profile setPanes:[NSArray arrayWithObject:pane]];

					break;
				case AIInfo_Accounts:
					pane = [AIContactAccountsPane contactInfoPane];
					[view_Accounts setPanes:[NSArray arrayWithObject:pane]];
					break;
				case AIInfo_Alerts:
					pane = [ESContactAlertsPane contactInfoPane];
					[view_Alerts setPanes:[NSArray arrayWithObject:pane]];
					break;
				case AIInfo_Settings:
					pane = [AIContactSettingsPane contactInfoPane];
					[view_Settings setPanes:[NSArray arrayWithObject:pane]];
					break;
			}
			
			if (pane) {
				[loadedPanes setObject:pane
								forKey:[NSNumber numberWithInt:identifier]];
			} else {
				NSLog(@"%@: Could not load pane for identifier %i",self,identifier);
			}
		}

		//Configure the loaded panes
		[self configurePane:pane];
	}
}

//When the contact list selection changes, then configure the window for the new contact
- (void)selectionChanged:(NSNotification *)notification
{
	AIListObject	*object = [[adium interfaceController] selectedListObject];
	if (object) [self configureForListObject:[[adium interfaceController] selectedListObject]];
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
		[self configureVisiblityOfTabViewItemsForListObject:inObject];

		//Confiugre the drawer
		[self configureDrawer];
		
		//Reconfigure the currently selected tab view item
		[self tabView:tabView_category willSelectTabViewItem:[tabView_category selectedTabViewItem]];

	}
}

//Configure our views
- (void)configurePane:(AIContactInfoPane *)pane
{
	if (displayedObject) {
		[pane configureForListObject:displayedObject];
	}
}

- (void)configureVisiblityOfTabViewItemsForListObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListGroup class]]) {
		//Remove the info and account items for groups
		if ([tabView_category indexOfTabViewItem:tabViewItem_info] != NSNotFound) {
			[tabViewItem_accounts retain];
			[tabViewItem_info retain];
			
			//Store the tab view item selected out of accounts or info, if one is selected
			NSTabViewItem *currentlySelected = [tabView_category selectedTabViewItem];
			tabViewItem_lastSelectedForListContacts = ((currentlySelected == tabViewItem_accounts || currentlySelected == tabViewItem_info) ?
													   currentlySelected :
													   nil);

			[tabView_category removeTabViewItem:tabViewItem_accounts];
			[tabView_category removeTabViewItem:tabViewItem_info];
		}
		
	} else {
		//Add the info and account items back in if they are missing
		if ([tabView_category indexOfTabViewItem:tabViewItem_info] == NSNotFound) {
			[tabView_category insertTabViewItem:tabViewItem_accounts atIndex:0];
			[tabView_category insertTabViewItem:tabViewItem_info atIndex:0];
			
			//Restore the tab view item last selected for a contact if we have one stored
			if (tabViewItem_lastSelectedForListContacts) {
				[tabView_category selectTabViewItem:tabViewItem_lastSelectedForListContacts];
				tabViewItem_lastSelectedForListContacts = nil;
			}
			
			[tabViewItem_accounts release];
			[tabViewItem_info release];
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

- (NSString *)fileNameForImageInImagePicker:(AIImageViewWithImagePicker *)picker
{
	return [[displayedObject displayName] safeFilenameString];
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
