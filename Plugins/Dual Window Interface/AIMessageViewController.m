/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIAccountSelectionView.h"
#import "CSMessageToOfflineContactWindowController.h"
#import "AIContactInfoWindowController.h"

#define MESSAGE_VIEW_NIB					@"MessageView"		//Filename of the message view nib
#define MESSAGE_TAB_TOOLBAR					@"MessageTab"		//ID of the message tab toolbar
#define ENTRY_TEXTVIEW_MIN_HEIGHT			20
#define ENTRY_TEXTVIEW_DEFAULT_MIN_HEIGHT	(ENTRY_TEXTVIEW_MIN_HEIGHT + 5)
#define ENTRY_TEXTVIEW_MAX_HEIGHT_PERCENT	.50
#define RESIZE_CORNER_TOOLBAR_OFFSET 		0
#define TEXT_ENTRY_PADDING					3
#define USER_LIST_WIDTH						75

#define	USERLIST_THEME						@"UserList Theme"
#define	USERLIST_LAYOUT						@"UserList Layout"

#define	KEY_ENTRY_TEXTVIEW_MIN_HEIGHT		@"Minimum Height"

@interface AIMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat;
- (void)dealloc;
- (void)textDidChange:(NSNotification *)notification;
- (void)sizeAndArrangeSubviews;
- (void)clearTextEntryView;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)listObjectStatusChanged:(NSNotification *)notification;
- (void)chatStatusChanged:(NSNotification *)notification;
- (void)redisplaySourceAndDestinationSelector:(NSNotification *)notification;
@end

@implementation AIMessageViewController

//Create a new message view controller
+ (AIMessageViewController *)messageViewControllerForChat:(AIChat *)inChat
{
    return([[[self alloc] initForChat:inChat] autorelease]);
}

//Init
- (id)initForChat:(AIChat *)inChat
{
    [super init];

    //
    view_accountSelection = nil;
	userListController = nil;
    delegate = nil;
    chat = nil;
    showUserList = NO;
	sendMessagesToOfflineContact = NO;
	inSizeAndArrange = NO;

	NSNumber	*minHeightNumber = [[adium preferenceController] preferenceForKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
																			group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	entryMinHeight = (minHeightNumber ? [minHeightNumber floatValue] : (ENTRY_TEXTVIEW_DEFAULT_MIN_HEIGHT));

    //view
    [NSBundle loadNibNamed:MESSAGE_VIEW_NIB owner:self];
	
	//We'll be removing this from our view at times; retain it manually to keep it around.
	[scrollView_userList retain];
	
	//Configure our chat
	chat = [inChat retain];

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
	
	//Create the message view
	messageViewController = [[[adium interfaceController] messageViewControllerForChat:chat] retain];
	
	//Get the messageView from the controller
	controllerView_messages = [[messageViewController messageView] retain];
	[controllerView_messages setFrame:[scrollView_messages frame]];
	
	//scrollView_messages is originally a placeholder; replace it with controllerView_messages
	[[scrollView_messages superview] replaceSubview:scrollView_messages with:controllerView_messages];
	
	//scrollView_messages should now be a containing view from the controller; it may or may not be the same as controllerView_messages
	scrollView_messages = [messageViewController messageScrollView];

	[controllerView_messages setNextResponder:textView_outgoing];

	// Set up the split view
	[splitView_messages setDelegate:self];
	
    //Configure the outgoing text view
	[textView_outgoing setChat:chat];
    [textView_outgoing setTarget:self action:@selector(sendMessage:)];
	[textView_outgoing setAssociatedView:scrollView_messages];
	
    [textView_outgoing setTextContainerInset:NSMakeSize(0,2)];
    if([textView_outgoing respondsToSelector:@selector(setUsesFindPanel:)]){
		[textView_outgoing setUsesFindPanel:YES];
    }
	[textView_outgoing setClearOnEscape:YES];
	[[adium contentController] didOpenTextEntryView:textView_outgoing];

    //Register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(sizeAndArrangeSubviews)
												 name:NSViewFrameDidChangeNotification
											   object:view_contents];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outgoingTextViewDesiredSizeDidChange:)
												 name:AIViewDesiredSizeDidChangeNotification 
											   object:textView_outgoing];
    
	[[adium notificationCenter] addObserver:self
								   selector:@selector(chatParticipantsChanged:)
									   name:Chat_ParticipatingListObjectsChanged
									 object:nil];
	
    //Finish everything up
	[self chatStatusChanged:nil];
	[self chatParticipatingListObjectsChanged:nil];

	//Now do a size and arrange once everything is set up
	[self sizeAndArrangeSubviews];	

    return(self);
}

