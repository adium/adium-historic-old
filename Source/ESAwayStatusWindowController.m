//
//  ESAwayStatusWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 4/12/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESAwayStatusWindowController.h"
#import "AIAccountController.h"
#import "AIPreferenceController.h"
#import "AISoundController.h"
#import "AIStatusController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIStatus.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AITableViewAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>


#define AWAY_STATUS_WINDOW_NIB					@"AwayStatusWindow"
#define	KEY_AWAY_STATUS_WINDOW_FRAME			@"Away Status Window Frame"

@interface ESAwayStatusWindowController (PRIVATE)
- (void)configureStatusWindow;
- (void)configureMuteWhileAway;
- (NSAttributedString *)attributedStatusTitleForStatus:(AIStatus *)statusState withIcon:(NSImage *)statusIcon;
- (NSArray *)awayAccounts;
- (void)setupMultistatusTable;
@end

/*!
 * @class ESAwayStatusWindowController
 * @brief Window controller for the status window which optionally shows when one or more accounts are away or invisible
 */
@implementation ESAwayStatusWindowController

static ESAwayStatusWindowController	*sharedInstance = nil;

/*!
 * @brief Update the visibility of the status window
 *
 * Opens or closes the window if necessary.
 *
 * If shouldBeVisibile is YES and the window is already visible, updates its contents to reflect the current status.
 * If shouldBeVisible is NO and the window is already not visibile, no action is taken.
 */
+ (void)updateStatusWindowWithVisibility:(BOOL)shouldBeVisible
{
	if (shouldBeVisible) {
		if (sharedInstance) {
			//Update the window's configuration
			[sharedInstance configureStatusWindow];
		} else {
			//Create a new shared instance, which will be configured automatically once the window loads
			sharedInstance = [[self alloc] initWithWindowNibName:AWAY_STATUS_WINDOW_NIB];
			[sharedInstance showWindow:nil];
		}
	
	} else {
		if (sharedInstance) {
			//If the window is current visible, close it
			[sharedInstance closeWindow:nil];
		}
	}
}

/*!
 * @brief Window size and position autosave name
 */
- (NSString *)adiumFrameAutosaveName
{
	return(KEY_AWAY_STATUS_WINDOW_FRAME);
}

/*!
 * @brief Window loaded
 */
- (void)windowDidLoad
{
	//Call super first so we get our placement before performing autosizing
	[super windowDidLoad];
	
	//Setup the textviews
    [textView_singleStatus setHorizontallyResizable:NO];
    [textView_singleStatus setVerticallyResizable:YES];
    [textView_singleStatus setDrawsBackground:NO];
	[textView_singleStatus setMinSize:NSZeroSize];
    [scrollView_singleStatus setDrawsBackground:NO];

	[self setupMultistatusTable];
	[self configureMuteWhileAway];

	[self configureStatusWindow];
}

/*!
 * @brief Window will close
 *
 * Release and clear the reference to our shared instance
 */
- (void)windowWillClose:(id)sender
{
	//If we are muting while this window is open, remove the mute before closing
	if ([button_muteWhileAway state]) {
		[[adium preferenceController] setPreference:nil
											 forKey:KEY_SOUND_MUTE
											  group:PREF_GROUP_SOUNDS];
	}

	[super windowWillClose:sender];

    //Clean up and release the shared instance
    [sharedInstance autorelease]; sharedInstance = nil;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[_awayAccounts release];
	
	[super dealloc];
}

