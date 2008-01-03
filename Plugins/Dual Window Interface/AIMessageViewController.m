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

#import "AIMessageViewController.h"
#import "AIAccountSelectionView.h"
#import "AIMessageWindowController.h"
#import "ESGeneralPreferencesPlugin.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIContactInfoWindowController.h"
#import "AIMessageTabSplitView.h"

#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIMessageEntryTextView.h>
#import <Adium/ESTextAndButtonsWindowController.h>

#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AISplitView.h>

#import <AIUtilities/AITigerCompatibility.h>

#import <PSMTabBarControl/NSBezierPath_AMShading.h>
#import "KNShelfSplitView.h"
#import "ESChatUserListController.h"

//Heights and Widths
#define MESSAGE_VIEW_MIN_HEIGHT_RATIO		.50						//Mininum height ratio of the message view
#define MESSAGE_VIEW_MIN_WIDTH_RATIO		.50						//Mininum width ratio of the message view
#define ENTRY_TEXTVIEW_MIN_HEIGHT			20						//Mininum height of the text entry view
#define USER_LIST_MIN_WIDTH					24						//Mininum width of the user list
#define USER_LIST_DEFAULT_WIDTH				120						//Default width of the user list

//Preferences and files
#define MESSAGE_VIEW_NIB					@"MessageView"			//Filename of the message view nib
#define	USERLIST_THEME						@"UserList Theme"		//File name of the user list theme
#define	USERLIST_LAYOUT						@"UserList Layout"		//File name of the user list layout
#define	KEY_ENTRY_TEXTVIEW_MIN_HEIGHT		@"Minimum Text Height"	//Preference key for text entry height
#define	KEY_ENTRY_USER_LIST_MIN_WIDTH		@"UserList Width"		//Preference key for user list width


@interface AIMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat;
- (void)chatStatusChanged:(NSNotification *)notification;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)_configureMessageDisplay;
- (void)_createAccountSelectionView;
- (void)_destroyAccountSelectionView;
- (void)_configureTextEntryView;
- (void)_updateTextEntryViewHeight;
- (int)_textEntryViewProperHeightIgnoringUserMininum:(BOOL)ignoreUserMininum;
- (void)_showUserListView;
- (void)_hideUserListView;
- (void)_configureUserList;
- (void)_updateUserListViewWidth;
- (int)_userListViewProperWidthIgnoringUserMininum:(BOOL)ignoreUserMininum;
- (void)updateFramesForAccountSelectionView;
- (void)saveUserListMinimumSize;
@end

@implementation AIMessageViewController

/*!
 * @brief Create a new message view controller
 */
+ (AIMessageViewController *)messageDisplayControllerForChat:(AIChat *)inChat
{
    return [[[self alloc] initForChat:inChat] autorelease];
}


/*!
 * @brief Initialize
 */
- (id)initForChat:(AIChat *)inChat
{
    if ((self = [super init])) {
		AIListContact	*contact;
		//Init
		chat = [inChat retain];
		contact = [chat listObject];
		view_accountSelection = nil;
		userListController = nil;
		suppressSendLaterPrompt = NO;
		retainingScrollViewUserList = NO;
		
		//Load the view containing our controls
		[NSBundle loadNibNamed:MESSAGE_VIEW_NIB owner:self];
		
		//Register for the various notification we need
		[[adium notificationCenter] addObserver:self
									   selector:@selector(sendMessage:) 
										   name:Interface_SendEnteredMessage
										 object:chat];
		[[adium notificationCenter] addObserver:self
									   selector:@selector(didSendMessage:)
										   name:Interface_DidSendEnteredMessage 
										 object:chat];
		[[adium notificationCenter] addObserver:self
									   selector:@selector(chatStatusChanged:) 
										   name:Chat_StatusChanged
										 object:chat];
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(chatParticipatingListObjectsChanged:)
										   name:Chat_ParticipatingListObjectsChanged
										 object:chat];
		[[adium notificationCenter] addObserver:self
									   selector:@selector(redisplaySourceAndDestinationSelector:) 
										   name:Chat_SourceChanged
										 object:chat];
		[[adium notificationCenter] addObserver:self
									   selector:@selector(redisplaySourceAndDestinationSelector:) 
										   name:Chat_DestinationChanged
										 object:chat];
		[[adium notificationCenter] addObserver:self
									   selector:@selector(toggleUserlist:)
										   name:@"toggleUserlist"
										 object:nil];
		
		[splitView_textEntryHorizontal setDividerThickness:3]; //Default is 9
		[splitView_textEntryHorizontal setDrawsDivider:NO];
		
		//Observe general preferences for sending keys
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];

		/* Update chat status and participating list objects to configure the user list if necessary
		 * Call chatParticipatingListObjectsChanged first, which will set up the user list. This allows other sizing to match.
		 */
		[self setUserListVisible:[chat isGroupChat]];
		
		[self chatParticipatingListObjectsChanged:nil];
		[self chatStatusChanged:nil];
		
		//Configure our views
		[self _configureMessageDisplay];
		[self _configureTextEntryView];

		//Set our base writing direction
		if (contact) {
			[textView_outgoing setBaseWritingDirection:[contact baseWritingDirection]];
		}
	}

	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{   
	AIListContact	*contact = [chat listObject];
	
	[[adium preferenceController] unregisterPreferenceObserver:self];

	//Store our minimum height for the text entry area, and minimim width for the user list
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:entryMinHeight]
										 forKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	if (userListController) {
		[self saveUserListMinimumSize];
	}
	
	//Save the base writing direction
	if (contact)
		[contact setBaseWritingDirection:[textView_outgoing baseWritingDirection]];

	[chat release]; chat = nil;

    //remove observers
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    //Account selection view
	[self _destroyAccountSelectionView];
	
	[messageDisplayController messageViewIsClosing];
    [messageDisplayController release];
	[userListController release];

	[controllerView_messages release];
	
	//Release view_contents, for which we are responsible because we loaded it via -[NSBundle loadNibNamed:owner]
	[view_contents release];

	//Release the hidden user list view
	if (retainingScrollViewUserList) {
		[scrollView_userList release];
	}
	//release menuItem
	[showHide release];
    [super dealloc];
}

