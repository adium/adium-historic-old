//
//  AITypingNotificationPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AITypingNotificationPlugin.h"
#import <Adium/Adium.h>

@interface AITypingNotificationPlugin (PRIVATE)
- (void)_sendTyping:(BOOL)typing toChat:(AIChat *)chat;
@end

#define CAN_RECEIVE_TYPING	@"CanReceiveTyping"
#define WE_ARE_TYPING		@"WeAreTyping"

@implementation AITypingNotificationPlugin

- (void)installPlugin
{
    //Register as an entry filter
    [[owner contentController] registerTextEntryFilter:self];

    typingDict = [[NSMutableDictionary alloc] init];
    //messagedDict = [[NSMutableDictionary alloc] init];

    [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
}

//Watch incoming content.  Once we are messaged by a contact, that contact may receive typing notifications
- (void)didReceiveContent:(NSNotification *)notification
{
    AIChat		*chat = [notification object];
    NSNumber		*cleared;

    cleared = [[chat statusDictionary] objectForKey:CAN_RECEIVE_TYPING];

    //Clear this contact for receiving typing notifications
    if(!cleared){
        [[chat statusDictionary] setObject:[NSNumber numberWithBool:1] forKey:CAN_RECEIVE_TYPING];
    }
}

- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    AIChat		*chat = [inTextEntryView chat];

    if(chat){
        if([[inTextEntryView attributedString] length] == 0 && [[chat statusDictionary] objectForKey:CAN_RECEIVE_TYPING] != nil){
            [self _sendTyping:NO toChat:chat]; //Not typing
            
        }else{
            if(![[[chat statusDictionary] objectForKey:WE_ARE_TYPING] boolValue] && [[chat statusDictionary] objectForKey:CAN_RECEIVE_TYPING] != nil){
                [self _sendTyping:YES toChat:chat]; //Typing
            }
            
        }
    }
}

- (void)_sendTyping:(BOOL)typing toChat:(AIChat *)chat
{
    AIAccount		*account = [chat account];
    AIContentTyping	*contentObject;
 
    //Send typing content object (It will go directly to the account since typing content isn't tracked or filtered)
    contentObject = [AIContentTyping typingContentInChat:chat
                                              withSource:account
                                             destination:nil
                                                  typing:typing];
    [[owner contentController] sendContentObject:contentObject];
    
    //Remember the state
    if(typing){ //Add 'typing' for this contact
        [[chat statusDictionary] setObject:[NSNumber numberWithBool:1] forKey:WE_ARE_TYPING];

    }else{ //Remove 'typing' for this contact
        [[chat statusDictionary] removeObjectForKey:WE_ARE_TYPING];

    }
}

- (void)initTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

@end
