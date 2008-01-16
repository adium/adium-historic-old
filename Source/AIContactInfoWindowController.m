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
#import "ESContactAlertsPane.h"
#import "ESContactInfoListController.h"
#import "AIContactInfoImageViewWithImagePicker.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIModularPaneCategoryView.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITabViewAdditions.h>

#define	CONTACT_INFO_NIB				@"ContactInfoInspector"			//Filename of the contact info nib
#define KEY_INFO_WINDOW_FRAME			@"Contact Info Inspector Frame"	//
#define KEY_INFO_SELECTED_CATEGORY		@"Selected Info Category"		//

#define	CONTACT_INFO_THEME				@"Contact Info List Theme"
#define	CONTACT_INFO_LAYOUT				@"Contact Info List Layout"

enum segments {
	CONTACT_INFO_SEGMENT = 0,
	CONTACT_ADDRESSBOOK_SEGMENT = 1,
	CONTACT_EVENTS_SEGMENT = 2,
	CONTACT_ADVANCED_SEGMENT = 3
};

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)selectionChanged:(NSNotification *)notification;
- (void)localizeSegmentTitles;
- (void)configureSegmentsForListObject:(AIListObject *)inObject;
@end

@implementation AIContactInfoWindowController

static AIContactInfoWindowController *sharedContactInfoInstance = nil;

#pragma mark CFI

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
	[displayedObject release]; displayedObject = nil;
	[loadedPanes release]; loadedPanes = nil;
	
	[super dealloc];
}


- (NSString *)adiumFrameAutosaveName
{
	return KEY_INFO_WINDOW_FRAME;
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[super windowDidLoad];

	int	selectedSegment;

	//
	loadedPanes = [[NSMutableDictionary alloc] init];

	//Localization
	[self localizeSegmentTitles];
	[removeContact setToolTip:AILocalizedString(@"Disassociate the selected contact from this meta contact. This does not remove the contact from your contact list.",nil)];
	[removeContact setEnabled:NO];

	//Select the previously selected category
	selectedSegment = [[[adium preferenceController] preferenceForKey:KEY_INFO_SELECTED_CATEGORY
															group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	if (selectedSegment < 0 || selectedSegment >= [inspectorToolbar segmentCount]) selectedSegment = 0;

	[inspectorToolbar setSelectedSegment:selectedSegment];

	[userIcon setAnimates:YES];
	[userIcon setMaxSize:NSMakeSize(256, 256)];

	//Monitor the selected contact
	[[adium notificationCenter] addObserver:self
								   selector:@selector(selectionChanged:)
									   name:Interface_ContactSelectionChanged
									 object:nil];

	//contactListController = [[ESContactInfoListController alloc] initWithContactListView:contactListView
//																			inScrollView:scrollView_contactList
//																				delegate:self];
}

- (void)localizeSegmentTitles
{	
	int i;
	for(i = 0; i < [inspectorToolbar segmentCount]; i++) {
		NSString	*label = nil;

		switch (i) {
			case CONTACT_INFO_SEGMENT:
				label = AILocalizedString(@"Status and Profile","This segment displays the status and profile information for the selected contact.");
				break;
			case CONTACT_ADDRESSBOOK_SEGMENT:
				label = AILocalizedString(@"Contact Information", "This segment displays contact and alias information for the selected contact.");
				break;
			case CONTACT_EVENTS_SEGMENT:
				label = AILocalizedString(@"Events", "This segment displays controls for a user to set up events for this contact.");
				break;
			case CONTACT_ADVANCED_SEGMENT:
				label = AILocalizedString(@"Advanced Settings","This segment displays the advanced settings for a contact, including encryption details and account information.");
				break;
		}

		AILog(@"%@", label);

		[(NSSegmentedCell *)[inspectorToolbar cell] setToolTip:label forSegment:i];
	}
}

//called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	//Take focus away from any controls to ensure that they register changes and save
	//Not really sure if we'll need to do this for the new inspector, so i'm just commenting it out - EBH
	//[[self window] makeFirstResponder:tabView_category];

	//Save the selected category
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[inspectorToolbar selectedSegment]]
										 forKey:KEY_INFO_SELECTED_CATEGORY
										  group:PREF_GROUP_WINDOW_POSITIONS];

	//Close down
	[[adium notificationCenter] removeObserver:self];
	[self autorelease]; sharedContactInfoInstance = nil;
}