- (void)saveUserListMinimumSize
{
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:userListMinWidth]
										 forKey:KEY_ENTRY_USER_LIST_MIN_WIDTH
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

- (void)updateGradientColors
{
	NSColor *darkerColor = [NSColor colorWithCalibratedWhite:0.90 alpha:1.0];
	NSColor *lighterColor = [NSColor colorWithCalibratedWhite:0.92 alpha:1.0];
	NSColor *leftColor = nil, *rightColor = nil;

	switch ([messageWindowController tabPosition]) {
		case AdiumTabPositionBottom:
		case AdiumTabPositionTop:
		case AdiumTabPositionLeft:
			leftColor = lighterColor;
			rightColor = darkerColor;
			break;
		case AdiumTabPositionRight:
			leftColor = darkerColor;
			rightColor = lighterColor;
			break;
	}

	[view_accountSelection setLeftColor:leftColor rightColor:rightColor];
	[splitView_textEntryHorizontal setLeftColor:leftColor rightColor:rightColor];
}

/*!
 * @brief Invoked before the message view closes
 *
 * This method is invoked before our message view controller's message view leaves a window.
 * We need to clean up our user list to invalidate cursor tracking before the view closes.
 */
- (void)messageViewWillLeaveWindowController:(AIMessageWindowController *)inWindowController
{
	if (inWindowController) {
		[userListController contactListWillBeRemovedFromWindow];
	}
	
	[messageWindowController release]; messageWindowController = nil;
}

- (void)messageViewAddedToWindowController:(AIMessageWindowController *)inWindowController
{
	if (inWindowController) {
		[userListController contactListWasAddedBackToWindow];
	}
	
	if (inWindowController != messageWindowController) {
		[messageWindowController release];
		messageWindowController = [inWindowController retain];
		
		[self updateGradientColors];
	}
}

/*!
 * @brief Retrieve the chat represented by this message view
 */
- (AIChat *)chat
{
    return chat;
}

/*!
 * @brief Retrieve the source account associated with this chat
 */
- (AIAccount *)account
{
    return [chat account];
}

/*!
 * @brief Retrieve the destination list object associated with this chat
 */
- (AIListContact *)listObject
{
    return [chat listObject];
}

/*!
 * @brief Returns the selected list object in our participants list
 */
- (AIListObject *)preferredListObject
{
	if (userListView) { //[[shelfView subviews] containsObject:scrollView_userList] && ([userListView selectedRow] != -1)
		return [userListView itemAtRow:[userListView selectedRow]];
	}
	
	return nil;
}

/*!
 * @brief Invoked when the status of our chat changes
 *
 * The only chat status change we're interested in is one to the disallow account switching flag.  When this flag 
 * changes we update the visibility of our account status menus accordingly.
 */
- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*modifiedKeys = [[notification userInfo] objectForKey:@"Keys"];
	
    if (notification == nil || [modifiedKeys containsObject:@"DisallowAccountSwitching"]) {
		[self setAccountSelectionMenuVisibleIfNeeded:YES];
    }
}


