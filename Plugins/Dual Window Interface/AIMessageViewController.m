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

#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
//#import "AIDualWindowInterfacePlugin.h"
#import "AIAccountSelectionView.h"
#import "CSMessageToOfflineContactWindowController.h"
#import "AIContactInfoWindowController.h"

#define MESSAGE_VIEW_NIB					@"MessageView"		//Filename of the message view nib
#define MESSAGE_TAB_TOOLBAR					@"MessageTab"		//ID of the message tab toolbar
#define ENTRY_TEXTVIEW_MIN_HEIGHT			20
#define ENTRY_TEXTVIEW_MAX_HEIGHT_PERCENT	.50
#define RESIZE_CORNER_TOOLBAR_OFFSET 		0
#define TEXT_ENTRY_PADDING					3
#define USER_LIST_WIDTH						75

@interface AIMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat;
- (void)dealloc;
- (void)textDidChange:(NSNotification *)notification;
- (void)sizeAndArrangeSubviews;
- (void)clearTextEntryView;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)listObjectStatusChanged:(NSNotification *)notification;
- (void)chatStatusChanged:(NSNotification *)notification;
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
    delegate = nil;
    chat = nil;
    showUserList = NO;
	sendMessagesToOfflineContact = NO;
	
    //view
    [NSBundle loadNibNamed:MESSAGE_VIEW_NIB owner:self];
	
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
								   selector:@selector(chatAccountChanged:) 
									   name:Chat_AccountChanged
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
	/*if (controllerView_messages != scrollView_messages)
		[scrollView_messages setNextResponder:controllerView_messages];
*/
//	[[scrollView_messages superview] addSubview:[messageViewController messageView]];
//	[[messageViewController messageView] setFrame:[scrollView_messages frame]];
//	[scrollView_messages removeFromSuperview];
//	scrollView_messages = [[messageViewController messageView] retain];
	
//	[scrollView_messages setAndSizeDocumentView:[messageViewController messageView]];
//	[scrollView_messages setNextResponder:textView_outgoing];
//	[scrollView_messages setAutoScrollToBottom:YES];
//	[scrollView_messages setAutoHideScrollBar:NO];
//	[scrollView_messages setHasVerticalScroller:YES];
	
	//User List
	//[view_userPane retain];
		
	[scrollView_userList setAutoScrollToBottom:NO];
	[scrollView_userList setAutoHideScrollBar:YES];
	[scrollView_userList retain];
	
	[tableView_userList setDelegate:self];
	[tableView_userList setTarget:self];
	[tableView_userList setDoubleAction:@selector(cellWasDoubleClicked:)];
	[tableView_userList setNextResponder:controllerView_messages];
	
	//NSTableColumn *leftCol = [[tableView_userList tableColumns] objectAtIndex:0];
	//[leftCol setDataCell:[[[NSImageCell alloc] init] autorelease]];

	/*
	 //The image column does not currently exist
	NSTableColumn *leftCol = [[tableView_userList tableColumns] objectAtIndex:0];
	[leftCol setDataCell:[[[NSImageCell alloc] init] autorelease]];
	*/
	
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
								   selector:@selector(listObjectChanged:)
									   name:ListObject_StatusChanged
									 object:nil];

	[[adium notificationCenter] addObserver:self
								   selector:@selector(chatParticipantsChanged:)
									   name:Chat_ParticipatingListObjectsChanged
									 object:nil];
	
    //Finish everything up
	[self chatStatusChanged:nil];
	[self sizeAndArrangeSubviews];
	
	[self chatParticipatingListObjectsChanged:nil];
	
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
	
    //nib
    [messageViewController release];
	
    [super dealloc];
}

//Return our view
- (NSView *)view{
    return(view_contents);
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
	//Ignore requests to show the selection menu if there are no options present
	if(![AIAccountSelectionView optionsAvailableForSendingContentType:CONTENT_MESSAGE_TYPE
															toContact:[chat listObject]]){
		visible = NO;
	}

	//
    if(visible && !view_accountSelection){ //Show the account selection view
        view_accountSelection = [[AIAccountSelectionView alloc] initWithFrame:NSMakeRect(0,0,100,100) delegate:self];
        [view_contents addSubview:view_accountSelection];
		
    }else if(!visible && view_accountSelection){ //Hide the account selection view
		[view_accountSelection setDelegate:nil]; //Make sure it doesn't try and talk to us after we're gone
        [view_accountSelection removeFromSuperview];
        [view_accountSelection release]; view_accountSelection = nil;
    }

	if(view_accountSelection){
		//Update the selected account
		[view_accountSelection updateMenu];
	}
	
    //
    [self sizeAndArrangeSubviews];
	[view_contents setNeedsDisplay:YES];

}