//
- (void)dealloc
{    
    //Close the message entry text view
    [[adium contentController] willCloseTextEntryView:textView_outgoing];

    //Close chat
    if(chat){
        [[adium contentController] closeChat:chat];
        [chat release]; chat = nil;
    }
	
    //remove notifications
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    //Account selection view
    if(view_accountSelection){
		[view_accountSelection setDelegate:nil]; //Make sure it doesn't try and talk to us after we're gone
        [view_accountSelection removeFromSuperview];
        [view_accountSelection release]; view_accountSelection = nil;
    }
	
	//This is the controller for the actual view (not self, despite the naming oddness)
    [messageViewController release];

	[scrollView_userList release];
	[controllerView_messages release];
	[view_contents release];
	
    [super dealloc];
}

- (void)tabViewItemWillClose
{
	//Store our minimum height for the text entry area
	[[adium preferenceController] setPreference:[NSNumber numberWithFloat:entryMinHeight]
										 forKey:KEY_ENTRY_TEXTVIEW_MIN_HEIGHT
											 group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	
	//Release the userListController to let it invalidate its tracking views before closing the window
	[userListController release]; userListController = nil;
}

//Return our view
- (NSView *)view
{
    return(view_contents);
}

- (NSObject<AIMessageViewController> *)messageViewController
{
	return(messageViewController);
}

//
- (void)setDelegate:(id)inDelegate
{
    delegate = inDelegate;
}

- (AIChat *)chat{
    return(chat);
}

//The source account of this message
- (void)setAccount:(AIAccount *)inAccount
{
	if(inAccount != [chat account]){
		[[adium contentController] switchChat:chat toAccount:inAccount];
	}
}
- (AIAccount *)account{
    return([chat account]);
}

//Set the target list object of this message view's chat to be identical to listContact (though not necessarily on
//the same account - use setAccount: to change the source account.)
- (void)setListObject:(AIListContact *)listContact
{
	if(listContact != [chat listObject]){
		[[adium contentController] switchChat:chat toListContact:listContact usingContactAccount:NO];
	}
}

//For our account selector view
- (AIListContact *)listObject
{
    return([chat listObject]);
}

//Toggle the visibility of our account selection menu
- (void)setAccountSelectionMenuVisible:(BOOL)visible
{
	BOOL visibilityChanged = NO;
	
	//Ignore requests to show the selection menu if there are no options present
	if(![AIAccountSelectionView optionsAvailableForSendingContentType:CONTENT_MESSAGE_TYPE
															toContact:[chat listObject]]){
		visible = NO;
	}

	//
    if(visible && !view_accountSelection){ //Show the account selection view
        view_accountSelection = [[AIAccountSelectionView alloc] initWithFrame:NSMakeRect(0,0,100,100) delegate:self];
        [view_contents addSubview:view_accountSelection];
		visibilityChanged = YES;
		
    }else if(!visible && view_accountSelection){ //Hide the account selection view
		[view_accountSelection setDelegate:nil]; //Make sure it doesn't try and talk to us after we're gone
        [view_accountSelection removeFromSuperview];
        [view_accountSelection release]; view_accountSelection = nil;
		visibilityChanged = YES;
    }

	if(view_accountSelection){
		//Update the selected account
		[view_accountSelection updateMenu];
	}
	
    //
	if(visibilityChanged){
		[self sizeAndArrangeSubviews];
		[view_contents setNeedsDisplay:YES];
	}
}

//Selected item in the group chat view
- (AIListObject *)preferredListObject
{
	if( [[splitView_messages subviews] containsObject:scrollView_userList] && ([userListView selectedRow] != -1)) {
		return [userListView itemAtRow:[userListView selectedRow]];
	}
	
	return nil;
}

//Send the entered message
- (IBAction)sendMessage:(id)sender
{
    if([[textView_outgoing attributedString] length] != 0){ //If message length is 0, don't send
        AIContentMessage			*message;
		NSMutableAttributedString	*outgoingAttributedString = [[[textView_outgoing textStorage] copy] autorelease];
		AIListObject				*listObject = [chat listObject];
		
		if (!sendMessagesToOfflineContact &&
			![chat name] &&
			![listObject online] &&
			![listObject isStranger]){
			
			//Contact is offline.  Ask how the user wants to handle the situation.
			[CSMessageToOfflineContactWindowController showSheetInWindow:[view_contents window]
												forMessageViewController:self];
			
		} else {
			AIAccount	*account = [chat account];
			
			//Send the message
			[[adium notificationCenter] postNotificationName:Interface_WillSendEnteredMessage
													  object:chat
													userInfo:nil];
			
			message = [AIContentMessage messageInChat:chat
										   withSource:account
										  destination:nil //meaningless, since we get better info from the AIChat
												 date:nil //created for us by AIContentMessage
											  message:outgoingAttributedString
											autoreply:NO];
			
			if([[adium contentController] sendContentObject:message]){
				BOOL	suppressTypingNotificationChangesAfterSend = [account suppressTypingNotificationChangesAfterSendForListObject:listObject];

				if(suppressTypingNotificationChangesAfterSend){
					//Let the account handle clearing the typing notification if necessary for cleaner interaction between
					//the not-typing state and the message-received state viewed on the other side

					[chat setStatusObject:[NSNumber numberWithBool:YES] 
								   forKey:@"SuppressTypingNotificationChanges"
								   notify:NotifyNever];
				}
				
				[[adium notificationCenter] postNotificationName:Interface_DidSendEnteredMessage 
														  object:chat
														userInfo:nil];
				
				if(suppressTypingNotificationChangesAfterSend){
					//On the next run loop (after we are finished processing all events from the keystroke or click which
					//led to sendMessage:) clear the suppression flag
					[self performSelector:@selector(endSuppressChatTypingNotificationChanges)
							   withObject:nil
							   afterDelay:0.00000001];
				}
			}
		}
    }
}

- (void)endSuppressChatTypingNotificationChanges{
	[chat setStatusObject:nil
				   forKey:@"SuppressTypingNotificationChanges"
				   notify:NotifyNever];
}

//The entered message was sent
- (IBAction)didSendMessage:(id)sender
{
    [self setAccountSelectionMenuVisible:NO];
    [self clearTextEntryView];
}

- (IBAction)sendMessageLater:(id)sender
{
	AIListObject		*listObject;
	
	//Put the alert on the metaContact containing this listObject if applicable
	listObject = [[adium contactController] parentContactForListObject:[chat listObject]];
	
	if (listObject){
		NSMutableDictionary *detailsDict, *alertDict;
		
		detailsDict = [NSMutableDictionary dictionary];
		[detailsDict setObject:[[chat account] internalObjectID] forKey:@"Account ID"];
		[detailsDict setObject:[NSNumber numberWithBool:YES] forKey:@"Allow Other"];
		[detailsDict setObject:[listObject internalObjectID] forKey:@"Destination ID"];

		alertDict = [NSMutableDictionary dictionary];
		[alertDict setObject:detailsDict forKey:@"ActionDetails"];
		[alertDict setObject:CONTACT_SEEN_ONLINE_YES forKey:@"EventID"];
		[alertDict setObject:@"SendMessage" forKey:@"ActionID"];
		[alertDict setObject:[NSNumber numberWithBool:YES] forKey:@"OneTime"]; 
		
		[alertDict setObject:listObject forKey:@"TEMP-ListObject"];
		
		[[adium contentController] filterAttributedString:[[[textView_outgoing textStorage] copy] autorelease]
										  usingFilterType:AIFilterContent
												direction:AIFilterOutgoing
											filterContext:listObject
										  notifyingTarget:self
												 selector:@selector(gotFilteredMessageToSendLater:receivingContext:)
												  context:alertDict];

		[self didSendMessage:nil];
	}
}

- (void)gotFilteredMessageToSendLater:(NSAttributedString *)filteredMessage receivingContext:(NSMutableDictionary *)alertDict
{
	NSMutableDictionary	*detailsDict;
	AIListObject		*listObject;
	
	detailsDict = [alertDict objectForKey:@"ActionDetails"];
	[detailsDict setObject:[filteredMessage dataRepresentation] forKey:@"Message"];

	listObject = [[alertDict objectForKey:@"TEMP-ListObject"] retain];
	[alertDict removeObjectForKey:@"TEMP-ListObject"];
	
	[[adium contactAlertsController] addAlert:alertDict 
								 toListObject:listObject
							 setAsNewDefaults:NO];
	[listObject release];
}

- (void)setShouldSendMessagesToOfflineContacts:(BOOL)should
{
	sendMessagesToOfflineContact = should;
}

- (IBAction)inviteUser:(id)sender
{
}

//Sets our text entry view as the first responder
- (void)makeTextEntryViewFirstResponder
{
    [[textView_outgoing window] makeFirstResponder:textView_outgoing];
}

//Clear the message entry text view
- (void)clearTextEntryView
{
	[textView_outgoing setString:@""];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
														object:textView_outgoing];
}

