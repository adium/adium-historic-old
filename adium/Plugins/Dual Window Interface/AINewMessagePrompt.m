//
//  AINewMessagePrompt.m
//  Adium
//
//  Created by Adam Iser on Sat Feb 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AINewMessagePrompt.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

#define NEW_MESSAGE_PROMPT_NIB	@"NewMessagePrompt"

@interface AINewMessagePrompt (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (void)windowDidLoad;
- (BOOL)shouldCascadeWindows;
- (BOOL)windowShouldClose:(id)sender;
@end


@implementation AINewMessagePrompt

static AINewMessagePrompt *sharedInstance = nil;
+ (void)newMessagePromptWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:NEW_MESSAGE_PROMPT_NIB owner:inOwner];
        [[sharedInstance window] makeKeyAndOrderFront:nil];
    }
}

+ (void)closeSharedInstance
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
    }
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//New Mesasge
- (IBAction)newMessage:(id)sender
{
    AIContactHandle	*handle;

    //Find the handle
    handle = [[owner contactController] handleWithService:[[popUp_service selectedItem] representedObject]
                                                      UID:[textField_handle stringValue]
                                               forAccount:[[owner accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toHandle:nil]];

    //Close the prompt
    [AINewMessagePrompt closeSharedInstance];

    //Initiate the message
    [[owner notificationCenter] postNotificationName:Interface_InitiateMessage
                                              object:nil
                                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:handle, @"To", nil]];
}

- (IBAction)selectService:(id)sender
{

}



// Private --------------------------------------------------------------------------------
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    //init
    [super initWithWindowNibName:windowNibName owner:self];
    owner = [inOwner retain];
    

    return(self);
}

- (void)dealloc
{
    [owner release];
    
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
    NSEnumerator		*enumerator;
    AIContactObject		*object;
    id <AIServiceController>	service;
    
    //Configure the auto-complete view
    enumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES ownedBy:nil] objectEnumerator];
    while((object = [enumerator nextObject])){
        [textField_handle addCompletionString:[object UID]];
    }

    //Configure the handle type menu
    [popUp_service removeAllItems];

    enumerator = [[[owner accountController] availableServiceArray] objectEnumerator];
    while((service = [enumerator nextObject])){
        AIServiceType	*serviceType = [service handleServiceType];
        NSMenuItem	*menuItem;

        menuItem = [[NSMenuItem alloc] initWithTitle:[serviceType description] target:self action:@selector(selectService:) keyEquivalent:@""];
        [menuItem setRepresentedObject:serviceType];

        [[popUp_service menu] addItem:menuItem];
    }
}

- (BOOL)shouldCascadeWindows
{
    return(NO);
}

- (BOOL)windowShouldClose:(id)sender
{
    [self autorelease]; sharedInstance = nil; //Close the shared instance
    return(YES);
}

@end