//Selected item in the group chat view
- (AIListObject *)preferredListObject
{
	if( [[splitView_messages subviews] containsObject:scrollView_userList] && ([tableView_userList selectedRow] != -1)) {
		return [[chat participatingListObjects] objectAtIndex:[tableView_userList selectedRow]];
	}
	
	return nil;
}

//Send the entered message
- (IBAction)sendMessage:(id)sender
{
    if([[textView_outgoing attributedString] length] != 0){ //If message length is 0, don't send
        AIContentMessage			*message;
		NSMutableAttributedString	*outgoingAttributedString = [[[textView_outgoing textStorage] copy] autorelease];

		if (!sendMessagesToOfflineContact &&
			![chat name] &&
			![[chat listObject] online] &&
			![[chat listObject] integerStatusObjectForKey:@"Stranger"]){
			
			//Contact is offline.  Ask how the user wants to handle the situation.
			[CSMessageToOfflineContactWindowController showSheetInWindow:[view_contents window] forMessageViewController:self];
			
		} else {
			//Send the message
			[[adium notificationCenter] postNotificationName:Interface_WillSendEnteredMessage object:chat userInfo:nil];
			
			message = [AIContentMessage messageInChat:chat
										   withSource:[chat account]
										  destination:nil //meaningless, since we get better info from the AIChat
												 date:nil //created for us by AIContentMessage
											  message:outgoingAttributedString
											autoreply:NO];
			
			if([[adium contentController] sendContentObject:message]){
				[[adium notificationCenter] postNotificationName:Interface_DidSendEnteredMessage object:chat userInfo:nil];
			}
		}
    }
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
	
	listObject = [chat listObject];
	if (listObject){
		NSMutableDictionary *detailsDict, *alertDict;
		NSAttributedString	*message;
		
		message = [[adium contentController] filterAttributedString:[[[textView_outgoing textStorage] copy] autorelease]
													usingFilterType:AIFilterContent
														  direction:AIFilterOutgoing
															context:listObject];
		
		detailsDict = [NSMutableDictionary dictionary];
		[detailsDict setObject:[[chat account] internalObjectID] forKey:@"Account ID"];
		[detailsDict setObject:[NSNumber numberWithBool:YES] forKey:@"Allow Other"];
		[detailsDict setObject:[listObject internalObjectID] forKey:@"Destination ID"];
		[detailsDict setObject:[message dataRepresentation] forKey:@"Message"];
		
		alertDict = [NSMutableDictionary dictionary];
		[alertDict setObject:detailsDict forKey:@"ActionDetails"];
		[alertDict setObject:CONTACT_STATUS_ONLINE_YES forKey:@"EventID"];
		[alertDict setObject:@"SendMessage" forKey:@"ActionID"];
		[alertDict setObject:[NSNumber numberWithBool:YES] forKey:@"OneTime"]; 
		
		[[adium contactAlertsController] addAlert:alertDict 
									 toListObject:[[adium contactController] parentContactForListObject:listObject]];
		
		[self didSendMessage:nil];
	}
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
        [tableView_userList reloadData];
    }
}

//Our chat's account changed, re-show the from selector
- (void)chatAccountChanged:(NSNotification *)notification
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

