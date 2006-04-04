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

#import "AIAccountSelectionView.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContactInfoWindowController.h"
#import "AIContentController.h"
#import "AIContentController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIInterfaceController.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIPreferenceController.h"
#import "ESContactAlertsController.h"
#import "ESGeneralPreferencesPlugin.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AISplitView.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIMessageEntryTextView.h>
#import <Adium/ESTextAndButtonsWindowController.h>

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
- (void)_updateAccountSelectionViewHeight;

- (void)saveUserListMinimumSize;
@end

@implementation AIMessageViewController

/*!
 * @brief Create a new message view controller
 */
+ (AIMessageViewController *)messageViewControllerForChat:(AIChat *)inChat
{
    return [[[self alloc] initForChat:inChat] autorelease];
}

/*!
 * @brief Initialize
 */
- (id)initForChat:(AIChat *)inChat
{
    if ((self = [super init]))
	{
		//Init
		chat = [inChat retain];
		view_accountSelection = nil;
		userListController = nil;
		sendMessagesToOfflineContact = [[chat account] supportsOfflineMessaging];
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

		//
		[splitView_textEntryHorizontal setDividerThickness:6]; //Default is 9
		[splitView_textEntryHorizontal setDrawsDivider:NO];
		
		//Configure our views
		[self _configureMessageDisplay];
		[self _configureTextEntryView];
		[self setAccountSelectionMenuVisibleIfNeeded:NO];
		
		//Update chat status and participating list objects to configure the user list if necessary
		[self chatStatusChanged:nil];
		[self chatParticipatingListObjectsChanged:nil];
		
		//Observe general preferences for sending keys
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];
	}

    return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{   
	[[adium preferenceController] unregisterPreferenceObserver:self];

	//Store our minimum height for the text entry area, and minimim width for the user list
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:entryMinHeight]
										 forKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	if (userListController) {
		[self saveUserListMinimumSize];
	}

	[chat release]; chat = nil;

    //remove observers
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    //Account selection view
	[self _destroyAccountSelectionView];
	
	//This is the controller for the actual view (not self, despite the naming oddness)
    [messageViewController release];
	[userListController release];

	[controllerView_messages release];
	
	//Release view_contents, for which we are responsible because we loaded it via -[NSBundle loadNibNamed:owner]
	[view_contents release];
	
	//Release the hidden user list view
	if (retainingScrollViewUserList) {
		[scrollView_userList release];
	}
	
    [super dealloc];
}

- (void)saveUserListMinimumSize
{
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:userListMinWidth]
										 forKey:KEY_ENTRY_USER_LIST_MIN_WIDTH
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Invoked before the message view closes
 *
 * This method is invoked before our message view controller's message view leaves a window.
 * We need to clean up our user list to invalidate cursor tracking before the view closes.
 */
- (void)messageViewWillLeaveWindow:(NSWindow *)inWindow
{
	if (inWindow) {
		[userListController contactListWillBeRemovedFromWindow];
	}
}

