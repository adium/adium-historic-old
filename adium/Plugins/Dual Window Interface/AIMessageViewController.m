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

#define KEY_MESSAGE_SPELL_CHECKING	@"Message"

#define MESSAGE_VIEW_NIB		@"MessageView"		//Filename of the message view nib
#define MESSAGE_TAB_TOOLBAR		@"MessageTab"		//ID of the message tab toolbar
#define ENTRY_TEXTVIEW_MAX_HEIGHT	70
#define ENTRY_TEXTVIEW_PADDING		3
#define RESIZE_CORNER_TOOLBAR_OFFSET 	0

@interface AIMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat owner:(id)inOwner;
- (void)dealloc;
- (void)textDidChange:(NSNotification *)notification;
- (void)sizeAndArrangeSubviews;
- (void)preferencesChanged:(NSNotification *)notification;
- (float)textHeight;
- (void)clearTextEntryView;
- (void)setChat:(AIChat *)inChat;
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

//Return the destination object of this message
- (AIListObject *)listObject{
    return(object);
}

//For our account selector view
- (AIListContact *)contact
{
    if([object isKindOfClass:[AIListContact class]]){ //Account selector is only valid for contacts
        return((AIListContact *)object);
    }else{
        return(nil);
    }
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
                                      destination:object
                                             date:nil
                                          message:[[[textView_outgoing attributedString] copy] autorelease]];

        
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
    if([object isKindOfClass:[AIListContact class]]){ //Don't let them do this if the object isn't a contact
        if(account != inAccount){
            NSArray	*existingContent = [[chat contentObjectArray] retain];

            //Set the account
            [account release]; account = nil;
            account = [inAccount retain];

            //Reconfigure our view for the new chat
            [self setChat:[[owner contentController] chatWithListObject:object onAccount:account]];
            //[chat appendContentArray:existingContent];
            //If I decide to go this route, care must be taken to:
            // - "Reload data" the message view
            // - Convert all content objects to the new chat
        }
    }
}

//Set the chat represented by this view
- (void)setChat:(AIChat *)inChat
{
    if(inChat != chat){
        //Close our existing chat, and hold onto the new one
        if(chat){
            [[owner contentController] closeChat:chat];
            [chat release]; chat = nil;
        }
        chat = [inChat retain];
    
        //Get our new account and contact
        [account release]; account = [[inChat account] retain];
        [object release]; object = [[inChat object] retain];

        //Config the outgoing text view
        [textView_outgoing setChat:chat];
//        [textView_outgoing setListObject:object];
//        [textView_outgoing setAccount:account];
    
        //Config our toolbar
        [toolbar_bottom setIdentifier:MESSAGE_TAB_TOOLBAR];
        [toolbar_bottom configureForObjects:[NSDictionary dictionaryWithObjectsAndKeys:inChat, @"Chat", object, @"ContactObject", textView_outgoing, @"TextEntryView", nil]];
    
        //Register for sending notifications
        [[owner notificationCenter] removeObserver:self name:Interface_SendEnteredMessage object:nil];
        [[owner notificationCenter] removeObserver:self name:Interface_DidSendEnteredMessage object:nil];
        [[owner notificationCenter] addObserver:self selector:@selector(sendMessage:) name:Interface_SendEnteredMessage object:inChat];
        [[owner notificationCenter] addObserver:self selector:@selector(didSendMessage:) name:Interface_DidSendEnteredMessage object:inChat];

        //Create the message view
        [view_messages release];
        view_messages = [[owner interfaceController] messageViewForChat:chat];
        [scrollView_messages setAndSizeDocumentView:view_messages];
        [scrollView_messages setNextResponder:textView_outgoing];
        [scrollView_messages setAutoScrollToBottom:YES];
        [scrollView_messages setAutoHideScrollBar:NO];
        [scrollView_messages setHasVerticalScroller:YES];

    }
}

