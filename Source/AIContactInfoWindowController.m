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
	CONTACT_ADVANCED_SEGMENT = 3,
	CONTACT_PLUGINS_SEGMENT = 4
};

@interface AIContactInfoWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)selectionChanged:(NSNotification *)notification;
- (void)localizeSegmentTitles;
- (void)configureToolbarForListObject:(AIListObject *)inObject;
- (void)contactInfoListControllerSelectionDidChangeToListObject:(AIListObject *)listObject;

-(void)addInspectorView:(NSView *)aView animate:(BOOL)doAnimate;
-(void)animateRemovingRect:(NSRect)aRect inView:(NSView *)aView;
-(void)animateViewIn:(NSView *)aView;
-(void)animateViewOut:(NSView *)aView;
@end

@implementation AIContactInfoWindowController

static AIContactInfoWindowController *sharedContactInfoInstance = nil;

-(IBAction)segmentSelected:(id)sender
{
	//Action method for the Segmented Control, which is actually the toolbar.
	int currentSegment = [sender selectedSegment];
	
	//Take focus away from any textual controls to ensure that they register changes and save
	if ([[[self window] firstResponder] isKindOfClass:[NSText class]]) {
		[[self window] makeFirstResponder:nil];
	}
	
	//There is an optional fifth segment, so we define a case for it.
	switch(currentSegment) {
		case CONTACT_INFO_SEGMENT:
			[self addInspectorView:[[loadedContent objectAtIndex:CONTACT_INFO_SEGMENT] inspectorContentView] animate:YES];
			break;
		case CONTACT_ADDRESSBOOK_SEGMENT:
			[self addInspectorView:[[loadedContent objectAtIndex:CONTACT_ADDRESSBOOK_SEGMENT] inspectorContentView] animate:YES];
			break;
		case CONTACT_EVENTS_SEGMENT:
			[self addInspectorView:[loadedContent objectAtIndex:CONTACT_EVENTS_SEGMENT] animate:YES];
			break;
		case CONTACT_ADVANCED_SEGMENT:
			[self addInspectorView:[loadedContent objectAtIndex:CONTACT_ADVANCED_SEGMENT] animate:YES];
			break;
		case CONTACT_PLUGINS_SEGMENT:
			[self addInspectorView:[loadedContent objectAtIndex:CONTACT_PLUGINS_SEGMENT] animate:YES];
			break;
		default:
			[self addInspectorView:[loadedContent objectAtIndex:CONTACT_INFO_SEGMENT] animate:YES];
			break;
	}
}

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
	//[loadedContent release]; loadedContent = nil;
	
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
	
	contentController = [[AIContactInfoContentController alloc] init];
	
	if(!loadedContent) {
		//Load the content array from the content controller.
		loadedContent = [contentController loadedPanes];
	}
	
	//Localization
	[self localizeSegmentTitles];
	
	//Select the previously selected category
	selectedSegment = [[[adium preferenceController] preferenceForKey:KEY_INFO_SELECTED_CATEGORY
															group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	if (selectedSegment < 0 || selectedSegment >= [inspectorToolbar segmentCount]) selectedSegment = 0;

	//TODO: Change this back to loading the segment from preferences when all the segments work!
	[inspectorToolbar setSelectedSegment:0];
	[self segmentSelected:inspectorToolbar];
	
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
	[[self window] makeFirstResponder:nil];

	//Save the selected category
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[inspectorToolbar selectedSegment]]
										 forKey:KEY_INFO_SELECTED_CATEGORY
										  group:PREF_GROUP_WINDOW_POSITIONS];

	//Close down
	[[adium notificationCenter] removeObserver:self];
	[self autorelease]; sharedContactInfoInstance = nil;
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
	//Set the title of the window.
	if (inObject) {
		[[self window] setTitle:[NSString stringWithFormat:AILocalizedString(@"%@'s Info",nil), [inObject displayName]]];
	} else {
		[[self window] setTitle:AILocalizedString(@"Contact Info",nil)];
	}
	
	//Configure each pane for this contact.
	id<AIContentInspectorPane> pane = nil;
	NSEnumerator *paneEnumerator = [loadedContent objectEnumerator];
	
	while((pane = [paneEnumerator nextObject])) {
		[pane updateForListObject:inObject];
	}
	
	//Configure our toolbar's enabledness
	[self configureToolbarForListObject:inObject];
		
	//Reconfigure the currently selected tab view item
	//[self tabView:tabView_category willSelectTabViewItem:[tabView_category selectedTabViewItem]];
}