//Message Display ------------------------------------------------------------------------------------------------------
#pragma mark Message Display
/*!
 * @brief Configure the message display view
 */
- (void)_configureMessageDisplay
{
	//Create the message view
	messageDisplayController = [[[adium interfaceController] messageDisplayControllerForChat:chat] retain];
	//Get the messageView from the controller
	controllerView_messages = [[messageDisplayController messageView] retain];
	//scrollView_messages is originally a placeholder; replace it with controllerView_messages
	[controllerView_messages setFrame:[scrollView_messages documentVisibleRect]];
	[[customView_messages superview] replaceSubview:customView_messages with:controllerView_messages];

	//This is what draws our transparent background
	//Technically, it could be set in MessageView.nib, too
	[scrollView_messages setBackgroundColor:[NSColor clearColor]];

	[controllerView_messages setNextResponder:textView_outgoing];
}

/*!
 * @brief Access to our view
 */
- (NSView *)view
{
    return view_contents;
}

/*!
 * @brief Support for printing.  Forward the print command to our message display view
 */
- (void)adiumPrint:(id)sender
{
	if ([messageDisplayController respondsToSelector:@selector(adiumPrint:)]) {
		[messageDisplayController adiumPrint:sender];
	}
}


//Messaging ------------------------------------------------------------------------------------------------------------
#pragma mark Messaging
/*!
 * @brief Send the entered message
 */
- (IBAction)sendMessage:(id)sender
{
	NSAttributedString	*attributedString = [textView_outgoing textStorage];
	
	//Only send if we have a non-zero-length string
    if ([attributedString length] != 0) { 
		AIListObject				*listObject = [chat listObject];
		
		if ([chat isGroupChat] && ![[chat account] online]) {
			//Refuse to do anything with a group chat for an offline account.
			NSBeep();
			return;
		}
		
		if (!suppressSendLaterPrompt &&
			![chat canSendMessages]) {
			
			NSString							*formattedUID = [listObject formattedUID];

			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:[NSString stringWithFormat:AILocalizedString(@"%@ appears to be offline. How do you want to send this message?", nil),
								   formattedUID]];
			[alert setInformativeText:[NSString stringWithFormat:
									   AILocalizedString(@"Send Later will send the message the next time both you and %@ are online. Send Now may work if %@ is invisible or is not on your contact list and so only appears to be offline.", "Send Later dialogue explanation text"),
									   formattedUID, formattedUID, formattedUID]];
			[alert addButtonWithTitle:AILocalizedString(@"Send Now", nil)];

			[alert addButtonWithTitle:AILocalizedString(@"Send Later", nil)];
			[[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"l"];
			[[[alert buttons] objectAtIndex:1] setKeyEquivalentModifierMask:0];

			[alert addButtonWithTitle:AILocalizedString(@"Don't Send", nil)];			 
			[[[alert buttons] objectAtIndex:2] setKeyEquivalent:@"\E"];
			[[[alert buttons] objectAtIndex:2] setKeyEquivalentModifierMask:0];

			NSImage *icon = ([listObject userIcon] ? [listObject userIcon] : [AIServiceIcons serviceIconForObject:listObject
																											 type:AIServiceIconLarge
																										direction:AIIconNormal]);
			icon = [[icon copy] autorelease];
			[icon setScalesWhenResized:NO];
			[alert setIcon:icon];
			[alert setAlertStyle:NSInformationalAlertStyle];

			[alert beginSheetModalForWindow:[view_contents window]
							  modalDelegate:self
							 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
								contextInfo:NULL];
			[alert release];


		} else {
			AIContentMessage		*message;
			NSAttributedString		*outgoingAttributedString;
			AIAccount				*account = [chat account];
			//Send the message
			[[adium notificationCenter] postNotificationName:Interface_WillSendEnteredMessage
													  object:chat
													userInfo:nil];

			outgoingAttributedString = [attributedString copy];
			message = [AIContentMessage messageInChat:chat
										   withSource:account
										  destination:[chat listObject]
												 date:nil //created for us by AIContentMessage
											  message:outgoingAttributedString
											autoreply:NO];
			[outgoingAttributedString release];

			if ([[adium contentController] sendContentObject:message]) {
				[[adium notificationCenter] postNotificationName:Interface_DidSendEnteredMessage 
														  object:chat
														userInfo:nil];
			}
		}
    }
}

/*!
 * @brief Send Later button was pressed
 */ 
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	switch (returnCode) {
		case NSAlertFirstButtonReturn: /* Send Now */
			suppressSendLaterPrompt = YES;
			[self sendMessage:nil];
			break;
			
		case NSAlertSecondButtonReturn: /* Send Later */
			[self sendMessageLater:nil];
			break;
		case NSAlertThirdButtonReturn: /* Don't Send */
			break;		
	}
}

