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
#import "AIDualWindowInterfacePlugin.h"
#import "AIAccountSelectionView.h"

#define KEY_MESSAGE_SPELL_CHECKING	@"Message"

#define MESSAGE_VIEW_NIB		@"MessageView"		//Filename of the message view nib
#define MESSAGE_TAB_TOOLBAR		@"MessageTab"		//ID of the message tab toolbar
#define ENTRY_TEXTVIEW_MAX_HEIGHT	70
#define ENTRY_TEXTVIEW_PADDING		3
#define RESIZE_CORNER_TOOLBAR_OFFSET 	0

@interface AIMessageViewController (PRIVATE)
- (id)initWithOwner:(id)inOwner handle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent interface:(id <AIContainerInterface>)inInterface;
- (void)dealloc;
- (void)textDidChange:(NSNotification *)notification;
- (void)sizeAndArrangeSubviews;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIMessageViewController

//Create a new message view controller
+ (AIMessageViewController *)messageViewControllerWithHandle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent owner:(id)inOwner interface:(id <AIContainerInterface>)inInterface
{
    return([[[self alloc] initWithOwner:inOwner handle:inHandle account:inAccount content:inContent interface:inInterface] autorelease]);
}

//Send the entered message
- (IBAction)sendMessage:(id)sender
{
    if([[textView_outgoing attributedString] length] != 0){ //If message length is 0, don't send
        AIContentMessage	*message;

        //Hide the account selection menu
        [self setAccountSelectionMenuVisible:NO];
        
        //Send the message
        [[owner notificationCenter] postNotificationName:Interface_WillSendEnteredMessage object:handle userInfo:nil];
        message = [AIContentMessage messageWithSource:account destination:handle date:nil message:[[[textView_outgoing attributedString] copy] autorelease]];
        [[owner contentController] sendContentObject:message toHandle:handle];
        [[owner notificationCenter] postNotificationName:Interface_DidSendEnteredMessage object:handle userInfo:nil];
    
        //Clear the message entry text view
        [textView_outgoing setString:@""];
        [self textDidChange:nil]; //force the view to resize
    }
}

//Return our view
- (NSView *)view
{
    return(view_contents);
}

//The destination handle of this message
- (AIContactHandle *)handle
{
    return(handle);
}

//The sounce account of this message
- (void)setAccount:(AIAccount *)inAccount
{
    [account release];
    account = [inAccount retain];
}
- (AIAccount *)account{
    return(account);
}


//Toggle the visibility of our account selection menu
- (void)setAccountSelectionMenuVisible:(BOOL)visible
{
    if(visible && !view_accountSelection){ //Hide the account selection view
        view_accountSelection = [[AIAccountSelectionView alloc] initWithFrame:NSMakeRect(0,0,100,100) delegate:self owner:owner];
        [view_contents addSubview:view_accountSelection];

    }else if(!visible && view_accountSelection){ //Show the account selection view
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


//Private -----------------------------------------------------------------------------
- (id)initWithOwner:(id)inOwner handle:(AIContactHandle *)inHandle account:(AIAccount *)inAccount content:(NSAttributedString *)inContent interface:(id <AIContainerInterface>)inInterface
{    
    [super init];
    
    //
    view_accountSelection = nil;
    owner = [inOwner retain];
    interface = [inInterface retain];
    handle = [inHandle retain];
    account = [inAccount retain];
    if(!account) account = [[[owner accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toHandle:handle] retain];

    //view
    [NSBundle loadNibNamed:MESSAGE_VIEW_NIB owner:self];

    //Create the message view
    view_messages = [[owner interfaceController] messageViewForHandle:handle];
    [scrollView_messages setAndSizeDocumentView:view_messages];
    [view_messages setNextResponder:textView_outgoing];

    //Config the outgoing text view
    [textView_outgoing setOwner:owner];
    [textView_outgoing setTarget:self action:@selector(sendMessage:)];
    [[textView_outgoing window] makeFirstResponder:textView_outgoing];
    
    //Config the toolbar
    [toolbar_bottom setIdentifier:MESSAGE_TAB_TOOLBAR];
    [toolbar_bottom configureForObjects:[NSDictionary dictionaryWithObjectsAndKeys:inHandle,@"ContactObject",textView_outgoing,@"TextEntryView",nil]];

    //Resize and arrange our views
    [self sizeAndArrangeSubviews];

    //Register for notifications
    [[owner notificationCenter] addObserver:self selector:@selector(sendMessage:) name:Interface_SendEnteredMessage object:handle];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSViewFrameDidChangeNotification object:view_contents];

    //Put the initial content in the outgoing text view
    [textView_outgoing setAttributedString:inContent];

    [self preferencesChanged:nil];

    return(self);
}

- (void)dealloc
{
    //Save spellcheck state
    [[owner preferenceController] setPreference:[NSNumber numberWithBool:[textView_outgoing isContinuousSpellCheckingEnabled]] forKey:KEY_MESSAGE_SPELL_CHECKING group:PREF_GROUP_SPELLING];
    
    //remove notifications
    [[owner notificationCenter] removeObserver:self];
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

//A preference did change
- (void)preferencesChanged:(NSNotification *)notification
{
    //Configure the message sending keys
    [textView_outgoing setSendOnEnter:[[[owner preferenceController] preferenceForKey:@"Send On Enter" group:PREF_GROUP_GENERAL object:handle] boolValue]];
    [textView_outgoing setSendOnReturn:[[[owner preferenceController] preferenceForKey:@"Send On Return" group:PREF_GROUP_GENERAL object:handle] boolValue]];

    //Configure spellchecking
    [textView_outgoing setContinuousSpellCheckingEnabled:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_SPELLING] objectForKey:KEY_MESSAGE_SPELL_CHECKING] boolValue]];
}

//The entered text has changed
- (void)textDidChange:(NSNotification *)notification
{
    [self sizeAndArrangeSubviews]; //Resize our contents to fit the text
}

//Arrange and resize our subviews based on the current state of this view (whether or not: it's locked to a handle, the account view is visible)
- (void)sizeAndArrangeSubviews
{
    int		height;
    float 	textHeight;
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
    textHeight = [[textView_outgoing layoutManager] usedRectForTextContainer:[textView_outgoing textContainer]].size.height + ENTRY_TEXTVIEW_PADDING;
    if(textHeight > ENTRY_TEXTVIEW_MAX_HEIGHT){
        textHeight = ENTRY_TEXTVIEW_MAX_HEIGHT;
        [scrollView_outgoingView setHasVerticalScroller:YES];
    }else{
        [scrollView_outgoingView setHasVerticalScroller:NO];
    }

    [scrollView_outgoingView setFrame:NSMakeRect(-1, superFrame.origin.y, superFrame.size.width + 2, textHeight)];
    superFrame.size.height -= textHeight;
    superFrame.origin.y += textHeight;

    //Messages
    [scrollView_messages setFrame:NSMakeRect(-1, superFrame.origin.y, superFrame.size.width + 2, superFrame.size.height + 1)];
}

@end