/*!
 * @brief Configure status window for the current account status(es)
 */
 - (void)configureStatusWindow
{
	NSWindow		*window = [self window];
	BOOL			allOnlineAccountsAreUnvailable;
	AIStatusType	activeUnvailableStatusType;
	NSString		*activeUnvailableStatusName = nil;
	NSSet			*relevantStatuses;
	NSRect			frame = [window frame];
	int				newHeight;
	
	[window setTitle:AILocalizedString(@"Current Status",nil)];
	[_awayAccounts release]; _awayAccounts = nil;

	relevantStatuses = [[adium statusController] activeUnavailableStatusesAndType:&activeUnvailableStatusType 
																		 withName:&activeUnvailableStatusName
												   allOnlineAccountsAreUnvailable:&allOnlineAccountsAreUnvailable];
	
	if (allOnlineAccountsAreUnvailable && ([relevantStatuses count] == 1)) {
		//Show the single status tab if all online accounts are unavailable and they are all in the same status state
		NSImage				*statusIcon;
		NSAttributedString	*statusTitle;

		statusIcon = [AIStatusIcons statusIconForStatusName:activeUnvailableStatusName
												  statusType:activeUnvailableStatusType
													iconType:AIStatusIconTab
												  direction:AIIconNormal];
		statusTitle = [self attributedStatusTitleForStatus:[relevantStatuses anyObject]
												  withIcon:statusIcon];
		
		[[textView_singleStatus textStorage] setAttributedString:statusTitle];

		newHeight = [statusTitle heightWithWidth:[textView_singleStatus frame].size.width] + 65;
		frame.origin.y -= (newHeight - frame.size.height);
		frame.size.height = newHeight;
			
		//Select the right tab view item
		[tabView_configuration selectTabViewItemWithIdentifier:@"singlestatus"];
		
	} else {
		/* Show the multistatus tableview tab if accounts are in different states, which includes the case of only one
		 * away state being in use but not all online accounts currently making use of it.
		 */
		int				requiredHeight;

		_awayAccounts = [[self awayAccounts] retain];

		[tableView_multiStatus reloadData];

		requiredHeight = (([tableView_multiStatus rowHeight] + [tableView_multiStatus intercellSpacing].height) *
						  [_awayAccounts count]);

		newHeight = requiredHeight + 65;
		frame.origin.y -= (newHeight - frame.size.height);
		frame.size.height = newHeight;

		/* Multiple statuses */
		[tabView_configuration selectTabViewItemWithIdentifier:@"multistatus"];
	}

	//Perform the window resizing as needed
	[window setFrame:frame display:YES animate:YES];
}

/*!
 * @brief Return the attributed status title for a status
 *
 * This method puts statusIcon into an NSTextAttachment and prefixes statusState's status message or title with it.
 */
- (NSAttributedString *)attributedStatusTitleForStatus:(AIStatus *)statusState withIcon:(NSImage *)statusIcon
{
	NSMutableAttributedString	*statusTitle;
	NSTextAttachment			*attachment;
	NSTextAttachmentCell		*cell;
	NSAttributedString			*statusMessage;
	
	if ((statusMessage = [statusState statusMessage]) &&
	   ([statusMessage length])) {
		//Use the status message if it is set
		statusTitle = [statusMessage mutableCopy];
		[[statusTitle mutableString] insertString:@" "
										  atIndex:0];

	} else {
		//If it isn't, use the title
		NSDictionary				*attributesDict;

		attributesDict = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:0]
													 forKey:NSFontAttributeName];

		statusTitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",[statusState title]]
															  attributes:attributesDict];
	}

	//Insert the image at the beginning
	cell = [[NSTextAttachmentCell alloc] init];
	[cell setImage:statusIcon];

	attachment = [[NSTextAttachment alloc] init];
	[attachment setAttachmentCell:cell];
	[cell release];

	[statusTitle insertAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]
								atIndex:0];
	[attachment release];

	return [statusTitle autorelease];
}

/*!
 * @brief Return an array of all away accounts
 */
- (NSArray *)awayAccounts
{	
	NSMutableArray	*awayAccounts = [NSMutableArray array];	
	NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;
	
	while ((account = [enumerator nextObject])) {
		if ([account online] || [account integerStatusObjectForKey:@"Connecting"]) {
			AIStatus	*statusState = [account statusState];
			if ([statusState statusType] != AIAvailableStatusType) {
				[awayAccounts addObject:account];
			}
		}
	}

	return awayAccounts;
}