/*!
 * @brief Invoked after our entered message sends
 *
 * This method hides the account selection view and clears the entered message after our message sends
 */
- (IBAction)didSendMessage:(id)sender
{
    [self setAccountSelectionMenuVisibleIfNeeded:NO];
    [self clearTextEntryView];
	
	//Redisplay the cursor
	[NSCursor setHiddenUntilMouseMoves:NO];
}

/*!
 * @brief Offline messaging
 */
- (IBAction)sendMessageLater:(id)sender
{
	AIListContact	*listContact;

	//If the chat can _now_ send a message, send it immediately instead of waiting for "later".
	if ([chat canSendMessages]) {
		[self sendMessage:sender];
		return;
	}

	//Put the alert on the metaContact containing this listContact if applicable
	listContact = [[chat listObject] parentContact];

	if (listContact) {
		NSMutableDictionary *detailsDict, *alertDict;
		
		detailsDict = [NSMutableDictionary dictionary];
		[detailsDict setObject:[[chat account] internalObjectID] forKey:@"Account ID"];
		[detailsDict setObject:[NSNumber numberWithBool:YES] forKey:@"Allow Other"];
		[detailsDict setObject:[listContact internalObjectID] forKey:@"Destination ID"];

		alertDict = [NSMutableDictionary dictionary];
		[alertDict setObject:detailsDict forKey:@"ActionDetails"];
		[alertDict setObject:CONTACT_SEEN_ONLINE_YES forKey:@"EventID"];
		[alertDict setObject:@"SendMessage" forKey:@"ActionID"];
		[alertDict setObject:[NSNumber numberWithBool:YES] forKey:@"OneTime"]; 
		
		[alertDict setObject:listContact forKey:@"TEMP-ListContact"];
		
		[[adium contentController] filterAttributedString:[[[textView_outgoing textStorage] copy] autorelease]
										  usingFilterType:AIFilterContent
												direction:AIFilterOutgoing
											filterContext:listContact
										  notifyingTarget:self
												 selector:@selector(gotFilteredMessageToSendLater:receivingContext:)
												  context:alertDict];

		[self didSendMessage:nil];
	}
}

/*!
 * @brief Offline messaging
 */
//XXX - Offline messaging code SHOULD NOT BE IN HERE! -ai
- (void)gotFilteredMessageToSendLater:(NSAttributedString *)filteredMessage receivingContext:(NSMutableDictionary *)alertDict
{
	NSMutableDictionary	*detailsDict;
	AIListContact		*listContact;
	
	detailsDict = [alertDict objectForKey:@"ActionDetails"];
	[detailsDict setObject:[filteredMessage dataRepresentation] forKey:@"Message"];

	listContact = [[alertDict objectForKey:@"TEMP-ListContact"] retain];
	[alertDict removeObjectForKey:@"TEMP-ListContact"];
	
	[[adium contactAlertsController] addAlert:alertDict 
								 toListObject:listContact
							 setAsNewDefaults:NO];
	[listContact release];
}

//Account Selection ----------------------------------------------------------------------------------------------------
#pragma mark Account Selection
/*!
 * @brief
 */
- (void)accountSelectionViewFrameDidChange:(NSNotification *)notification
{
	[self updateFramesForAccountSelectionView];
}

/*!
 * @brief Redisplay the source/destination account selector
 */
- (void)redisplaySourceAndDestinationSelector:(NSNotification *)notification
{
	[self setAccountSelectionMenuVisibleIfNeeded:YES];
}

/*!
 * @brief Toggle visibility of the account selection menus
 *
 * Invoking this method with NO will hide the account selection menus.  Invoking it with YES will show the account
 * selection menus if they are needed.
 */
- (void)setAccountSelectionMenuVisibleIfNeeded:(BOOL)makeVisible
{
	//Hide or show the account selection view as requested
	if (makeVisible) {
		[self _createAccountSelectionView];
	} else {
		[self _destroyAccountSelectionView];
	}
}

/*!
 * @brief Show the account selection view
 */
- (void)_createAccountSelectionView
{
	if (!view_accountSelection) {
		NSRect	contentFrame = [splitView_textEntryHorizontal frame];

		//Create the account selection view and insert it into our window
		view_accountSelection = [[AIAccountSelectionView alloc] initWithFrame:contentFrame];

		[view_accountSelection setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
		
		[self updateGradientColors];
		
		//Insert the account selection view at the top of our view
		[[shelfView contentView] addSubview:view_accountSelection];
		[view_accountSelection setChat:chat];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accountSelectionViewFrameDidChange:)
													 name:AIViewFrameDidChangeNotification
												   object:view_accountSelection];
		
		[self updateFramesForAccountSelectionView];
			
		//Redisplay everything
		[[shelfView contentView] setNeedsDisplay:YES];
	}
}

