/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define KEY_MESSAGE_SPELL_CHECKING	@"Message"

#define MESSAGE_VIEW_NIB		@"MessageView"		//Filename of the message view nib
#define MESSAGE_TAB_TOOLBAR		@"MessageTab"		//ID of the message tab toolbar
#define ACCOUNTS_VIEW_HEIGHT		27
#define TOOLBAR_VIEW_HEIGHT		20
#define ENTRY_TEXTVIEW_MAX_HEIGHT	70
#define ENTRY_TEXTVIEW_PADDING		3
#define RESIZE_CORNER_TOOLBAR_OFFSET 	0

@interface AIMessageViewController (PRIVATE)
- (id)initWithOwner:(id)inOwner handle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent interface:(id <AITabHoldingInterface>)inInterface;
- (void)lockToHandle:(AIContactHandle *)inHandle;
- (void)sizeAndArrangeSubviews;
- (IBAction)selectNewAccount:(id)sender;
- (void)configureAccountMenu;
@end

@implementation AIMessageViewController

//Create a new message view controller
+ (AIMessageViewController *)messageViewControllerWithHandle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent owner:(id)inOwner interface:(id <AITabHoldingInterface>)inInterface
{
    return([[[self alloc] initWithOwner:inOwner handle:inHandle account:inAccount content:inContent interface:inInterface] autorelease]);
}

//Send the entered message
- (IBAction)sendMessage:(id)sender
{
    if([[textView_outgoing attributedString] length] != 0){ //If message length is 0, don't send
        AIContentMessage	*message;

        //Lock this view to the specified handle (if it wasn't already locked to one)
        if(!handle){ 
            AIServiceType 	*serviceType = [[account service] handleServiceType];
            AIContactHandle	*newHandle;
        
            //Find the specified handle, and lock it
            newHandle = [[owner contactController] handleWithService:serviceType UID:[textField_handle stringValue] forAccount:account];
            [self lockToHandle:newHandle];
        }
    
        //Hide our 'from' account selector menu
        if(accountMenuVisible){
            [self setAccountMenuVisible:NO];
        }
        
        //Send the message
        [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:Interface_WillSendEnteredMessage object:handle userInfo:nil];
        message = [AIContentMessage messageWithSource:account destination:handle date:nil message:[[[textView_outgoing attributedString] copy] autorelease]];
        [[owner contentController] sendContentObject:message toHandle:handle];
        [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:Interface_DidSendEnteredMessage object:handle userInfo:nil];
    
        //Clear the message entry text view
        [textView_outgoing setString:@""];
        [self textDidChange:nil]; //force the view to resize
        
    }
}

- (IBAction)cancel:(id)sender
{
    [interface closeMessageViewController:self];
}

//Return the handle associated with this view
- (AIContactHandle *)handle
{
    return(handle);
}

//Return a title for our tab
- (NSAttributedString *)title
{
    return([[[NSAttributedString alloc] initWithString:@"Message"] autorelease]);
}

//Return our view
- (NSView *)view
{
    return(view_contents);
}

//Set keyboard focus on the enter view
- (IBAction)setFocusOnEnterView:(id)sender
{
    [[textView_outgoing window] makeFirstResponder:textView_outgoing];
}

//Set the visibility of the account menu
- (void)setAccountMenuVisible:(BOOL)visible
{
    accountMenuVisible = visible;
    [self sizeAndArrangeSubviews];
}


//Private -----------------------------------------------------------------------------
- (id)initWithOwner:(id)inOwner handle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent interface:(id <AITabHoldingInterface>)inInterface
{
    [super init];

    //
    scrollView_messages = nil;
    view_messages = nil;
    toolbar_bottom = nil;
    accountMenuVisible = YES;

    //
    owner = [inOwner retain];
    interface = [inInterface retain];
    account = [inAccount retain];
    if(!account) account = [[[owner accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toHandle:inHandle] retain];

    [NSBundle loadNibNamed:MESSAGE_VIEW_NIB owner:self];

    if(!inHandle){ //If a handle is specified, we can skip these steps, since these views will be removed
        AIContactController	*contactController = [owner contactController];
        NSEnumerator		*enumerator;
        AIContactHandle		*object;
        
        //Configure the sending text view
        [textView_outgoing setTarget:self action:@selector(sendMessage:)];
        [textView_outgoing setSendOnReturn:[[[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL ] boolForKey:@"message_send_onReturn"]];
        [textView_outgoing setSendOnEnter:[[[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL ] boolForKey:@"message_send_onEnter"]];
    
        //Configure the auto-complete view
        [textField_handle setFont:[NSFont systemFontOfSize:11]];
        enumerator = [[contactController allContactsInGroup:nil subgroups:YES ownedBy:nil] objectEnumerator];
        while((object = [enumerator nextObject])){
            [textField_handle addCompletionString:[object UID]];
        }

        [self configureAccountMenu];

    }else{ //When a handle is specified we can also lock the view to that handle now
        [self lockToHandle:inHandle];
    }
    
    //Put the initial content in the outgoing text view, and give it focus
    [textView_outgoing setAttributedString:inContent];
    [[textView_outgoing window] makeFirstResponder:textView_outgoing];

    //Restore spellcheck state
    [textView_outgoing setContinuousSpellCheckingEnabled:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_MESSAGE_SPELL_CHECKING] boolValue]];

    //Configure the rest of the view
    [[popUp_accounts menu] setAutoenablesItems:NO];
    [view_account setColor:[NSColor whiteColor]];
    [view_handle setColor:[NSColor whiteColor]];
    [view_buttons setColor:[NSColor whiteColor]];

    //register for notifications
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_PropertiesChanged object:nil];
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_StatusChanged object:nil];
    

    return(self);
}

