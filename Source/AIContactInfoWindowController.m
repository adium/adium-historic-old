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
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITabViewAdditions.h>
#import <QuartzCore/QuartzCore.h>

#define	CONTACT_INFO_NIB				@"ContactInfoInspector"			//Filename of the contact info nib
#define KEY_INFO_WINDOW_FRAME			@"Contact Info Inspector Frame"	//
#define KEY_INFO_SELECTED_CATEGORY		@"Selected Info Category"		//
#define KEY_INFO_SAVED_FRAME_PREFIX		@"Contact Info Inspector Frame Panel"

#define	CONTACT_INFO_THEME				@"Contact Info List Theme"
#define	CONTACT_INFO_LAYOUT				@"Contact Info List Layout"

//Defines for the image files used by the toolbar segments
#define INFO_SEGMENT_IMAGE (@"info_segment.png")
#define ADDRESS_BOOK_SEGMENT_IMAGE (@"addressbook_segment.png")
#define EVENTS_SEGMENT_IMAGE (@"events_segment.png")
#define ADVANCED_SEGMENT_IMAGE (@"advanced_segment.png")

enum segments {
	CONTACT_INFO_SEGMENT = 0,
	CONTACT_ADDRESSBOOK_SEGMENT = 1,
	CONTACT_EVENTS_SEGMENT = 2,
	CONTACT_ADVANCED_SEGMENT = 3,
	CONTACT_PLUGINS_SEGMENT = 4
};

@interface AIContactInfoWindowController (PRIVATE)
- (void)configureForListObject:(AIListObject *)inObject;

-(void)segmentSelected:(id)sender animate:(BOOL)shouldAnimate;
- (void)selectionChanged:(NSNotification *)notification;
- (void)setupToolbarSegments;
- (void)configureToolbarForListObject:(AIListObject *)inObject;
- (void)contactInfoListControllerSelectionDidChangeToListObject:(AIListObject *)listObject;

//View Animation
-(void)addInspectorPanel:(int)newSegment animate:(BOOL)doAnimate;
-(void)animateViewIn:(NSView *)aView;
-(void)animateViewOut:(NSView *)aView;
@end

@interface NSWindow (FakeLeopardAdditions)
- (void)setAutorecalculatesContentBorderThickness:(BOOL)autorecalculateContentBorderThickness forEdge:(NSRectEdge)edge;
- (float)contentBorderThicknessForEdge:(NSRectEdge)edge;
- (void)setContentBorderThickness:(float)borderThickness forEdge:(NSRectEdge)edge;
@end

@implementation AIContactInfoWindowController

static AIContactInfoWindowController *sharedContactInfoInstance = nil;

- (IBAction)segmentSelected:(id)sender
{
	[self segmentSelected:sender animate:YES];
}

- (void)segmentSelected:(id)sender animate:(BOOL)shouldAnimate
{
	//Action method for the Segmented Control, which is actually the toolbar.
	int currentSegment = [sender selectedSegment];
	
	//Take focus away from any textual controls to ensure that they register changes and save
	if ([[[self window] firstResponder] isKindOfClass:[NSText class]]) {
		[[self window] makeFirstResponder:nil];
	}
	
	[self addInspectorPanel:currentSegment animate:shouldAnimate];
}

//Return the shared contact info window
+ (AIContactInfoWindowController *)showInfoWindowForListObject:(AIListObject *)listObject
{
	//Create the window
	if (!sharedContactInfoInstance) {
		sharedContactInfoInstance = [[self alloc] initWithWindowNibName:CONTACT_INFO_NIB];
	}

	[sharedContactInfoInstance setDisplayedListObject:listObject];
	
	[[sharedContactInfoInstance window] makeKeyAndOrderFront:nil];

	return sharedContactInfoInstance;
}

//Close the info window
+ (void)closeInfoWindow
{
	if (sharedContactInfoInstance) {
		[sharedContactInfoInstance closeWindow:nil];
		[sharedContactInfoInstance release]; sharedContactInfoInstance = nil;
	}
}

- (void)dealloc
{
	AILogWithSignature(@"");
	[displayedObject release]; displayedObject = nil;
	[loadedContent release]; loadedContent = nil;
	[contentController release]; contentController = nil;

	[[adium notificationCenter] removeObserver:self];

	[super dealloc];
}


- (NSString *)adiumFrameAutosaveName
{
	return KEY_INFO_WINDOW_FRAME;
}

-(void)windowWillLoad
{
	[super windowWillLoad];
	
	//If we are on Leopard, we want our panel to have a finder-esque look.

	contentController = [[AIContactInfoContentController defaultInfoContentController] retain];

	if(!loadedContent) {
		//Load the content array from the content controller.
		loadedContent = [[contentController loadedPanes] retain];
	}
	
	//Monitor the selected contact
	[[adium notificationCenter] addObserver:self
								   selector:@selector(selectionChanged:)
									   name:Interface_ContactSelectionChanged
									 object:nil];
}
	

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[super windowDidLoad];

	//Localization
	[self setupToolbarSegments];
	
	currentPane = nil;
	lastSegment = 0;
	
	int	selectedSegment;
	
	//Select the previously selected category
	selectedSegment = [[[adium preferenceController] preferenceForKey:KEY_INFO_SELECTED_CATEGORY
																group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	
	if (selectedSegment < 0 || selectedSegment >= [inspectorToolbar segmentCount])
		selectedSegment = 0;

	[inspectorToolbar setSelectedSegment:selectedSegment];
	[self segmentSelected:inspectorToolbar];
}

- (void)windowWillClose:(NSNotification *)inNotification
{
	AILogWithSignature(@"");
	
	[[adium preferenceController] setPreference:NSStringFromRect([currentPane frame])
										 forKey:[KEY_INFO_SAVED_FRAME_PREFIX stringByAppendingFormat:@"%d", lastSegment]
										  group:PREF_GROUP_WINDOW_POSITIONS
										 object:nil];
	
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[inspectorToolbar selectedSegment]]
										  forKey:KEY_INFO_SELECTED_CATEGORY
										   group:PREF_GROUP_WINDOW_POSITIONS];
	
	[sharedContactInfoInstance autorelease]; sharedContactInfoInstance = nil;

	[super windowWillClose:inNotification];
}