//Add to the message entry text view (at the insertion point, replacing the selection if present)
- (void)addToTextEntryView:(NSAttributedString *)inString
{
    [textView_outgoing insertText:inString];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView_outgoing];
}


//Our chat's participating list objects did change
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification
{
    NSArray	*participatingListObjects = [chat participatingListObjects];
    BOOL	listVisible;

    //We display the user list if it contains more than one user, or if someone has specified that it be visible.
    if([chat integerStatusObjectForKey:@"AlwaysShowUserList"] ||
       [participatingListObjects count] > 1){
        listVisible = YES;
    }else{
        listVisible = NO;
    }

    //Show/hide the userlist
    if(listVisible != showUserList){
        showUserList = listVisible;
        [self sizeAndArrangeSubviews];
		[view_contents setNeedsDisplay:YES];
    }

    //Update the user list
    if(showUserList){
        [userListController reloadData];
    }
}

//YES if the user list is visible
- (BOOL)userListVisible
{
	return(showUserList);
}


//Our chat's account changed, re-show the from selector
- (void)redisplaySourceAndDestinationSelector:(NSNotification *)notification
{
	[self setAccountSelectionMenuVisible:YES];
}

//Our chat's status did change
- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*modifiedKeys = [[notification userInfo] objectForKey:@"Keys"];

    if(notification == nil || [modifiedKeys containsObject:@"Enabled"]){
        [button_send setEnabled:([[textView_outgoing string] length] != 0)];
    }

    if(notification == nil || [modifiedKeys containsObject:@"DisallowAccountSwitching"]){
        BOOL disallowAccountChanging = [chat integerStatusObjectForKey:@"DisallowAccountSwitching"];

        //Disallow source account switching
        if(disallowAccountChanging){
            [self setAccountSelectionMenuVisible:NO];
        }
    }
}