- (void)dealloc
{
    //Save spellcheck state
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[textView_outgoing isContinuousSpellCheckingEnabled]] forKey:KEY_MESSAGE_SPELL_CHECKING group:PREF_GROUP_SPELLING];
    
    //remove notifications
    [[[owner interfaceController] interfaceNotificationCenter] removeObserver:self];
    [[[owner accountController] accountNotificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    //nib
    [view_contents removeAllSubviews];
    [view_contents release]; view_contents = nil;

    [owner release]; owner = nil;
    [interface release]; interface = nil;
    [account release]; account = nil;
    [handle release]; handle = nil;


    [super dealloc];
}

//Lock this view to a handle
- (void)lockToHandle:(AIContactHandle *)inHandle
{
    NSParameterAssert(handle == nil); //The account selector can be toggled at will, but once a handle is set - it CANNOT be removed.

    handle = [inHandle retain];

    //Remove the views that are no longer needed
    [view_handle removeFromSuperview]; view_handle = nil;
    [view_buttons removeFromSuperview]; view_buttons = nil;
    [textField_handle removeFromSuperview]; textField_handle = nil;

    //Create any new views we need
        //Create the message scroll view
        scrollView_messages = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,100,100)]; //Size is arbitrary
        [scrollView_messages setHasVerticalScroller:YES];
        [scrollView_messages setHasHorizontalScroller:NO];
        [scrollView_messages setBorderType:NSBezelBorder];
        [scrollView_messages setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [view_contents addSubview:[scrollView_messages autorelease]];

        //Create the message view to go inside it
        view_messages = [[owner interfaceController] messageViewForHandle:handle];
        [scrollView_messages setAndSizeDocumentView:view_messages];
    
        //Create the toolbar
        toolbar_bottom = [[AIMiniToolbar alloc] initWithFrame:NSMakeRect(0,0,100,100)]; //Size is arbitrary
        [toolbar_bottom setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
        [view_contents addSubview:[toolbar_bottom autorelease]];

        //Create the outgoing text view
        [textView_outgoing setAutoresizingMask:(NSViewWidthSizable)];
        [textView_outgoing setDelegate:self];
        [textView_outgoing setOwner:owner];
        [textView_outgoing setSendOnEnter:[[[owner preferenceController] preferenceForKey:@"message_send_onEnter" group:PREF_GROUP_GENERAL object:handle] boolValue]];
        [textView_outgoing setSendOnReturn:[[[owner preferenceController] preferenceForKey:@"message_send_onReturn" group:PREF_GROUP_GENERAL object:handle] boolValue]];
        [textView_outgoing setTarget:self action:@selector(sendMessage:)];
        [[textView_outgoing window] makeFirstResponder:textView_outgoing];

        //Configure the outgoing scroll view
        [scrollView_outgoingView setHasVerticalScroller:NO];
        [scrollView_outgoingView setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
    
        //Configure the toolbar
        [toolbar_bottom setIdentifier:MESSAGE_TAB_TOOLBAR];
        [toolbar_bottom configureForObjects:[NSDictionary dictionaryWithObjectsAndKeys:inHandle,@"ContactObject",textView_outgoing,@"TextEntryView",nil]];

    //Give the entry view focus
//    [[textView_outgoing window] makeFirstResponder:textView_outgoing];

    //Register for notifications
    [[[owner interfaceController] interfaceNotificationCenter] addObserver:self selector:@selector(sendMessage:) name:Interface_SendEnteredMessage object:handle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSViewFrameDidChangeNotification object:view_contents];


    //resize and reconfigure
    [self sizeAndArrangeSubviews];
    [self configureAccountMenu];
}

//The entered text has changed
- (void)textDidChange:(NSNotification *)notification
{
    //Resize our contents to fix the text
    [self sizeAndArrangeSubviews];
}

//The account list/status changed
- (void)accountListChanged:(NSNotification *)notification
{
    [self configureAccountMenu]; //rebuild the account menu
}

//Arrange and resize our subviews based on the current state of this view (whether or not: it's locked to a handle, the account view is visible)
- (void)sizeAndArrangeSubviews
{
    NSRect	superFrame = [view_contents frame];
    NSRect	frame;

    superFrame.origin.y = 0;
    superFrame.origin.x = 0;

    if(!handle){
        //Account
        frame = [view_account frame];
        if(accountMenuVisible){
            NSSize	oldSize = [view_account frame].size;
        
            [view_account setFrame:NSMakeRect(0, superFrame.size.height - ACCOUNTS_VIEW_HEIGHT, superFrame.size.width, ACCOUNTS_VIEW_HEIGHT)];
            [view_account resizeSubviewsWithOldSize:oldSize];

            superFrame.size.height -= ACCOUNTS_VIEW_HEIGHT;
        }else{
            [view_account setFrameOrigin:NSMakePoint(5000,0)]; //hide the view by moving it out of the window
        }

        //Handle
        frame = [view_handle frame];
        [view_handle setFrame:NSMakeRect(0, superFrame.size.height - frame.size.height, superFrame.size.width, frame.size.height)];
        superFrame.size.height -= frame.size.height;
        
        //Buttons
        frame = [view_buttons frame];
        [view_buttons setFrame:NSMakeRect(0, 0, superFrame.size.width, frame.size.height)];
        superFrame.size.height -= frame.size.height;
        superFrame.origin.y += frame.size.height;
        
        //Text entry
        [scrollView_outgoingView setFrame:NSMakeRect(0, superFrame.origin.y, superFrame.size.width, superFrame.size.height)];
    }else{
        //Account
        frame = [view_account frame];
        if(accountMenuVisible){
            [view_account setFrame:NSMakeRect(0, superFrame.size.height - ACCOUNTS_VIEW_HEIGHT, superFrame.size.width, ACCOUNTS_VIEW_HEIGHT)];
            superFrame.size.height -= ACCOUNTS_VIEW_HEIGHT;
        }else{
            [view_account setFrame:NSMakeRect(0,0,0,0)];
        }

        //Toolbar
        [toolbar_bottom setFrame:NSMakeRect(0, 0, superFrame.size.width - RESIZE_CORNER_TOOLBAR_OFFSET, TOOLBAR_VIEW_HEIGHT)];
        superFrame.size.height -= TOOLBAR_VIEW_HEIGHT;
        superFrame.origin.y += TOOLBAR_VIEW_HEIGHT;

        //Text entry
        {
            float textHeight = [[textView_outgoing layoutManager] usedRectForTextContainer:[textView_outgoing textContainer]].size.height + ENTRY_TEXTVIEW_PADDING;
    
            if(textHeight > ENTRY_TEXTVIEW_MAX_HEIGHT){
                textHeight = ENTRY_TEXTVIEW_MAX_HEIGHT;
                [scrollView_outgoingView setHasVerticalScroller:YES];
            }else{
                [scrollView_outgoingView setHasVerticalScroller:NO];
            }

            [scrollView_outgoingView setFrame:NSMakeRect(-1, superFrame.origin.y, superFrame.size.width + 2, textHeight)];
            superFrame.size.height -= textHeight;
            superFrame.origin.y += textHeight;
        }
        
        //Messages
        [scrollView_messages setFrame:NSMakeRect(-1, superFrame.origin.y, superFrame.size.width + 2, superFrame.size.height + 1)];
    }    
}

//User selected a new account from the account menu
- (IBAction)selectNewAccount:(id)sender
{
    [account release];
    account = [[[sender selectedItem] representedObject] retain];
}

//Configures the account menu (dimming invalid accounts if applicable)
- (void)configureAccountMenu
{
    NSEnumerator	*enumerator;
    AIAccount		*anAccount;

    //remove any existing menu items
    [popUp_accounts removeAllItems];

    //insert a menu for each account
    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((anAccount = [enumerator nextObject])){

        //Accounts only show up in the menu if they're the correct handle type.
        if(!handle || [[handle serviceID] compare:[[[anAccount service] handleServiceType] identifier]] == 0){
            NSMenuItem	*menuItem;

            menuItem = [[[NSMenuItem alloc] initWithTitle:[anAccount accountDescription] target:nil action:nil keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:anAccount];

            //They are disabled if the account is offline
            if(![(AIAccount<AIAccount_Content> *)anAccount availableForSendingContentType:CONTENT_MESSAGE_TYPE toHandle:handle]){
                [menuItem setEnabled:NO];
            }
        
            [[popUp_accounts menu] addItem:menuItem];
        }
    }
    
    //Select our current account
    [popUp_accounts selectItemAtIndex:[popUp_accounts indexOfItemWithRepresentedObject:account]];
}

@end





