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
- (void)_sendTyping:(BOOL)typing toContact:(AIListContact *)contact onAccount:(AIAccount *)account;
@end

@implementation AITypingNotificationPlugin

//..Don't sent typing notifications until the contact has messaged us..

- (void)installPlugin
{
    //Register as an entry filter
    [[owner contentController] registerTextEntryFilter:self];

    typingDict = [[NSMutableDictionary alloc] init];
    messagedDict = [[NSMutableDictionary alloc] init];

    [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
}

//Watch incoming content.  Once we are messaged by a contact, that contact may receive typing notifications
- (void)didReceiveContent:(NSNotification *)notification
{
    id			object = [[notification userInfo] objectForKey:@"Object"];
    AIListContact	*contact = (AIListContact *)[object source];
    AIAccount		*account = (AIAccount *)[object destination];
    NSString		*key;
    NSNumber		*cleared;

    key = [NSString stringWithFormat:@"(%@)%@",[account accountID],[contact UIDAndServiceID]];
    cleared = [messagedDict objectForKey:key];

    //Clear this contact for receiving typing notifications
    if(!cleared){
        [messagedDict setObject:[NSNumber numberWithBool:1] forKey:key];
    }
}

- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    AIListContact	*contact = [inTextEntryView contact];
    AIAccount		*account = [inTextEntryView account];
    NSString		*key = [NSString stringWithFormat:@"(%@)%@",[account accountID],[contact UIDAndServiceID]];

    if(contact && account){
        if([[inTextEntryView attributedString] length] == 0 && [messagedDict objectForKey:key] != nil){
            [self _sendTyping:NO toContact:contact onAccount:account]; //Not typing
            
        }else{
            if(![[typingDict objectForKey:key] boolValue] && [messagedDict objectForKey:key] != nil){
                [self _sendTyping:YES toContact:contact onAccount:account]; //Typing
            }
            
        }
    }
}

- (void)_sendTyping:(BOOL)typing toContact:(AIListContact *)contact onAccount:(AIAccount *)account
{
    AIContentTyping	*contentObject;
    AIHandle		*handle;
    NSString		*key;

    //Get the dest handle
    handle = [[owner contactController] handleOfContact:contact forReceivingContentType:CONTENT_MESSAGE_TYPE fromAccount:account];

    //Send typing content object (Directly to the account)
    contentObject = [AIContentTyping typingContentWithSource:account destination:contact typing:typing];
    [(AIAccount <AIAccount_Content> *)account sendContentObject:contentObject];
        
    //Remember the state
    key = [NSString stringWithFormat:@"(%@)%@",[account accountID],[contact UIDAndServiceID]];
    if(typing){
        //Add 'typing' for this contact
        [typingDict setObject:[NSNumber numberWithBool:YES] forKey:key];

    }else{
        //Remove 'typing' for this contact
        [typingDict removeObjectForKey:key];

    }
}

- (void)initTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

@end