/*!
 * @brief Hide the account selection view
 */
- (void)_destroyAccountSelectionView
{
	if (view_accountSelection) {
		//Remove the observer
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:AIViewFrameDidChangeNotification
													  object:view_accountSelection];

		//Remove the account selection view from our window, clean it up
		[view_accountSelection removeFromSuperview];
		[view_accountSelection release]; view_accountSelection = nil;

		//Redisplay everything
		[self updateFramesForAccountSelectionView];
	}
}

/*!
 * @brief Position the account selection view, if it is present, and the messages/text entry splitview appropriately
 */
- (void)updateFramesForAccountSelectionView
{
	int		contentsHeight = [[shelfView contentView] frame].size.height;
	int 	accountSelectionHeight = (view_accountSelection ? [view_accountSelection frame].size.height : 0);
	int		intersectionPoint = ([[shelfView contentView] isFlipped] ? accountSelectionHeight : (contentsHeight - accountSelectionHeight));

	if (view_accountSelection) {
		[view_accountSelection setFrameOrigin:NSMakePoint(NSMinX([view_accountSelection frame]), intersectionPoint)];
		[view_accountSelection setNeedsDisplay:YES];
	}

	[splitView_textEntryHorizontal setFrameSize:NSMakeSize(NSWidth([splitView_textEntryHorizontal frame]), intersectionPoint)];
	[splitView_textEntryHorizontal setNeedsDisplay:YES];
}	


//Text Entry -----------------------------------------------------------------------------------------------------------
#pragma mark Text Entry
/*!
 * @brief Preferences changed, update sending keys
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[textView_outgoing setSendOnReturn:[[prefDict objectForKey:SEND_ON_RETURN] boolValue]];
	[textView_outgoing setSendOnEnter:[[prefDict objectForKey:SEND_ON_ENTER] boolValue]];
}

/*!
 * @brief Configure the text entry view
 */
- (void)_configureTextEntryView
{	
	//Configure the text entry view
    [textView_outgoing setTarget:self action:@selector(sendMessage:)];

	//This is necessary for tab completion.
	[textView_outgoing setDelegate:self];
    
	[textView_outgoing setTextContainerInset:NSMakeSize(0,2)];
    if ([textView_outgoing respondsToSelector:@selector(setUsesFindPanel:)]) {
		[textView_outgoing setUsesFindPanel:YES];
    }
	[textView_outgoing setClearOnEscape:YES];
	[textView_outgoing setTypingAttributes:[[adium contentController] defaultFormattingAttributes]];
	
	//User's choice of mininum height for their text entry view
	entryMinHeight = [[[adium preferenceController] preferenceForKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
															   group:PREF_GROUP_DUAL_WINDOW_INTERFACE] intValue];
	if (entryMinHeight <= 0) entryMinHeight = [self _textEntryViewProperHeightIgnoringUserMininum:YES];

	//Associate the view with our message view so it knows which view to scroll in response to page up/down
	//and other special key-presses.
	[textView_outgoing setAssociatedView:[messageDisplayController messageScrollView]];
	
	//Associate the text entry view with our chat and inform Adium that it exists.
	//This is necessary for text entry filters to work correctly.
	[textView_outgoing setChat:chat];
	
    //Observe text entry view size changes so we can dynamically resize as the user enters text
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outgoingTextViewDesiredSizeDidChange:)
												 name:AIViewDesiredSizeDidChangeNotification 
											   object:textView_outgoing];

	[self _updateTextEntryViewHeight];
}

/*!
 * @brief Sets our text entry view as the first responder
 */
- (void)makeTextEntryViewFirstResponder
{
    [[textView_outgoing window] makeFirstResponder:textView_outgoing];
}

/*!
 * @brief Clear the message entry text view
 */
- (void)clearTextEntryView
{
	NSWritingDirection	writingDirection;

	writingDirection = [textView_outgoing baseWritingDirection];
	
	[textView_outgoing setString:@""];
	[textView_outgoing setTypingAttributes:[[adium contentController] defaultFormattingAttributes]];
	
	[textView_outgoing setBaseWritingDirection:writingDirection];	//Preserve the writing diraction

    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
														object:textView_outgoing];
}

/*!
 * @brief Add text to the message entry text view 
 *
 * Adds the passed string to the entry text view at the insertion point.  If there is selected text in the view, it
 * will be replaced.
 */