//The entered text has changed
- (void)textDidChange:(NSNotification *)notification
{
    BOOL enabled;

    //Enable/Disable our sending button
    enabled = ([[textView_outgoing string] length] != 0);
    if([button_send isEnabled] != enabled){
        [button_send setEnabled:enabled];
    }
}

//Text entry view desired size has changed
- (void)outgoingTextViewDesiredSizeDidChange:(NSNotification *)notification
{
    [self sizeAndArrangeSubviews];
    [view_contents setNeedsDisplay:YES];
}

/*
 * @brief Arrange and resize our subviews 
 *
 * This shows/hides as appropriate the contact/account selection view and the group chat user list,
 * sizes the text entry area, and sizes the message view to take up the remaining space.
 *
 * sizeAndArrangeSubviews guards against its frame changes calling it to be called again. This guard is also used
 * to determine if a resizing event is caused by the user dragging a splitview divider or programatically, elsewhere in
 * this class.
 */
- (void)sizeAndArrangeSubviews
{
	if(!inSizeAndArrange){
		inSizeAndArrange = YES;

		float	textHeight;
		int		height;
		NSRect	superFrame = [view_contents frame];
		NSRect	targetRect;

		superFrame.origin.y = 0;
		superFrame.origin.x = 0;
		
		//Account
		if(view_accountSelection){
			height = [view_accountSelection frame].size.height;
			
			[view_accountSelection setFrame:NSMakeRect(0, superFrame.size.height - height, superFrame.size.width, height)];
			[view_accountSelection setNeedsDisplay:YES];
			superFrame.size.height -= height;
		}
		
		//Split view taking up the rest of the window
		targetRect = NSMakeRect(superFrame.origin.x,
								superFrame.origin.y,
								(superFrame.size.width),
								superFrame.size.height);
		if(!NSEqualRects([splitView_textEntryHorizontal frame], targetRect)){
			[splitView_textEntryHorizontal setFrame:targetRect];
			[splitView_textEntryHorizontal setNeedsDisplay:YES];
		}
		
		//Text entry
		float	entryMaxHeight = [view_contents frame].size.height * ENTRY_TEXTVIEW_MAX_HEIGHT_PERCENT;
		textHeight = [textView_outgoing desiredSize].height;
		if(textHeight > entryMaxHeight){
			textHeight = entryMaxHeight;
		}else if(textHeight < entryMinHeight){
			textHeight = entryMinHeight;
		}

		//Why magic + 1?
		targetRect = NSMakeRect(superFrame.origin.y, superFrame.origin.x, superFrame.size.width + 1, textHeight);
		if(!NSEqualSizes([scrollView_outgoing frame].size, targetRect.size)){
			[scrollView_outgoing setHasVerticalScroller:(textHeight == entryMaxHeight)];
			[scrollView_outgoing setFrame:targetRect];
			[scrollView_outgoing setNeedsDisplay:YES];
		}
		
		superFrame.size.height -= textHeight + [splitView_textEntryHorizontal dividerThickness];
		superFrame.origin.y += textHeight + [splitView_textEntryHorizontal dividerThickness];
		
		//Split View with UserList and Messages.  Why magic + 1's?
		targetRect = NSMakeRect(superFrame.origin.x,
								superFrame.origin.y,
								(superFrame.size.width + 1),
								superFrame.size.height + 1);
		if(!NSEqualRects([splitView_messages frame], targetRect)){
			[splitView_messages setFrame:targetRect];
			[splitView_messages setNeedsDisplay:YES];
		}
		
		//UserList
		if(showUserList){
			
			if (!userListController) {
				NSDictionary	*themeDict = [NSDictionary dictionaryNamed:USERLIST_THEME forClass:[self class]];
				NSDictionary	*layoutDict = [NSDictionary dictionaryNamed:USERLIST_LAYOUT forClass:[self class]];
				
				userListController = [[ESChatUserListController alloc] initWithContactListView:userListView
																				  inScrollView:scrollView_userList 
																					  delegate:self];
				
				[userListController updateLayoutFromPrefDict:layoutDict andThemeFromPrefDict:themeDict];
				[userListController updateTransparencyFromLayoutDict:layoutDict themeDict:themeDict];	
				[userListController setContactListRoot:chat];
				[userListController setHideRoot:YES];
				
			}
			
			if( ![[splitView_messages subviews] containsObject:scrollView_userList] ) {
				[splitView_messages addSubview:scrollView_userList];
				
				NSRect splitFrame = [splitView_messages frame];
				//NSRect buttonFrame = [button_inviteUser frame];
				[controllerView_messages setFrame:NSMakeRect(0,0,NSWidth(splitFrame)-USER_LIST_WIDTH-[splitView_messages dividerThickness],NSHeight(splitFrame))];
				[controllerView_messages setNeedsDisplay:YES];
				[scrollView_userList setFrame:NSMakeRect(NSWidth(splitFrame)-USER_LIST_WIDTH,0,USER_LIST_WIDTH,NSHeight(splitFrame))];
				[scrollView_userList setNeedsDisplay:YES];
				
				//NSRect userFrame = [view_userPane frame];
				//[scrollView_userList setFrame:NSMakeRect(0,0,NSWidth(userFrame),NSHeight(userFrame))];
				//[button_inviteUser setFrame:NSMakeRect(0,0,25,25)];
			}
		}else{		
			if( [[splitView_messages subviews] containsObject:scrollView_userList] ) {
				[scrollView_userList removeFromSuperview];
			}
		}
		
		//Messages
		[splitView_textEntryHorizontal displayIfNeeded];
		[view_accountSelection displayIfNeeded];

		inSizeAndArrange = NO;
	}
}