//Toggle the visibility of our account selection menu
- (void)setAccountSelectionMenuVisible:(BOOL)visible
{
    if(visible && !view_accountSelection){ //Show the account selection view
        view_accountSelection = [[AIAccountSelectionView alloc] initWithFrame:NSMakeRect(0,0,100,100) delegate:self owner:owner];
        [view_contents addSubview:view_accountSelection];

    }else if(!visible && view_accountSelection){ //Hide the account selection view
        [view_accountSelection removeFromSuperview];
        [view_accountSelection release]; view_accountSelection = nil;
    }

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
    view_messages = nil;
    account = nil;
    object = nil;
    chat = nil;
    owner = [inOwner retain];

    //view
    [NSBundle loadNibNamed:MESSAGE_VIEW_NIB owner:self];

    //Configure for our chat
    [self setChat:inChat];

    //Config the outgoing text view
    [textView_outgoing setOwner:owner];
    [textView_outgoing setTarget:self action:@selector(sendMessage:)];

    //Resize and arrange our views
    [self sizeAndArrangeSubviews];

    //Register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sizeAndArrangeSubviews) name:NSViewFrameDidChangeNotification object:view_contents];
    [[owner notificationCenter] addObserver:self selector:@selector(listObjectStatusChanged:) name:ListObject_StatusChanged object:object];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
    
    return(self);
}

- (void)closeMessageView
{
    //Save spellcheck state
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[textView_outgoing isContinuousSpellCheckingEnabled]] forKey:KEY_MESSAGE_SPELL_CHECKING group:PREF_GROUP_SPELLING];

    //Clear the message entry text view
    [self clearTextEntryView];

    //Close our chat
    if(chat){
        [[owner contentController] closeChat:chat];
        [chat release]; chat = nil;
    }
}

- (void)dealloc
{
    //remove notifications
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    //nib
    [view_contents removeAllSubviews];
    [view_contents release]; view_contents = nil;

    [owner release]; owner = nil;
    [interface release]; interface = nil;
    [account release]; account = nil;
    [object release]; object = nil;

    [super dealloc];
}

//Our contact's status did change
- (void)listObjectStatusChanged:(NSNotification *)notification
{    
    //Enable/Disable our text view sending
    [textView_outgoing setAvailableForSending:[[owner contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toChat:chat onAccount:account]];

    //Update our toolbar
    [toolbar_bottom configureForObjects:nil];
}

//A preference did change
- (void)preferencesChanged:(NSNotification *)notification
{
    //Configure the message sending keys
    [textView_outgoing setSendOnEnter:[[[owner preferenceController] preferenceForKey:@"Send On Enter" group:PREF_GROUP_GENERAL object:object] boolValue]];
    [textView_outgoing setSendOnReturn:[[[owner preferenceController] preferenceForKey:@"Send On Return" group:PREF_GROUP_GENERAL object:object] boolValue]];

    //Configure spellchecking
    [textView_outgoing setContinuousSpellCheckingEnabled:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_MESSAGE_SPELL_CHECKING] boolValue]];
}

//The entered text has changed
- (void)textDidChange:(NSNotification *)notification
{
    if([self textHeight] != currentTextEntryHeight){
        [self sizeAndArrangeSubviews]; //Resize our contents to fit the text (If it's height has changed)
    }
}

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

    //Toolbar
    height = [toolbar_bottom frame].size.height;
    [toolbar_bottom setFrame:NSMakeRect(0, 0, superFrame.size.width - RESIZE_CORNER_TOOLBAR_OFFSET, height)];
    superFrame.size.height -= height;
    superFrame.origin.y += height;

    //Text entry
    currentTextEntryHeight = [self textHeight];
    [scrollView_outgoingView setHasVerticalScroller:(currentTextEntryHeight == ENTRY_TEXTVIEW_MAX_HEIGHT)];
    [scrollView_outgoingView setFrame:NSMakeRect(-1, superFrame.origin.y, superFrame.size.width + 2, currentTextEntryHeight)];
    superFrame.size.height -= currentTextEntryHeight;
    superFrame.origin.y += currentTextEntryHeight;

    //Messages
    [scrollView_messages setFrame:NSMakeRect(-1, superFrame.origin.y, superFrame.size.width + 2, superFrame.size.height + 1)];
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
    }

    return(textHeight);
}



@end


