/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIAccountSelectionView.h"

#define MESSAGE_VIEW_NIB		@"MessageView"		//Filename of the message view nib
#define MESSAGE_TAB_TOOLBAR		@"MessageTab"		//ID of the message tab toolbar
#define ENTRY_TEXTVIEW_MIN_HEIGHT	20
#define ENTRY_TEXTVIEW_MAX_HEIGHT	70
#define ENTRY_TEXTVIEW_PADDING		3
#define RESIZE_CORNER_TOOLBAR_OFFSET 	0

@interface AIMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat owner:(id)inOwner;
- (void)dealloc;
- (void)textDidChange:(NSNotification *)notification;
- (void)sizeAndArrangeSubviews;
- (float)textHeight;
- (void)clearTextEntryView;
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification;
- (void)listObjectStatusChanged:(NSNotification *)notification;
- (void)chatStatusChanged:(NSNotification *)notification;
@end

@implementation AIMessageViewController

//Create a new message view controller
+ (AIMessageViewController *)messageViewControllerForChat:(AIChat *)inChat owner:(id)inOwner
{
    return([[[self alloc] initForChat:inChat owner:inOwner] autorelease]);
}

//Return our view
- (NSView *)view{
    return(view_contents);
}

//Return the chat associated with this message
- (AIChat *)chat{
    return(chat);
}

//For our account selector view
- (AIListObject *)listObject
{
    return([chat listObject]);
}

//The source account of this message
- (AIAccount *)account{
    return(account);
}

//Send the entered message
- (IBAction)sendMessage:(id)sender
{
    if([[textView_outgoing attributedString] length] != 0){ //If message length is 0, don't send
        AIContentMessage	*message;

        //Send the message
        [[owner notificationCenter] postNotificationName:Interface_WillSendEnteredMessage object:chat userInfo:nil];

        message = [AIContentMessage messageInChat:chat
                                       withSource:account
                                      destination:nil
                                             date:nil
                                          message:[[[textView_outgoing attributedString] copy] autorelease]
                                        autorelpy:NO];

        
        if([[owner contentController] sendContentObject:message]){
            [[owner notificationCenter] postNotificationName:Interface_DidSendEnteredMessage object:chat userInfo:nil];
        }
    }
}

//The entered message was sent
- (IBAction)didSendMessage:(id)sender
{
    [self setAccountSelectionMenuVisible:NO]; //Hide the account selection menu
    [self clearTextEntryView]; //Clear the message entry text view
}

//Set the sounce account of this message
- (void)setAccount:(AIAccount *)inAccount
{
    //Initiate a new chat with the specified account.  The interface will automatically recycle this message view, switching it to the new account.
    [[owner contentController] openChatOnAccount:inAccount withListObject:[chat listObject]];
}

//Set the chat represented by this view
- (void)setChat:(AIChat *)inChat
{
    if(inChat != chat){
        NSArray	*savedContent = nil;

        if(chat){
            NSEnumerator	*enumerator;
            AIContentObject	*contentObject;
            
            //Extract the content from our existing chat
            savedContent = [[[chat contentObjectArray] retain] autorelease];

            //Convert the content to our new chat
            enumerator = [savedContent objectEnumerator];
            while(contentObject = [enumerator nextObject]){
                [contentObject setChat:inChat];
            }
            
            //Close our existing chat
            [[owner contentController] closeChat:chat];
            [chat release]; chat = nil;
        }

        //Hold onto the new chat
        chat = [inChat retain];

        //Transfer over the content from our old chat
        if(savedContent){
            [chat setContentArray:savedContent];
        }
    
        //Get our new account
        [account release]; account = [[inChat account] retain];
        //Config the outgoing text view
        [textView_outgoing setChat:chat];
    
        //Register for sending notifications
        [[owner notificationCenter] removeObserver:self name:Interface_SendEnteredMessage object:nil];
        [[owner notificationCenter] removeObserver:self name:Interface_DidSendEnteredMessage object:nil];
        [[owner notificationCenter] addObserver:self selector:@selector(sendMessage:) name:Interface_SendEnteredMessage object:inChat];
        [[owner notificationCenter] addObserver:self selector:@selector(didSendMessage:) name:Interface_DidSendEnteredMessage object:inChat];

        //Create the message view
        [messageViewController release];
        messageViewController = [[[owner interfaceController] messageViewControllerForChat:chat] retain];
        [scrollView_messages setAndSizeDocumentView:[messageViewController messageView]];
        [scrollView_messages setNextResponder:textView_outgoing];
        [scrollView_messages setAutoScrollToBottom:YES];
        [scrollView_messages setAutoHideScrollBar:NO];
        [scrollView_messages setHasVerticalScroller:YES];

        //
        [scrollView_userList setAutoScrollToBottom:NO];
        [scrollView_userList setAutoHideScrollBar:YES];
        
        //Observe the chat
        [[owner notificationCenter] removeObserver:self name:Content_ChatStatusChanged object:nil];
        [[owner notificationCenter] addObserver:self selector:@selector(chatStatusChanged:) name:Content_ChatStatusChanged object:chat];
        [self chatStatusChanged:nil];
        
        //Update our participating list objects list
        [[owner notificationCenter] removeObserver:self name:Content_ChatParticipatingListObjectsChanged object:nil];
        [[owner notificationCenter] addObserver:self selector:@selector(chatParticipatingListObjectsChanged:) name:Content_ChatParticipatingListObjectsChanged object:chat];
        [self chatParticipatingListObjectsChanged:nil];

        //Notify our delegate of the change
        [delegate messageViewController:self chatChangedTo:inChat];
    }
}

