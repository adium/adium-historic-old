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
    AIChat		*chat = [inTextEntryView chat];
    AIAccount		*account = [chat account];
    AIListObject	*object = [chat object];
    NSString		*key = [NSString stringWithFormat:@"(%@)%@",[account accountID],[object UIDAndServiceID]];

    if(object && account){
        if([[inTextEntryView attributedString] length] == 0 && [messagedDict objectForKey:key] != nil){
            [self _sendTyping:NO toChat:chat]; //Not typing
            
        }else{
            if(![[typingDict objectForKey:key] boolValue] && [messagedDict objectForKey:key] != nil){
                [self _sendTyping:YES toChat:chat]; //Typing
            }
            
        }
    }
}

- (void)_sendTyping:(BOOL)typing toChat:(AIChat *)chat
{
    AIAccount		*account = [chat account];
    AIListObject	*object = [chat object];
    AIContentTyping	*contentObject;
    NSString		*key;
 
    //Send typing content object (It will go directly to the account since typing content isn't tracked or filtered)
    contentObject = [AIContentTyping typingContentInChat:chat
                                              withSource:account
                                             destination:object
                                                  typing:typing];
    [[owner contentController] sendContentObject:contentObject];
    
    //Remember the state
    key = [NSString stringWithFormat:@"(%@)%@",[account accountID],[object UIDAndServiceID]];
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