/*
    @method     setupToolbarSegments
    @abstract   setupToolbarSegments loads the localized tooltips and images for each toolbar segment
    @discussion Since we don't want to enumerate over all of the segments twice, we've combined the
	localization and image loading steps into this method.
*/
- (void)setupToolbarSegments
{	
	int i;
	for(i = 0; i < [inspectorToolbar segmentCount]; i++) {
		NSString	*segmentLabel = nil;
		NSImage		*segmentImage = nil;

		switch (i) {
			case CONTACT_INFO_SEGMENT:
				segmentLabel = AILocalizedString(@"Status and Profile","This segment displays the status and profile information for the selected contact.");
				segmentImage = [NSImage imageNamed:INFO_SEGMENT_IMAGE];
				break;
			case CONTACT_ADDRESSBOOK_SEGMENT:
				segmentLabel = AILocalizedString(@"Contact Information", "This segment displays contact and alias information for the selected contact.");
				segmentImage = [NSImage imageNamed:ADDRESS_BOOK_SEGMENT_IMAGE];
				break;
			case CONTACT_EVENTS_SEGMENT:
				segmentLabel = AILocalizedString(@"Events", "This segment displays controls for a user to set up events for this contact.");
				segmentImage = [NSImage imageNamed:EVENTS_SEGMENT_IMAGE];
				break;
			case CONTACT_ADVANCED_SEGMENT:
				segmentLabel = AILocalizedString(@"Advanced Settings","This segment displays the advanced settings for a contact, including encryption details and account information.");
				segmentImage = [NSImage imageNamed:ADVANCED_SEGMENT_IMAGE];
				break;
		}

		[(NSSegmentedCell *)[inspectorToolbar cell] setToolTip:segmentLabel forSegment:i];
		
		[segmentImage setDataRetained:YES];
		[inspectorToolbar setImage:segmentImage forSegment:i];
	}	
}

- (void)windowDidResize:(NSNotification *)notification
{
	float availableWidth = [[inspectorToolbar superview] frame].size.width + 2;
	[inspectorToolbar setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
	[inspectorToolbar setFrame:NSMakeRect(-1, [inspectorToolbar frame].origin.y,
										  availableWidth, [inspectorToolbar frame].size.height)];	
	
	int i;
	for(i = 0; i < [inspectorToolbar segmentCount]; i++) {
		[(NSSegmentedCell *)[inspectorToolbar cell] setWidth:(availableWidth / 4) forSegment:i];
	}
}

//When the contact list selection changes, then configure the window for the new contact
- (void)selectionChanged:(NSNotification *)notification
{
	AIListObject	*object = [[adium interfaceController] selectedListObject];
	if (object) {
		[self setDisplayedListObject:object];
	}
}

- (void)setDisplayedListObject:(AIListObject *)inObject
{
	if (inObject != displayedObject) {
		[displayedObject release];
		displayedObject = [inObject retain];
		
		//Ensure our window is loaded
		[self window];
		
		//Configure for the new object
		[self configureForListObject:inObject];
	}
}

//Change the list object
- (void)configureForListObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]]) {
		inObject = [(AIListContact *)inObject parentContact];
	}
	
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
}

#pragma mark View Management and Animation
-(void)addInspectorPanel:(int)newSegment animate:(BOOL)doAnimate
{	
	NSView *newPane = [[loadedContent objectAtIndex:newSegment] inspectorContentView];
	
	if (currentPane == newPane) {
		return;
	}
	
	if (currentPane) {
		// Save current width and height
		[[adium preferenceController] setPreference:NSStringFromRect([currentPane frame])
											 forKey:[KEY_INFO_SAVED_FRAME_PREFIX stringByAppendingFormat:@"%d", lastSegment]
											  group:PREF_GROUP_WINDOW_POSITIONS
											 object:nil];
		
		// Remove the old pane		
		[self animateViewOut:currentPane];
		[currentPane removeFromSuperview];
	}
	
	lastSegment = newSegment;

	NSRect paneFrame = [newPane frame], contentBounds = [inspectorContent frame], inspectorFrame = [[self window] frame];
	
	// Restore the saved sizing (if available)
	NSString *savedPane = [[adium preferenceController] preferenceForKey:[KEY_INFO_SAVED_FRAME_PREFIX stringByAppendingFormat:@"%d", newSegment]
																   group:PREF_GROUP_WINDOW_POSITIONS
																  object:nil];
	if (savedPane) {
		paneFrame = NSRectFromString(savedPane);
		[newPane setFrame:paneFrame];
	}
	
	paneFrame.size.height = ((inspectorFrame.size.height - contentBounds.size.height) + paneFrame.size.height); 
	paneFrame.origin.x = inspectorFrame.origin.x; 
	paneFrame.origin.y = inspectorFrame.origin.y + (inspectorFrame.size.height - paneFrame.size.height); 
	
	[[self window] setFrame:paneFrame display:YES animate:doAnimate]; 
	
	[inspectorContent addSubview:newPane];
	
	currentPane = newPane;
	[self animateViewIn:currentPane];
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