- (void)messageViewAddedToWindow:(NSWindow *)inWindow
{
	if (inWindow) {
		[userListController contactListWasAddedBackToWindow];
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
	if ( [[splitView_messages subviews] containsObject:scrollView_userList] && ([userListView selectedRow] != -1)) {
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
//XXX - This is a mess because of the naming confusion between AIMessageViewController and <AIMessageViewController>, which are actually two completely separate things :x -ai
- (void)_configureMessageDisplay
{
	//Create the message view
	messageViewController = [[[adium interfaceController] messageViewControllerForChat:chat] retain];
	//Get the messageView from the controller
	controllerView_messages = [[messageViewController messageView] retain];
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
	if ([messageViewController respondsToSelector:@selector(adiumPrint:)]) {
		[messageViewController adiumPrint:sender];
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
		
		if (!sendMessagesToOfflineContact &&
			![chat isGroupChat] &&
			![listObject online] &&
			![listObject isStranger] &&
			![[chat account] supportsOfflineMessaging]) {
			
			NSString			*messageHeader;
			NSAttributedString	*message;
			NSString			*formattedUID = [listObject formattedUID];
			messageHeader = [NSString stringWithFormat:AILocalizedString(@"%@ appears to be offline. How do you want to send this message?", nil),
				formattedUID];
			message = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:
				AILocalizedString(@"Send Later will send the message the next time both you and %@ are online. Send Now may work if %@ is invisible or is not on your contact list and so only appears to be offline.", "Send Later dialogue explanation text"),
				formattedUID, formattedUID, formattedUID]
													  attributes:nil];

			[ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:nil
																  defaultButton:AILocalizedString(@"Send Now", nil)
																alternateButton:AILocalizedString(@"Don't Send", nil)
																	otherButton:AILocalizedString(@"Send Later", nil)
																	   onWindow:[view_contents window]
															  withMessageHeader:messageHeader
																	 andMessage:message
																		  image:([listObject userIcon] ? [listObject userIcon] : [AIServiceIcons serviceIconForObject:listObject
																																								 type:AIServiceIconLarge
																																							direction:AIIconNormal])
																		 target:self
																	   userInfo:nil];
			[message release];

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
*
* @result YES to allow the close
*/
- (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo
{
	switch (returnCode) {
		case AITextAndButtonsDefaultReturn:
			[self setShouldSendMessagesToOfflineContacts:YES]; //don't ask again
			[self sendMessage:nil];
			break;

		case AITextAndButtonsOtherReturn:
			[self sendMessageLater:nil];
			break;
		case AITextAndButtonsAlternateReturn:
		case AITextAndButtonsClosedWithoutResponse:
			break;		
	}
	
	return YES;
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
}

/*!
 * @brief Offline messaging
 */
//XXX - Offline messaging code SHOULD NOT BE IN HERE! -ai
- (IBAction)sendMessageLater:(id)sender
{
	AIListContact	*listContact;
	
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

/*!
 * @brief Offline messaging
 */
//XXX - Offline messaging code SHOULD NOT BE IN HERE! -ai
- (void)setShouldSendMessagesToOfflineContacts:(BOOL)should
{
	sendMessagesToOfflineContact = should;
}


//Account Selection ----------------------------------------------------------------------------------------------------
#pragma mark Account Selection
/*!
 * @brief
 */
- (void)accountSelectionViewFrameDidChange:(NSNotification *)notification
{
	[self _updateAccountSelectionViewHeight];
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
		
		//Insert the account selection view at the top of our view
		[view_contents addSubview:view_accountSelection];
		[view_accountSelection setChat:chat];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accountSelectionViewFrameDidChange:)
													 name:AIViewFrameDidChangeNotification
												   object:view_accountSelection];
		
		[self _updateAccountSelectionViewHeight];
			
		//Redisplay everything
		[view_contents setNeedsDisplay:YES];
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
		[self _updateAccountSelectionViewHeight];
	}
}

/*!
 * @brief 
 */
- (void)_updateAccountSelectionViewHeight
{
	int		contentsHeight = [view_contents frame].size.height;
	int 	accountSelectionHeight = [view_accountSelection frame].size.height;
	
	[view_accountSelection setFrameOrigin:NSMakePoint([view_accountSelection frame].origin.x, 
													  contentsHeight - accountSelectionHeight)];
	[splitView_textEntryHorizontal setFrameSize:NSMakeSize([splitView_textEntryHorizontal frame].size.width,
														   contentsHeight - accountSelectionHeight)];
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
    [textView_outgoing setTextContainerInset:NSMakeSize(0,2)];
    if ([textView_outgoing respondsToSelector:@selector(setUsesFindPanel:)]) {
		[textView_outgoing setUsesFindPanel:YES];
    }
	[textView_outgoing setClearOnEscape:YES];
	[textView_outgoing setTypingAttributes:[[adium contentController] defaultFormattingAttributes]];
	
	//User's choice of mininum height for their text entry view
	entryMinHeight = [[[adium preferenceController] preferenceForKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
															   group:PREF_GROUP_DUAL_WINDOW_INTERFACE] intValue];
	if (entryMinHeight < ENTRY_TEXTVIEW_MIN_HEIGHT) entryMinHeight = ENTRY_TEXTVIEW_MIN_HEIGHT;

	
	//Associate the view with our message view so it knows which view to scroll in response to page up/down
	//and other special key-presses.
	[textView_outgoing setAssociatedView:[messageViewController messageScrollView]];
	
	//Associate the text entry view with our chat and inform Adium that it exists.
	//This is necessary for text entry filters to work correctly.
	[textView_outgoing setChat:chat];
	
    //Observe text entry view size changes so we can dynamically resize as the user enters text
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outgoingTextViewDesiredSizeDidChange:)
												 name:AIViewDesiredSizeDidChangeNotification 
											   object:textView_outgoing];
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
	BOOL				tigerOrBetter = [NSApp isOnTigerOrBetter];

	if (tigerOrBetter) {
		writingDirection = [textView_outgoing baseWritingDirection];
	} else {
		//Just silencing gcc; this will
		writingDirection = NSWritingDirectionLeftToRight;
	}
	
	[textView_outgoing setString:@""];
	[textView_outgoing setTypingAttributes:[[adium contentController] defaultFormattingAttributes]];
	
	if (tigerOrBetter) {
		[textView_outgoing setBaseWritingDirection:writingDirection];	//Preserve the writing diraction
	}

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
 * @brief Update the text entry view's height when its desired size changes
 */
- (void)outgoingTextViewDesiredSizeDidChange:(NSNotification *)notification
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
	int		heightWithDivider = [splitView_textEntryHorizontal dividerThickness] + height;
	NSRect	tempFrame, newFrame;
	BOOL	changed = NO;
	
	//Display the vertical scroller if our view is not tall enough to display all the entered text
	[scrollView_outgoing setHasVerticalScroller:(height < [textView_outgoing desiredSize].height)];

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

	//Size the message split view to fill the remaining space
	tempFrame = [splitView_messages frame];
	newFrame = NSMakeRect(tempFrame.origin.x,
						  tempFrame.origin.y,
						  tempFrame.size.width,
						  [splitView_textEntryHorizontal frame].size.height - heightWithDivider);
	if (!NSEqualRects(tempFrame, newFrame)) {
		[splitView_messages setFrame:newFrame];
		[splitView_messages setNeedsDisplay:YES];
		changed = YES;
	}

	if (changed) {		
		//Redisplay the window on the next run loop
		[[splitView_textEntryHorizontal window] performSelector:@selector(display)
													 withObject:nil
													 afterDelay:0];
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
	return [[splitView_messages subviews] containsObject:scrollView_userList];
}

/*!
 * @brief Show the user list
 */
- (void)_showUserListView
{
	//Configure the user list
	[self _configureUserList];

	//Add the user list back to our window if it's missing
	if (![self userListVisible]) {
		[splitView_messages addSubview:scrollView_userList];
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

		[userListController release]; userListController = nil;
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
    //We display the user list if it contains more than one user, or if someone has specified that it be visible
	[self setUserListVisible:([chat integerStatusObjectForKey:@"AlwaysShowUserList"] ||
							  [[chat participatingListObjects] count] > 1)];
	
    //Update the user list
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
									  [[chat participatingListObjects] objectAtIndex:selectedIndex] :
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
	int		widthWithDivider = [splitView_messages dividerThickness] + width;
	NSRect	tempFrame;

	//Size the user list view to the desired width
	tempFrame = [scrollView_userList frame];
	[scrollView_userList setFrame:NSMakeRect([splitView_messages frame].size.width - width,
											 tempFrame.origin.y,
											 width,
											 tempFrame.size.height)];
	
	//Size the message view to fill the remaining space
	tempFrame = [scrollView_messages frame];
	[scrollView_messages setFrame:NSMakeRect(tempFrame.origin.x,
											 tempFrame.origin.y,
											 [splitView_messages frame].size.width - widthWithDivider,
											 tempFrame.size.height)];

	//Redisplay both views and the divider
	[splitView_messages setNeedsDisplay:YES];
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
	int dividerThickness = [splitView_messages dividerThickness];
	int allowedWidth = ([splitView_messages frame].size.width / 2.0) - dividerThickness;
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

	} else /*if (sender == splitView_messages)*/ {
		return ([sender frame].size.width - ([self _userListViewProperWidthIgnoringUserMininum:YES] +
											[sender dividerThickness]));
		
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
		
	} else /*if (sender == splitView_messages)*/ {
		return (int)([sender frame].size.width * MESSAGE_VIEW_MIN_WIDTH_RATIO);
		
	}
}

/*!
 * @brief A split view had its divider position changed
 *
 * Remember the user's choice of text entry view height.
 */
- (float)splitView:(NSSplitView *)splitView constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)index
{
	if (splitView == splitView_textEntryHorizontal) {
		entryMinHeight = (int)([splitView frame].size.height - (proposedPosition + [splitView dividerThickness]));
		
	} else /*if (splitView == splitView_messages)*/ {
		userListMinWidth = (int)([splitView frame].size.width - (proposedPosition + [splitView dividerThickness]));

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
		
	} else /*if (sender == splitView_messages)*/ {
		return subview == scrollView_userList;
		
	}
}

/* 
 * @brief Manually adjust the split views during resize
 *
 * The default resizing behavior does an absolutely horrible job of maintaining proportionality when the
 * window is resized in odd increments.  To combat this and provide nice behavior such as not changing the
 * height of the text entry area unless necessary while resizing, we use completely custom view sizing code
 * for our split panes.
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if ([[sender subviews] count] == 2) {
		NSView	*view1 = [[sender subviews] objectAtIndex:0];
		NSView	*view2 = [[sender subviews] objectAtIndex:1];
		
		//Change in width and height
		NSSize	newSize = [sender frame].size;
		int		dWidth  = newSize.width - oldSize.width;
		int		dHeight = newSize.height - oldSize.height;

		//Behavior varies depending on which split view is resizing
		if (sender == splitView_textEntryHorizontal) {
			//Adjust the height of both views
			[self _updateTextEntryViewHeight];
			
			//Adjust the width of both views to fill remaining space
			[view1 setFrameSize:NSMakeSize(newSize.width + dWidth, [view1 frame].size.height)];
			[view2 setFrameSize:NSMakeSize(newSize.width + dWidth, [view2 frame].size.height)];
			
		} else /*if (sender == splitView_messages)*/{
			//Adjust the width of both views
			[self _updateUserListViewWidth];

			//Adjust the height of both views to fill remaining space
			[view1 setFrameSize:NSMakeSize([view1 frame].size.width, newSize.height + dHeight)];
			[view2 setFrameSize:NSMakeSize([view2 frame].size.width, newSize.height + dHeight)];
		}
		
	} else if ([[sender subviews] count] == 1) {
		[[[sender subviews] objectAtIndex:0] setFrame:[sender frame]];
		
	}
}

@end