- (void)addToTextEntryView:(NSAttributedString *)inString
{
    [textView_outgoing insertText:inString];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView_outgoing];
}

/*!
 * @brief Add data to the message entry text view 
 *
 * Adds the passed pasteboard data to the entry text view at the insertion point.  If there is selected text in the
 * view, it will be replaced.
 */
- (void)addDraggedDataToTextEntryView:(id <NSDraggingInfo>)draggingInfo
{
    [textView_outgoing performDragOperation:draggingInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView_outgoing];
}

/*!
 * @brief Update the text entry view's height when its desired size changes
 */
- (void)outgoingTextViewDesiredSizeDidChange:(NSNotification *)notification
{
	[self _updateTextEntryViewHeight];
}

- (void)tabViewDidChangeVisibility
{
	[self _updateTextEntryViewHeight];
}

/* 
 * @brief Update the height of our text entry view
 *
 * This method sets the height of the text entry view to the most ideal value, and adjusts the other views in our
 * window to fill the remaining space.
 */
- (void)_updateTextEntryViewHeight
{
	int		height = [self _textEntryViewProperHeightIgnoringUserMininum:NO];
	
	//Display the vertical scroller if our view is not tall enough to display all the entered text
	[scrollView_outgoing setHasVerticalScroller:(height < [textView_outgoing desiredSize].height)];

	if ([NSApp isOnLeopardOrBetter]) {
		//Attempt to maximize the message view's size.  We'll automatically restrict it to the correct minimum via the NSSplitView's delegate methods.
		[splitView_textEntryHorizontal setPosition:NSHeight([splitView_textEntryHorizontal frame])
								  ofDividerAtIndex:0];
		
	} else {
		NSRect	tempFrame, newFrame;
		BOOL	changed = NO;

		//Size the outgoing text view to the desired height
		tempFrame = [scrollView_outgoing frame];
		newFrame = NSMakeRect(tempFrame.origin.x,
							  [splitView_textEntryHorizontal frame].size.height - height,
							  tempFrame.size.width,
							  height);
		if (!NSEqualRects(tempFrame, newFrame)) {
			[scrollView_outgoing setFrame:newFrame];
			[scrollView_outgoing setNeedsDisplay:YES];
			changed = YES;
		}

		if (changed) {
			[splitView_textEntryHorizontal adjustSubviews];
		}
	}
}

/*!
 * @brief Returns the height our text entry view should be
 *
 * This method takes into account user preference, the amount of entered text, and the current window size to return
 * a height which is most ideal for the text entry view.
 *
 * @param ignoreUserMininum If YES, the user's preference for mininum height will be ignored
 */
- (int)_textEntryViewProperHeightIgnoringUserMininum:(BOOL)ignoreUserMininum
{
	int dividerThickness = [splitView_textEntryHorizontal dividerThickness];
	int allowedHeight = ([splitView_textEntryHorizontal frame].size.height / 2.0) - dividerThickness;
	int	height;
	
	//Our primary goal is to display all the entered text
	height = [textView_outgoing desiredSize].height;
	
	//But we must never fall below the user's prefered mininum or above the allowed height
	if (!ignoreUserMininum && height < entryMinHeight) height = entryMinHeight;
	if (height > allowedHeight) height = allowedHeight;
	
	return height;
}

#pragma mark Autocompletion
/*!
 * @brief Should the tab key cause an autocompletion if possible?
 *
 * We only tab to autocomplete for a group chat
 */