#pragma mark non-CFI

//When the contact list selection changes, then configure the window for the new contact
- (void)selectionChanged:(NSNotification *)notification
{
	AIListObject	*object = [[adium interfaceController] selectedListObject];
	if (object) [self configureForListObject:[[adium interfaceController] selectedListObject]];
}

- (void)updateUserIcon
{
	NSImage		*currentIcon;
	NSSize		userIconSize, imagePickerSize;

	//User Icon
	if (!(currentIcon = [displayedObject userIcon])) {
		currentIcon = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
	}
	
	/* NSScaleProportionally will lock an animated GIF into a single frame.  We therefore use NSScaleNone if
	 * we are already at the right size or smaller than the right size; otherwise we scale proportionally to
	 * fit the frame.
	 */
	userIconSize = [currentIcon size];
	imagePickerSize = [userIcon frame].size;
	
	[userIcon setImageScaling:(((userIconSize.width <= userIconSize.width) && (userIconSize.height <= userIconSize.height)) ?
										 NSScaleNone :
										 NSScaleProportionally)];
	[userIcon setImage:currentIcon];
	[userIcon setTitle:(displayedObject ?
								  [NSString stringWithFormat:AILocalizedString(@"%@'s Image",nil),[displayedObject displayName]] :
								  AILocalizedString(@"Image Picker",nil))];

	//Show the reset image button if a preference is set on this object, overriding its serverside icon
	[userIcon setShowResetImageButton:([displayedObject preferenceForKey:KEY_USER_ICON
																			 group:PREF_GROUP_USERICONS
															 ignoreInheritedValues:YES] != nil)];
}

//Change the list object
- (void)configureForListObject:(AIListObject *)inObject
{
	if (inObject == nil || displayedObject != inObject) {
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
					displayServiceID = AILocalizedString(@"Meta", "Short string used to identify the 'service' of a multiple-service meta contact");
					useDisplayName = YES;
				} else {
					displayServiceID = [[[(AIMetaContact *)inObject preferredContact] service] shortDescription];
				}

			} else {
				displayServiceID = [[inObject service] shortDescription];
			}

			[serviceName setStringValue:(displayServiceID ? displayServiceID : @"")];

		} else if ([inObject isKindOfClass:[AIListGroup class]]) {
			[serviceName setLocalizedString:AILocalizedString(@"Group",nil)];
		} else {
			[serviceName setStringValue:@""];
		}

		//Account name
		if (inObject) {
			NSString	*formattedUID;

			if (!useDisplayName && (formattedUID = [inObject formattedUID])) {
				[accountName setStringValue:formattedUID];
			} else {
				NSString	*displayName;

				if ((displayName = [inObject displayName])) {
					[accountName setStringValue:displayName];
				} else {
					[accountName setStringValue:[inObject UID]];
				}
			}

		} else {
			[accountName setStringValue:@""];
		}

		[self updateUserIcon];

		//Configure our subpanes
		[self configureSegmentsForListObject:inObject];
		
		//Reconfigure the currently selected tab view item
		//[self tabView:tabView_category willSelectTabViewItem:[tabView_category selectedTabViewItem]];

	}
}

- (void)configureSegmentsForListObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListGroup class]]) {
		//Remove the info and account items for groups
		if ([inspectorToolbar isEnabledForSegment:CONTACT_INFO_SEGMENT]) {

			//Store the tab view item selected out of accounts or info, if one is selected
			int currentSegment = [inspectorToolbar selectedSegment];
			lastSegmentForContact = ((currentSegment == CONTACT_INFO_SEGMENT) ?
													   currentSegment :
													   0);

			[inspectorToolbar setEnabled:NO forSegment:CONTACT_INFO_SEGMENT];
		}
		
	} else {
		//Add the info and account items back in if they are missing
		if (![inspectorToolbar isEnabledForSegment:CONTACT_INFO_SEGMENT]) {
			[inspectorToolbar setEnabled:YES forSegment:CONTACT_INFO_SEGMENT];
			
			//Restore the tab view item last selected for a contact if we have one stored
			if (lastSegmentForContact != NULL) {
				[inspectorToolbar setSelectedSegment:lastSegmentForContact];
				lastSegmentForContact = NULL;
			}

		}			
	}
	