//Arrange and resize our subviews based on the current state of this view (whether or not: it's locked to a contact, the account view is visible)
- (void)sizeAndArrangeSubviews
{
    float	textHeight;
    int		height;
    NSRect	superFrame = [view_contents frame];

	
    superFrame.origin.y = 0;
    superFrame.origin.x = 0;

    //Account
    if(view_accountSelection){
        height = [view_accountSelection frame].size.height;

        [view_accountSelection setFrame:NSMakeRect(0, superFrame.size.height - height, superFrame.size.width, height)];
        superFrame.size.height -= height;
    }

    //Text entry
	float	entryMaxHeight = [view_contents frame].size.height * ENTRY_TEXTVIEW_MAX_HEIGHT_PERCENT;
    textHeight = [textView_outgoing desiredSize].height;
    if(textHeight > entryMaxHeight){
        textHeight = entryMaxHeight;
    }else if(textHeight < ENTRY_TEXTVIEW_MIN_HEIGHT){
        textHeight = ENTRY_TEXTVIEW_MIN_HEIGHT;
    }
	
    [scrollView_outgoingView setHasVerticalScroller:(textHeight == entryMaxHeight)];
    [scrollView_outgoingView setFrame:NSMakeRect(superFrame.origin.x - 1, superFrame.origin.y, superFrame.size.width + 2, textHeight)];
    superFrame.size.height -= textHeight + TEXT_ENTRY_PADDING;
    superFrame.origin.y += textHeight + TEXT_ENTRY_PADDING;

	//Split View (contains UserList and Messages)
    [splitView_messages setFrame:superFrame];
	
    //UserList
    if(showUserList){
		if( ![[splitView_messages subviews] containsObject:scrollView_userList] ) {
			[splitView_messages addSubview:scrollView_userList];
			
			NSRect splitFrame = [splitView_messages frame];
			//NSRect buttonFrame = [button_inviteUser frame];
			[controllerView_messages setFrame:NSMakeRect(0,0,NSWidth(splitFrame)-USER_LIST_WIDTH-[splitView_messages dividerThickness],NSHeight(splitFrame))];
			[scrollView_userList setFrame:NSMakeRect(NSWidth(splitFrame)-USER_LIST_WIDTH,0,USER_LIST_WIDTH,NSHeight(splitFrame))];
			
			//NSRect userFrame = [view_userPane frame];
			//[scrollView_userList setFrame:NSMakeRect(0,0,NSWidth(userFrame),NSHeight(userFrame))];
			//[button_inviteUser setFrame:NSMakeRect(0,0,25,25)];
		}
    }else{		
		if( [[splitView_messages subviews] containsObject:scrollView_userList] ) {
			[scrollView_userList removeFromSuperview];
		}
	
    }
	
	/*
	 if(showUserList){
		 if( ![[splitView_messages subviews] containsObject:scrollView_userList] ) {
			 [splitView_messages addSubview:scrollView_userList];
			 [splitView_messages addSubview:button_inviteUser];
			 NSRect splitFrame = [splitView_messages frame];
			 NSRect buttonFrame = [button_inviteUser frame];
			 [controllerView_messages setFrame:NSMakeRect(0,0,NSWidth(splitFrame)-USER_LIST_WIDTH-[splitView_messages dividerThickness],NSHeight(splitFrame)-NSHeight(buttonFrame))];
			 [scrollView_userList setFrame:NSMakeRect(NSWidth(splitFrame)-USER_LIST_WIDTH,NSHeight(buttonFrame),USER_LIST_WIDTH,NSHeight(splitFrame))];
			 [button_inviteUser setFrameOrigin:NSMakePoint(NSWidth(splitFrame)-USER_LIST_WIDTH,0)];
		 }
	 }else{
		 if( [[splitView_messages subviews] containsObject:scrollView_userList] ) {
			 [scrollView_userList removeFromSuperview];
			 [button_inviteUser removeFromSuperview];
		 }
		 
	 }
	 */	 
	
    //Messages
	[splitView_messages displayIfNeeded];

}

#pragma mark Table View
//User List
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([[chat participatingListObjects] count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	
	AIListObject *listObject = [[chat participatingListObjects] objectAtIndex:row];
	
	// Identifier 0: status image column. 1: name
	if( [(NSNumber *)[tableColumn identifier] intValue] == 0 ) {
		return [[listObject displayArrayForKey:@"Tab Icon"] objectValue];
	} else {
		return([listObject displayName]);
	}
	
	//return nil;
}

// Allow selection of a contact, prepare info on them
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{	
	return YES;
}

// Cell was single-clicked
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int selectedIndex = [tableView_userList selectedRow];
	[chat setPreferredListObject:((selectedIndex != -1) ? 
								  [[chat participatingListObjects] objectAtIndex:selectedIndex] :
								  nil)];
}

- (void)cellWasDoubleClicked:(id)sender
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

- (void)listObjectChanged:(NSNotification *)notification
{
	[tableView_userList reloadData];
}

- (void)chatParticipantsChanged:(NSNotification *)notification
{
	if( [notification object] == chat )
		[tableView_userList reloadData];
}

#pragma mark Split View Delegate

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	if( subview == tableView_userList || subview == scrollView_userList )
		return YES;
	else
		return NO;
}

    
@end