- (BOOL)textViewShouldTabComplete:(NSTextView *)inTextView
{
	return [[self chat] isGroupChat];
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index
{
	NSMutableArray	*completions;
	
	if ([[self chat] isGroupChat]) {
		NSString		*partialWord = [[[textView textStorage] attributedSubstringFromRange:charRange] string];
		NSEnumerator	*enumerator;
		AIListContact	*listContact;
		
		NSString		*suffix;
		if (charRange.location == 0) {
			//At the start of a line, append ": "
			suffix = @": ";
		} else {
			suffix = nil;
		}
		
		completions = [NSMutableArray array];
		enumerator = [[[self chat] containedObjects] objectEnumerator];
		while ((listContact = [enumerator nextObject])) {
			if ([[listContact displayName] rangeOfString:partialWord
												 options:(NSLiteralSearch | NSAnchoredSearch)].location != NSNotFound) {
				
				[completions addObject:(suffix ? [[listContact displayName] stringByAppendingString:suffix] : [listContact displayName])];
				
			} else if ([[listContact formattedUID] rangeOfString:partialWord
														 options:(NSLiteralSearch | NSAnchoredSearch)].location != NSNotFound) {
				[completions addObject:(suffix ? [[listContact formattedUID] stringByAppendingString:suffix] : [listContact formattedUID])];
				
			} else if ([[listContact UID] rangeOfString:partialWord
												options:(NSLiteralSearch | NSAnchoredSearch)].location != NSNotFound) {
				[completions addObject:(suffix ? [[listContact UID] stringByAppendingString:suffix] : [listContact UID])];
			}
		}

		if ([completions count]) {			
			*index = 0;
		}

	} else {
		completions = nil;
	}

	return ([completions count] ? completions : words);
}

//User List ------------------------------------------------------------------------------------------------------------
#pragma mark User List
/*!
 * @brief Set visibility of the user list
 */
- (void)setUserListVisible:(BOOL)inVisible
{
	if (inVisible) {
		[self _showUserListView];
	} else {
		[self _hideUserListView];
	}
}

/*!
 * @brief Returns YES if the user list is currently visible
 */
- (BOOL)userListVisible
{
	return [shelfView isShelfVisible];
}

/*!
 * @brief Show the user list
 */
- (void)_showUserListView
{	
	[self setupShelfView];

	//Configure the user list
	[self _configureUserList];

	//Add the user list back to our window if it's missing
	if (![self userListVisible]) {
		[self _updateUserListViewWidth];
		
		if (retainingScrollViewUserList) {
			[scrollView_userList release];
			retainingScrollViewUserList = NO;
		}
	}
}

/*!
 * @brief Hide the user list.
 *
 * We gain responsibility for releasing scrollView_userList after we hide it
 */
- (void)_hideUserListView
{
	if ([self userListVisible]) {
		[scrollView_userList retain];
		[scrollView_userList removeFromSuperview];
		retainingScrollViewUserList = YES;
		
		[self saveUserListMinimumSize];
		[userListController release];
		userListController = nil;
	
		//need to collapse the splitview
		[shelfView setShelfIsVisible:NO];
	}
}

/*!
 * @brief Configure the user list
 *
 * Configures the user list view and prepares it for display.  If the user list is not being shown, this configuration
 * should be avoided for performance.
 */
- (void)_configureUserList
{
	if (!userListController) {
		NSDictionary	*themeDict = [NSDictionary dictionaryNamed:USERLIST_THEME forClass:[self class]];
		NSDictionary	*layoutDict = [NSDictionary dictionaryNamed:USERLIST_LAYOUT forClass:[self class]];
		
		//Create and configure a controller to manage the user list
		userListController = [[ESChatUserListController alloc] initWithContactListView:userListView
																		  inScrollView:scrollView_userList 
																			  delegate:self];
		[userListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];
		[userListController setContactListRoot:chat];
		[userListController setHideRoot:YES];

		//User's choice of mininum width for their user list view
		userListMinWidth = [[[adium preferenceController] preferenceForKey:KEY_ENTRY_USER_LIST_MIN_WIDTH
																	 group:PREF_GROUP_DUAL_WINDOW_INTERFACE] intValue];
		if (userListMinWidth < USER_LIST_MIN_WIDTH) userListMinWidth = USER_LIST_DEFAULT_WIDTH;
		[shelfView setShelfWidth:[userListView bounds].size.width];
	}
}

/*!
 * @brief Update the user list in response to changes
 *
 * This method is invoked when the chat's participating contacts change.  In resopnse, it sets correct visibility of
 * the user list, and updates the displayed users.
 */
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification
{
    //Update the user list
	AILogWithSignature(@"%i, so %@ %@",[self userListVisible], ([self userListVisible] ? @"reloading" : @"not reloading"),
					   userListController);
    if ([self userListVisible]) {
        [userListController reloadData];
    }
}

/*!
 * @brief The selection in the user list changed
 *
 * When the user list selection changes, we update the chat's "preferred list object", which is used
 * elsewhere to identify the currently 'selected' contact for Get Info, Messaging, etc.
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == userListView) {
		int selectedIndex = [userListView selectedRow];
		[chat setPreferredListObject:((selectedIndex != -1) ? 
									  [[chat containedObjects] objectAtIndex:selectedIndex] :
									  nil)];
	}
}

/*!
 * @brief Perform default action on the selected user list object
 *
 * Here we could open a private message or display info for the user, however we perform no action
 * at the moment.
 */
- (void)performDefaultActionOnSelectedObject:(AIListObject *)listObject sender:(NSOutlineView *)sender
{
	//Empty
}

/* 
 * @brief Update the width of our user list view
 *
 * This method sets the width of the user list view to the most ideal value, and adjusts the other views in our
 * window to fill the remaining space.
 */
- (void)_updateUserListViewWidth
{
	int		width = [self _userListViewProperWidthIgnoringUserMininum:NO];
	int		widthWithDivider = 1 + width;	//resize bar effective width  
	NSRect	tempFrame;

	//Size the user list view to the desired width
	tempFrame = [scrollView_userList frame];
	[scrollView_userList setFrame:NSMakeRect([shelfView frame].size.width - width,
											 tempFrame.origin.y,
											 width,
											 tempFrame.size.height)];
	
	//Size the message view to fill the remaining space
	tempFrame = [scrollView_messages frame];
	[scrollView_messages setFrame:NSMakeRect(tempFrame.origin.x,
											 tempFrame.origin.y,
											 [shelfView frame].size.width - widthWithDivider,
											 tempFrame.size.height)];

	//Redisplay both views and the divider
	[shelfView setNeedsDisplay:YES];
}

/*!
 * @brief Returns the width our user list view should be
 *
 * This method takes into account user preference and the current window size to return a width which is most
 * ideal for the user list view.
 *
 * @param ignoreUserMininum If YES, the user's preference for mininum width will be ignored
 */
- (int)_userListViewProperWidthIgnoringUserMininum:(BOOL)ignoreUserMininum
{
	int dividerThickness = 1; //[shelfView dividerThickness];
	int allowedWidth = ([shelfView frame].size.width / 2.0) - dividerThickness;
	int	width = USER_LIST_MIN_WIDTH;
	
	//We must never fall below the user's prefered mininum or above the allowed width
	if (!ignoreUserMininum && width < userListMinWidth) width = userListMinWidth;
	if (width > allowedWidth) width = allowedWidth;

	return width;
}


//Split Views --------------------------------------------------------------------------------------------------
#pragma mark Split Views
/* 
 * @brief Returns the maximum constraint of the split pane
 *
 * For the horizontal split, we prevent the message view from growing so large that the text entry view
 * is forced below its desired height.
 */
- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	if (sender == splitView_textEntryHorizontal) {
		return ([sender frame].size.height - ([self _textEntryViewProperHeightIgnoringUserMininum:YES] +
											 [sender dividerThickness]));

	} else {
		NSLog(@"Unknown split view %@",sender);
		return 0;
	}
}