//Toggle the visibility of our account selection menu
- (void)setAccountSelectionMenuVisible:(BOOL)visible
{
    //
    if(visible && !view_accountSelection){ //Show the account selection view
        view_accountSelection = [[AIAccountSelectionView alloc] initWithFrame:NSMakeRect(0,0,100,100) delegate:self owner:owner];
        [view_contents addSubview:view_accountSelection];

    }else if(!visible && view_accountSelection){ //Hide the account selection view
        [view_accountSelection removeFromSuperview];
        [view_accountSelection release]; view_accountSelection = nil;
    }

    //Update the selected account
    [view_accountSelection updateMenu];

    //
    [self sizeAndArrangeSubviews];
}

//Sets our text entry view as the first responder
- (void)makeTextEntryViewFirstResponder
{
    [[textView_outgoing window] makeFirstResponder:textView_outgoing];
}

//Clear the message entry text view and force a textDidChange: notification
- (void)clearTextEntryView
{
    [textView_outgoing setString:@""];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView_outgoing];
}


//Private -----------------------------------------------------------------------------
//Init
- (id)initForChat:(AIChat *)inChat owner:(id)inOwner
{
    [super init];

    //
    currentTextEntryHeight = 0;
    view_accountSelection = nil;
    account = nil;
    delegate = nil;
    chat = nil;
    owner = [inOwner retain];
    showUserList = NO;

    //view
    [NSBundle loadNibNamed:MESSAGE_VIEW_NIB owner:self];

    //Configure for our chat
    [self setChat:inChat];

    //
    [button_send setTitle:@"Send"];
    [button_send setButtonType:NSMomentaryPushInButton];

    //Config the outgoing text view
    [textView_outgoing setOwner:owner];
    [textView_outgoing setTarget:self action:@selector(sendMessage:)];
    [textView_outgoing setTextContainerInset:NSMakeSize(0,2)];
    [[owner contentController] didOpenTextEntryView:textView_outgoing];

    //Resize and arrange our views
    [self sizeAndArrangeSubviews];

    //Register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sizeAndArrangeSubviews) name:NSViewFrameDidChangeNotification object:view_contents];
    
    return(self);
}

- (void)closeMessageView
{
    //Clear and close the message entry text view
    [self clearTextEntryView];
    [[owner contentController] willCloseTextEntryView:textView_outgoing];

    //Close our chat
    if(chat){
        [[owner contentController] closeChat:chat];
        [chat release]; chat = nil;
    }
}

- (void)dealloc
{    
    //Close chat
    if(chat){
        [[owner contentController] closeChat:chat];
        [chat release]; chat = nil;
    }

    //remove notifications
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    //Account selection view
    if(view_accountSelection){
        [view_accountSelection removeFromSuperview];
        [view_accountSelection release]; view_accountSelection = nil;
    }

    //nib
    [view_contents removeAllSubviews];
    [view_contents release]; view_contents = nil;
    [view_accountSelection release];
    [messageViewController release];
    [owner release]; owner = nil;
    [interface release]; interface = nil;
    [account release]; account = nil;

    [super dealloc];
}

//
- (void)setDelegate:(id)inDelegate
{
    delegate = inDelegate;
}

//Our chat's participating list objects did change
- (void)chatParticipatingListObjectsChanged:(NSNotification *)notification
{
    NSArray	*participatingListObjects = [chat participatingListObjects];
    BOOL	listVisible;
    
    //We display the user list if it contains more than one user, or if someone has specified that it be visible.
    if([[[chat statusDictionary] objectForKey:@"AlwaysShowUserList"] boolValue] ||
       [participatingListObjects count] > 1){
        listVisible = YES;
    }else{
        listVisible = NO;
    }

    //Show/hide the userlist
    if(listVisible != showUserList){
        showUserList = listVisible;
        [self sizeAndArrangeSubviews];
    }

    //Update the user list
    if(showUserList){
        [tableView_userList reloadData];
    }
}