- (void)configureToolbarForListObject:(AIListObject *)inObject
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
			if (lastSegmentForContact != -1) {
				[inspectorToolbar setSelectedSegment:lastSegmentForContact];
				lastSegmentForContact = 0;
			}

		}			
	}
	
#warning need to hide panes for bookmarks
}

#pragma mark View Management and Animation
-(void)addInspectorView:(NSView *)aView animate:(BOOL)doAnimate;
{
	NSLog(@"Adding Inspector View: %@", aView);
	
	if(currentPane == aView)
		return;
	
	else if(currentPane) {
		[self animateViewOut:currentPane];
		[currentPane removeFromSuperview];
	}
	
	NSWindow *inspectorWindow = [self window];
	
	NSRect viewBounds = [aView bounds];
	//TODO: It does kind of work, but the window bounds includes the toolbar, need to fix that.
	NSRect contentBounds = [inspectorContent bounds];
	NSRect inspectorFrame = [inspectorWindow frame];

	viewBounds.size.height = ((inspectorFrame.size.height - contentBounds.size.height) + viewBounds.size.height);
	viewBounds.origin.x = inspectorFrame.origin.x;
	viewBounds.origin.y = inspectorFrame.origin.y + (inspectorFrame.size.height - viewBounds.size.height);
	
	[inspectorWindow setFrame:viewBounds display:YES animate:doAnimate];

	[inspectorContent setFrame:[aView bounds]];
	[inspectorContent addSubview:aView];
	currentPane = aView;
	[self animateViewIn:currentPane];
}

-(void)animateRemovingRect:(NSRect)aRect inView:(NSView *)aView;
{
	NSMutableDictionary *animationDict = [NSMutableDictionary dictionaryWithCapacity:4];
	
	[animationDict setObject:aView forKey:NSViewAnimationTargetKey];
	[animationDict setObject:[NSValue valueWithRect:aRect] forKey:NSViewAnimationEndFrameKey];
	[animationDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
	
	NSViewAnimation *viewAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationDict, nil]];
	
	//Setup the animation
	[viewAnim setDuration:0.1];
	[viewAnim setAnimationCurve:NSAnimationEaseInOut];
	[viewAnim setAnimationBlockingMode:NSAnimationBlocking];
	
	//Start it
	[viewAnim startAnimation];
	
	[viewAnim release];
}

-(void)animateViewIn:(NSView *)aView;
{
	NSMutableDictionary *animationDict = [NSMutableDictionary dictionaryWithCapacity:4];
	
	//Set View for animation
	[animationDict setObject:aView forKey:NSViewAnimationTargetKey];
	
	//Set View to resize to passed frame size during animation.
	NSRect zeroView = [aView frame];
	[animationDict setObject:[NSValue valueWithRect:zeroView] forKey:NSViewAnimationStartFrameKey];
	
	//Set View to fade in.
	[animationDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
	
	//Create the animation
	NSViewAnimation *viewAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationDict, nil]];
	
	//Setup the animation
	[viewAnim setDuration:0.1];
	[viewAnim setAnimationCurve:NSAnimationEaseInOut];
	[viewAnim setAnimationBlockingMode:NSAnimationBlocking];
	
	//Start it
	[viewAnim startAnimation];
	
	[viewAnim release];
}

-(void)animateViewOut:(NSView *)aView;
{
	NSMutableDictionary *animationDict = [NSMutableDictionary dictionaryWithCapacity:3];
	
	//Set View for animation
	[animationDict setObject:aView forKey:NSViewAnimationTargetKey];
	
	//Set View to resize to 0 during animation.
	NSRect zeroView = [aView frame];
	[animationDict setObject:[NSValue valueWithRect:zeroView] forKey:NSViewAnimationEndFrameKey];
	
	//Set View to fade out.
	[animationDict setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];
	
	//Create the animation
	NSViewAnimation *viewAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationDict, nil]];
	
	//Setup the animation
	[viewAnim setDuration:0.1];
	[viewAnim setAnimationCurve:NSAnimationEaseInOut];
	[viewAnim setAnimationBlockingMode:NSAnimationBlocking];
	
	//Start it
	[viewAnim startAnimation];
	
	[viewAnim release];
}



@end