#pragma mark ESChatUserListController delegate
/*
 * @brief The selection in the chat user list changed
 *
 * Set the chat's "preferred list object" which is used for things like the Get Info and Message buttons.
 *
 * @param notification A notification with an AIListOutlineView object which corresponds to our userListView if intended for us
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == userListView){
		int selectedIndex = [userListView selectedRow];
		[chat setPreferredListObject:((selectedIndex != -1) ? 
									  [[chat participatingListObjects] objectAtIndex:selectedIndex] :
									  nil)];
	}
}

/*
 * @brief Participants in the chat changed
 *
 * Reload the user list data
 *
 * @param notification A notification with an AIChat object which corresponds to our chat if intended for us
 */
- (void)chatParticipantsChanged:(NSNotification *)notification
{
	if([notification object] == chat){
		[userListController reloadData];
	}
}

#pragma mark Split View Delegate

/*
 *
 * @param sender The splitView
 * @param proposedMax The proposed maximum, in the sender's flipped coordinate system. For a horizontal divider, this is distance from the top.
 */
- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	if(sender == splitView_textEntryHorizontal){
		//Maximum of the top portion is the hieght less the minimum textview entry height
		return (proposedMax - ENTRY_TEXTVIEW_MIN_HEIGHT);
		
	}else /*if(sender == splitView_messages)*/ {
		return proposedMax;
	}
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	if(sender == splitView_textEntryHorizontal){
		return ([view_contents frame].size.height * (1-ENTRY_TEXTVIEW_MAX_HEIGHT_PERCENT));
		
	}else /*if(sender == splitView_messages)*/ {
		return proposedMin;
	}
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	if(subview == userListView || subview == scrollView_userList){
		return YES;
	}else{
		return NO;
	}
}

/*
 * @brief A split view had its divider position changed
 *
 * This is called both when the user drags the divider and when we change the frame programatically.
 * We only want to use it when the user drags the divider, so we can know our new minimum height, so we only take action
 * if inSizeAndArrange is NO.
 *
 * @param notification A notification whose object is an NSSplitView.
 */
- (void)splitViewDidResizeSubviews:(NSNotification *)notification
{
	if(([notification object] == splitView_textEntryHorizontal) && !inSizeAndArrange){
		entryMinHeight = [scrollView_outgoing frame].size.height;
	}
}

#pragma mark AIListControllerDelegate

- (void)performDefaultActionOnSelectedObject:(AIListObject *)listObject sender:(id)sender
{
	/*
	 int selectedIndex = [tableView_userList selectedRow];
	 
	 if( selectedIndex != -1 ) {
		 
		 AIListObject *listObject = [[chat participatingListObjects] objectAtIndex:selectedIndex];
		 if (listObject)
			 [AIContactInfoWindowController showInfoWindowForListObject:listObject];
	 }
	 */
}

@end

