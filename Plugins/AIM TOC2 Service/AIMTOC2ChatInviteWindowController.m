//
//  AIMTOC2ChatInviteWindowController.m
//  Adium
//
//  Created by Adam Iser on Fri Aug 15 2003.
//

#import "AIMTOC2ChatInviteWindowController.h"
#import "AIMTOC2Account.h"

#define	INVITE_WINDOW_NIB	@"ChatInviteWindow"	//Filename of the invite window nib


@interface AIMTOC2ChatInviteWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName handle:(AIHandle *)inHandle chatID:(NSString *)inChatID name:(NSString *)inChatName account:(AIMTOC2Account *)inAccount;
- (BOOL)shouldCascadeWindows;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
@end

@implementation AIMTOC2ChatInviteWindowController
//
+ (id)chatInviteFrom:(AIHandle *)inHandle forChatID:(NSString *)inChatID name:(NSString *)inChatName account:(AIMTOC2Account *)inAccount
{
    return([[self alloc] initWithWindowNibName:INVITE_WINDOW_NIB handle:inHandle chatID:inChatID name:inChatName account:inAccount]);
}

//
- (id)initWithWindowNibName:(NSString *)windowNibName handle:(AIHandle *)inHandle chatID:(NSString *)inChatID name:(NSString *)inChatName account:(AIMTOC2Account *)inAccount
{
    //
    [super initWithWindowNibName:windowNibName];

    //
    handle = [inHandle retain];
    chatID = [inChatID retain];
    chatName = [inChatName retain];
    account = [inAccount retain];
    
    return(self);
}

- (void)dealloc
{
    [handle release];
    [chatID release];
    [chatName release];

    [super dealloc];
}

- (IBAction)accept:(id)sender
{
    [account acceptInvitationForChatID:chatID];
    [self closeWindow:nil];
}

- (IBAction)decline:(id)sender
{
    [account declineInvitationForChatID:chatID];
    [self closeWindow:nil];
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Prevents the system from moving our window around
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//Called after the window loads, so we can set up the window before it's displayed
- (void)windowDidLoad
{
    NSRect	frame = [[self window] frame];
    int		heightChange;

    //Setup the textview
    [textView_prompt setHorizontallyResizable:NO];
    [textView_prompt setVerticallyResizable:YES];
    [textView_prompt setDrawsBackground:NO];
    [scrollView_prompt setDrawsBackground:NO];

    //Display the prompt
    [textView_prompt setString:[NSString stringWithFormat:@"%@ has invited you to chat in '%@'", [[handle containingContact] displayName], chatName]];

    //Resize the window to fit the prompt
    [textView_prompt sizeToFit];
    heightChange = [textView_prompt frame].size.height - [scrollView_prompt documentVisibleRect].size.height;

    frame.size.height += heightChange;
    frame.origin.y -= heightChange;
    [[self window] setFrame:frame display:NO animate:NO];
}

//Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //Release the window controller (ourself)
    [self autorelease];

    return(YES);
}


@end