#warning need to hide panes for bookmarks
}

#pragma mark AIImageViewWithImagePicker Delegate
// AIImageViewWithImagePicker Delegate ---------------------------------------------------------------------
- (void)imageViewWithImagePicker:(AIImageViewWithImagePicker *)sender didChangeToImageData:(NSData *)imageData
{
	if (displayedObject) {
		[displayedObject setUserIconData:imageData];
	}
	
	[self updateUserIcon];
}

- (void)deleteInImageViewWithImagePicker:(AIImageViewWithImagePicker *)sender
{
	if (displayedObject) {
		//Remove the preference
		[displayedObject setUserIconData:nil];

		[self updateUserIcon];
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

- (NSImage *)emptyPictureImageForImageViewWithImagePicker:(AIImageViewWithImagePicker *)picker
{
	return [AIServiceIcons serviceIconForObject:displayedObject type:AIServiceIconLarge direction:AIIconNormal];
}

- (NSString *)fileNameForImageInImagePicker:(AIImageViewWithImagePicker *)picker
{
	NSString *fileName = [[displayedObject displayName] safeFilenameString];
	if ([fileName hasPrefix:@"."]) {
		fileName = [fileName substringFromIndex:1];
	}
	return fileName;
}

#pragma mark Contact List (metaContact)
//- (void)setupMetaContactDrawer
//{
//	NSDictionary	*themeDict = [NSDictionary dictionaryNamed:CONTACT_INFO_THEME forClass:[self class]];
//	NSDictionary	*layoutDict = [NSDictionary dictionaryNamed:CONTACT_INFO_LAYOUT forClass:[self class]];
//
//	[contactListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];
//
//	[contactListController setHideRoot:YES];
//}
//
//- (void)configureDrawer
//{
//	AIListObject	*listObject = ([displayedObject isKindOfClass:[AIListContact class]] ?
//								   [(AIListContact *)displayedObject parentContact] :
//								   displayedObject);
//	
//	if ([listObject isKindOfClass:[AIMetaContact class]] &&
//		([[(AIMetaContact *)listObject listContacts] count] > 1)) {
//		[contactListController setContactListRoot:(AIMetaContact *)listObject];
//		[drawer_metaContact open];
//
//		NSRect	outlineFrame = [contactListView frame];
//		int		totalHeight = [contactListView totalHeight];
//
//		if (outlineFrame.size.height != totalHeight) {
//			outlineFrame.size.height = totalHeight;
//			[contactListView setFrame:outlineFrame];
//			[contactListView setNeedsDisplay:YES];
//		}
//
//	} else {
//		[drawer_metaContact close];
//		[contactListController setContactListRoot:nil];
//	}
//}

//- (IBAction)removeContact:(id)sender
//{
//	NSEnumerator	*enumerator;
//	AIListObject	*aListObject;
//	AIMetaContact	*contactListRoot = (AIMetaContact *)[contactListController contactListRoot];
//
//	enumerator = [[contactListView arrayOfSelectedItems] objectEnumerator];
//	while ((aListObject = [enumerator nextObject])) {
//		[[adium contactController] removeAllListObjectsMatching:aListObject
//												fromMetaContact:contactListRoot];
//	}
//
//	//The contents of the metaContact have now changed; reload
//	[contactListView reloadData];
//
//	[contactListController outlineViewSelectionDidChange:nil];
//}

- (void)performDefaultActionOnSelectedObject:(AIListObject *)listObject sender:(NSOutlineView *)sender
{

}

- (void)contactInfoListControllerSelectionDidChangeToListObject:(AIListObject *)listObject
{
	AILog(@"Configuring Info List for %@",listObject);
	[self configureForListObject:listObject];

	//Only enable the remove contact button if a contact within the metacontact is selected
	[removeContact setEnabled:(listObject && (listObject != (AIListObject *)[contactListController contactListRoot]))];
}

@end