/*!
 * @brief Return from away
 */
- (IBAction)returnFromAway:(id)sender
{
	NSTabViewItem	*selectedTabViewItem = [tabView_configuration selectedTabViewItem];
	AIStatus		*availableStatusState = [[adium statusController] defaultInitialStatusState];
	
	if ([[selectedTabViewItem identifier] isEqualToString:@"singlestatus"]) {
		//Put all accounts in the Available status state
		[[adium statusController] setActiveStatusState:availableStatusState];

	} else {
		//Multistatus
		NSArray	*selectedAccounts;
		
		selectedAccounts = [[tableView_multiStatus arrayOfSelectedItemsUsingSourceArray:_awayAccounts] copy];
		
		if ([selectedAccounts count]) {
			//Apply the available status state to only the selected accounts
			[[adium statusController] applyState:availableStatusState
									  toAccounts:selectedAccounts];
		} else {
			//No selection: Put all accounts in the Available status state
			[[adium statusController] setActiveStatusState:availableStatusState];			
		}

		[selectedAccounts release];
	}
}

/*!
 * @brief Perform initial setup for the multistatus table
 */
- (void)setupMultistatusTable
{
	AIImageTextCell	*imageTextCell;
	
	imageTextCell = [[AIImageTextCell alloc] init];
	[imageTextCell setDrawsGradientHighlight:YES];
	[[tableView_multiStatus tableColumnWithIdentifier:@"status"] setDataCell:imageTextCell];
	[imageTextCell release];	
}

#pragma mark Multiservice table view datasource
/*!
* @brief Number of rows in the table
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([_awayAccounts count]);
}

/*!
 * @brief Table values
 *
 * Object value is the account's formatted UID
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	AIAccount	*account = [_awayAccounts objectAtIndex:row];

	return([account formattedUID]);
}

/*!
 * @brief Will display a cell
 *
 * Set the image (status icon) and substring (status title) before display.  Cell is an AIImageTextCell.
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	AIAccount	*account = [_awayAccounts objectAtIndex:row];

	[cell setImage:[AIStatusIcons statusIconForListObject:account
													 type:AIServiceIconSmall
												direction:AIIconNormal]];
	[cell setSubString:[[account statusState] title]];
}

- (void)configureMuteWhileAway
{
	NSNumber	*shouldMuteWhileWindowIsOpen = [[adium preferenceController] preferenceForKey:@"Mute While Away Status Window is Open"
																					group:PREF_GROUP_STATUS_PREFERENCES];
	//Apply the mute to the sound controller by setting a preference for it
	//XXX - This is BROKEN.  The "muting" should occur at the event level, NOT in the sound controller as it was before. -ai
	[[adium preferenceController] setPreference:shouldMuteWhileWindowIsOpen
										 forKey:KEY_SOUND_MUTE
										  group:PREF_GROUP_SOUNDS];
	[button_muteWhileAway setState:([shouldMuteWhileWindowIsOpen boolValue] ? NSOnState : NSOffState)];
}

- (IBAction)toggleMuteWhileAway:(id)sender
{
	NSNumber	*shouldMuteWhileWindowIsOpen;
	
	shouldMuteWhileWindowIsOpen = ([sender state] ?
								   [NSNumber numberWithBool:YES] :
								   nil);
	//Store for restoring here
	[[adium preferenceController] setPreference:shouldMuteWhileWindowIsOpen
										 forKey:@"Mute While Away Status Window is Open"
										  group:PREF_GROUP_STATUS_PREFERENCES];
	//And apply the mute to the sound controller by setting a preference for it
	[[adium preferenceController] setPreference:shouldMuteWhileWindowIsOpen
										 forKey:KEY_SOUND_MUTE
										  group:PREF_GROUP_SOUNDS];	
}

@end