/* 
 * @brief Returns the mininum constraint of the split pane
 *
 * For both splitpanes, we prevent the message view from dropping below 50% of the window's width and height
 */
- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	if (sender == splitView_textEntryHorizontal) {
		return (int)([sender frame].size.height * MESSAGE_VIEW_MIN_HEIGHT_RATIO);
		
	} else {
		NSLog(@"Unknown split view %@",sender);
		return 0;
	}
}

/*!
 * @brief A split view had its divider position changed
 *
 * Remember the user's choice of text entry view height.
 */
- (float)splitView:(NSSplitView *)sender constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)index
{
	if (sender == splitView_textEntryHorizontal) {
		entryMinHeight = (int)([sender frame].size.height - (proposedPosition + [sender dividerThickness]));
	} else {
		NSLog(@"Unknown split view %@",sender);
		return 0;
	}
	
	return proposedPosition;
}

/* 
 * @brief Returns YES if the passed subview can be collapsed
 */
- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	if (sender == splitView_textEntryHorizontal) {
		return NO;
		
	} else {
		NSLog(@"Unknown split view %@",sender);
		return 0;
	}
}

#pragma mark Shelfview
/* @name	setupShelfView
 * @brief	sets up shelfsplitview containing userlist & contentviews
 */
 -(void)setupShelfView
{
	[shelfView setShelfWidth:200];

	AILogWithSignature(@"ShelfView %@ (content view is %@) --> superview %@, in window %@; frame %@; content view %@ shelf view %@ in window %@",
					   shelfView, [shelfView contentView], [shelfView superview], [shelfView window], NSStringFromRect([[shelfView superview] frame]),
					   splitView_textEntryHorizontal,
					   scrollView_userList, [scrollView_userList window]);

	[shelfView bind:@"contextButtonMenu" toObject:[self chat] withKeyPath:@"actionMenu"
			options:[NSDictionary dictionaryWithObjectsAndKeys:
					 [NSNumber numberWithBool:YES], NSAllowsNullArgumentBindingOption,
					 [NSNumber numberWithBool:YES], NSValidatesImmediatelyBindingOption,
					 nil]];
	[shelfView setContextButtonImage:[NSImage imageNamed:@"sidebarActionWidget.png"]];

	[shelfView setShelfIsVisible:YES];
}

/* @name	toggleUserlist
 * @brief	toggles the state of the userlist shelf
 */
-(void)toggleUserlist:(id)sender
{	
	[shelfView setShelfIsVisible:![shelfView isShelfVisible]];
}	

@end