//Our chat's status did change
- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*modifiedKeys = [[notification userInfo] objectForKey:@"Keys"];

    if(notification == nil || [modifiedKeys containsObject:@"Enabled"]){
        //Update our available for sending
        availableForSending = [[[chat statusDictionary] objectForKey:@"Enabled"] boolValue];

        //Enable/Disable our text view sending, and send button
        [textView_outgoing setAvailableForSending:availableForSending];
        [button_send setEnabled:(availableForSending && [[textView_outgoing string] length] != 0)];
    }

    if(notification == nil || [modifiedKeys containsObject:@"DisallowAccountSwitching"]){
        BOOL disallowAccountChanging = [[[chat statusDictionary] objectForKey:@"DisallowAccountSwitching"] boolValue];

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
    
    //Resize our contents to fit the text (If it's height has changed)
    if([self textHeight] != currentTextEntryHeight){
        [self sizeAndArrangeSubviews];
        [view_contents setNeedsDisplay:YES];
    }

    //Enable/Disable our sending button
    enabled = (availableForSending && [[textView_outgoing string] length] != 0);
    if([button_send isEnabled] != enabled){
        [button_send setEnabled:enabled];
    }
    
}

#define TEXT_ENTRY_PADDING 2
#define SEND_BUTTON_PADDING 2
//Arrange and resize our subviews based on the current state of this view (whether or not: it's locked to a contact, the account view is visible)
- (void)sizeAndArrangeSubviews
{
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

    //Send Button
    int buttonWidth = [button_send frame].size.width;
    [button_send setFrame:NSMakeRect(superFrame.origin.x + superFrame.size.width - buttonWidth,
                                     superFrame.origin.y - 1,
                                     [button_send frame].size.width,
                                     [button_send frame].size.height)];
    
    //Text entry
    currentTextEntryHeight = [self textHeight];
    [scrollView_outgoingView setHasVerticalScroller:(currentTextEntryHeight == ENTRY_TEXTVIEW_MAX_HEIGHT)];
    [scrollView_outgoingView setFrame:NSMakeRect(0, superFrame.origin.y, superFrame.size.width - (buttonWidth + SEND_BUTTON_PADDING), currentTextEntryHeight)];
    superFrame.size.height -= currentTextEntryHeight + TEXT_ENTRY_PADDING;
    superFrame.origin.y += currentTextEntryHeight + TEXT_ENTRY_PADDING;

    //UserList
    if(showUserList){
#define fixed_width 100
#define fixed_padding 4
        [scrollView_userList setFrame:NSMakeRect(superFrame.size.width - fixed_width, superFrame.origin.y, fixed_width - 1, superFrame.size.height)];

        superFrame.size.width -= fixed_width + fixed_padding;
    }else{
        [scrollView_userList setFrame:NSMakeRect(10000, 10000, 0, 0)]; //Shove it way off screen for now
    }
    
    //Messages
    [scrollView_messages setFrame:NSMakeRect(0, superFrame.origin.y, superFrame.size.width, superFrame.size.height)];
}

- (float)textHeight
{
    float 		textHeight;

    //When the view is empty, usedRectForTextContainer will return an incorrect height, so we calculate it manually using the typing attributes    
    if([[textView_outgoing textStorage] length] == 0){
        NSAttributedString	*attrString;

        //Manually determine the font's height
        attrString = [[[NSAttributedString alloc] initWithString:@" AbcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" attributes:[textView_outgoing typingAttributes]] autorelease];
        textHeight = [attrString heightWithWidth:10000] + ENTRY_TEXTVIEW_PADDING; //Arbitrarily large number
        
    }else{
        //Let the container tell us its height
        textHeight = [[textView_outgoing layoutManager] usedRectForTextContainer:[textView_outgoing textContainer]].size.height + ENTRY_TEXTVIEW_PADDING;

    }
    
    if(textHeight > ENTRY_TEXTVIEW_MAX_HEIGHT){
        textHeight = ENTRY_TEXTVIEW_MAX_HEIGHT;
    }else if(textHeight < ENTRY_TEXTVIEW_MIN_HEIGHT){
        textHeight = ENTRY_TEXTVIEW_MIN_HEIGHT;
    }

    return(textHeight);
}

//User List
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([[chat participatingListObjects] count]);
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    return([[[chat participatingListObjects] objectAtIndex:row] displayName]);
}


@end

