//
//  SmackXMPPChatStateNotificationsPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-24.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPChatStateNotificationsPlugin.h"
#import "AIAccount.h"
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import <AIUtilities/AIStringUtilities.h>
#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import "AIContentController.h"
#import "AIContentTyping.h"
#import "AIChat.h"
#import "AIContactController.h"
#import "AIChatController.h"

@interface SmackCocoaAdapter (chatStateNotificationsAdditions)

+ (SmackChatStateNotifications*)getChatState:(SmackMessage*)message;
+ (SmackChatStateNotifications*)createChatState:(NSString*)type;
+ (SmackXMessageEvent*)messageEvent;

@end

@implementation SmackCocoaAdapter (chatStateNotificationsAdditions)

+ (SmackChatStateNotifications*)getChatState:(SmackMessage*)message {
    return [[[self classLoader] loadClass:@"net.adium.smackBridge.ChatStateNotifications"] getChatState:message];
}

+ (SmackChatStateNotifications*)createChatState:(NSString*)type {
    return [[[self classLoader] loadClass:@"net.adium.smackBridge.ChatStateNotifications"] createChatState:type];
}

+ (SmackXMessageEvent*)messageEvent {
    return [[[[self classLoader] loadClass:@"org.jivesoftware.smackx.packet.MessageEvent"] newWithSignature:@"()"] autorelease];
}

@end

@implementation SmackXMPPAccount (chatStateNotificationsAdditions)

- (BOOL)suppressTypingNotificationChangesAfterSend {
	return YES;
}

- (BOOL)sendTypingObject:(AIContentTyping *)inTypingObject {
//    NSLog(@"typing %@",([inTypingObject typingState]==AINotTyping)?@"NO":(([inTypingObject typingState]==AITyping)?@"TYPING":@"ENTEREDTEXT"));
    if([self currentlyInvisible])
        return YES; // when invisible, don't send typing notifications to not reveal that we're actually here
    
    AIChat *chat = [inTypingObject chat];
    
    if([chat isGroupChat])
    {
        NSLog(@"typing ignored -> groupchat");
        return YES; // ignore group chats
    }

    BOOL useCsn = [[chat statusObjectForKey:@"XMPPChatStateNotifications"] boolValue];
    BOOL useMessageEvent = [[chat statusObjectForKey:@"XMPPMessageEventComposingRequest"] boolValue];
    
    if(!useCsn && !useMessageEvent)
        return YES; // the other client doesn't support any of the two
    
    if(useCsn && ![[chat statusObjectForKey:@"XMPPType"] isEqualToString:@"chat"])
    {
        NSLog(@"typing ignored -> not a chat");
        return NO; // ChatStateNotifications only allowed in chats
    }

    NSString *resource = [chat statusObjectForKey:@"XMPPResource"];
    NSString *jid = [[chat listObject] UID];
    
    SmackMessage *message = [SmackCocoaAdapter messageTo:jid typeString:@"CHAT"];

    if(useCsn)
    {
        SmackChatStateNotifications *csn = nil;
        switch([inTypingObject typingState]) {
            case AINotTyping:
                csn = [SmackCocoaAdapter createChatState:@"active"];
                break;
            case AITyping:
                csn = [SmackCocoaAdapter createChatState:@"composing"];
                break;
            case AIEnteredText:
                csn = [SmackCocoaAdapter createChatState:@"paused"];
                break;
            default:
                NSLog(@"typing ignored -> unknown typing state");
                return NO; // ignore
        }
        [message addExtension:csn];

        // JEP-0022 says that no other tags may be included, so we only use the thread id here
        
        NSString *threadid = [chat statusObjectForKey:@"XMPPThreadID"];

        if(!threadid || [threadid length] == 0) // first message was sent by us
        {
            [chat setStatusObject:threadid = [chat uniqueChatID] forKey:@"XMPPThreadID" notify:NotifyLater];
            
            //Apply the change
            [chat notifyOfChangedStatusSilently:[self silentAndDelayed]];
        }
        [message setThread:threadid];
        
    } else if(useMessageEvent)
    {
        SmackXMessageEvent *mevt = [SmackCocoaAdapter messageEvent];
        [mevt setPacketID:[chat statusObjectForKey:@"XMPPMessageEventPacketID"]?[chat statusObjectForKey:@"XMPPMessageEventPacketID"]:@""];
        switch([inTypingObject typingState]) {
            case AINotTyping:
            case AIEnteredText:
                [mevt setCancelled:YES];
                break;
            case AITyping:
                [mevt setComposing:YES];
                break;
            default:
                NSLog(@"typing ignored -> unknown typing state");
                return NO; // ignore
        }
        [message addExtension:mevt];
    }
        
    [connection sendPacket:message];

    return YES;
}

@end

@implementation SmackXMPPChatStateNotificationsPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if((self = [super init]))
    {
        account = a;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedMessagePacket:)
                                                     name:SmackXMPPMessagePacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendMessage:)
                                                     name:SmackXMPPMessageSentNotification
                                                   object:account];
    }
    return self;
}

- (void)dealloc {
    [[adium notificationCenter] removeObserver:self];
    [[SmackCocoaAdapter serviceDiscoveryManagerForConnection:[account connection]] removeFeature:@"http://jabber.org/protocol/chatstates"];
    [super dealloc];
}

- (void)connected:(SmackXMPPConnection*)connection
{
    SmackXServiceDiscoveryManager *sdm = [SmackCocoaAdapter serviceDiscoveryManagerForConnection:[account connection]];
    if(![sdm includesFeature:@"http://jabber.org/protocol/chatstates"])
        [sdm addFeature:@"http://jabber.org/protocol/chatstates"];
}

- (void)receivedMessagePacket:(NSNotification*)n
{
    SmackMessage *packet = [[n userInfo] objectForKey:SmackXMPPPacket];

    AIListContact *sourceContact = [[adium contactController] existingContactWithService:[account service] account:account UID:[packet getFrom]];
    
    if(!sourceContact)
        return; // if we don't know that person, we don't have a chat either
    
    AIChat *chat = [[adium chatController] existingChatWithContact:sourceContact];
    if(!chat)
        return; // no need to care about chats that aren't open
    
    SmackChatStateNotifications *csn = [SmackCocoaAdapter getChatState:packet];
    
    if(csn && [[[packet getType] toString] isEqualToString:@"chat"])
    {
        NSString *type = [csn getElementName];
        if([type isEqualToString:@"active"])
            [chat setStatusObject:[NSNumber numberWithInt:AINotTyping]
                           forKey:KEY_TYPING
                           notify:NotifyNow];
        else if([type isEqualToString:@"paused"])
            [chat setStatusObject:[NSNumber numberWithInt:AIEnteredText]
                           forKey:KEY_TYPING
                           notify:NotifyNow];
        else if([type isEqualToString:@"composing"])
            [chat setStatusObject:[NSNumber numberWithInt:AITyping]
                           forKey:KEY_TYPING
                           notify:NotifyNow];
        else if([type isEqualToString:@"gone"])
        {
            [[adium contentController] displayEvent:AILocalizedString(@"The user has closed the chat.","The user has closed the chat.")
                                             ofType:@"chat-info"
                                             inChat:chat];
            // now remove thread id, since it's no longer valid
            // note that there's no way to remove the status, so just set it to @""
            [chat setStatusObject:@"" forKey:@"XMPPThreadID" notify:NotifyNow];
        } else if([type isEqualToString:@"inactive"])
            [[adium contentController] displayEvent:AILocalizedString(@"The user is inactive.","The user is inactive.")
                                             ofType:@"chat-info"
                                             inChat:chat];
        [chat setStatusObject:[NSNumber numberWithBool:YES] forKey:@"XMPPChatStateNotifications" notify:NotifyNow];
        [[adium notificationCenter] addObserver:self
                                       selector:@selector(chatWillClose:)
                                           name:Chat_WillClose
                                         object:chat];
    } else {
        SmackXMessageEvent *mevt = [packet getExtension:@"x" :@"jabber:x:event"];
        if(mevt)
        {
            if([mevt isMessageEventRequest])
            {
                if([mevt isComposing])
                {
                    [chat setStatusObject:[NSNumber numberWithBool:YES] forKey:@"XMPPMessageEventComposingRequest" notify:NotifyLater];
                    [chat setStatusObject:[packet getPacketID] forKey:@"XMPPMessageEventPacketID" notify:NotifyLater];
                }
                if([mevt isDelivered])
                {
                    SmackMessage *msg = [SmackCocoaAdapter messageTo:[packet getFrom] typeString:@"NORMAL"];
                    SmackXMessageEvent *mevt2 = [SmackCocoaAdapter messageEvent];
                    [mevt2 setDelivered:YES];
                    [msg addExtension:mevt2];
                    [[account connection] sendPacket:msg];
                }
                if([mevt isDisplayed])
                {
                    // not really correct here, but the plugin can't tell when it's actually displayed
                    SmackMessage *msg = [SmackCocoaAdapter messageTo:[packet getFrom] typeString:@"NORMAL"];
                    SmackXMessageEvent *mevt2 = [SmackCocoaAdapter messageEvent];
                    [mevt2 setDisplayed:YES];
                    [msg addExtension:mevt2];
                    [[account connection] sendPacket:msg];
                }
            } else {
                if([mevt isComposing])
                    [chat setStatusObject:[NSNumber numberWithInt:AITyping]
                                   forKey:KEY_TYPING
                                   notify:NotifyNow];
                else if([mevt isCancelled])
                    [chat setStatusObject:[NSNumber numberWithInt:AINotTyping]
                                   forKey:KEY_TYPING
                                   notify:NotifyNow];
                else if([mevt isOffline])
                    [[adium chatController] displayEvent:AILocalizedString(@"The user is offline. The message was stored on the user's server.", "The user is offline. The message was stored on the user's server.")
                                                  ofType:@"chat-info"
                                                  inChat:chat];
            }
        } else
            [chat setStatusObject:[NSNumber numberWithBool:NO] forKey:@"XMPPMessageEventComposingRequest" notify:NotifyLater];
    }
    if([packet getBody])
        [chat setStatusObject:[NSNumber numberWithInt:AINotTyping]
                       forKey:KEY_TYPING
                       notify:NotifyNow];
}

- (void)chatWillClose:(NSNotification*)notification
{
    if([account currentlyInvisible])
        return; // when invisible, don't send typing notifications to not reveal that we're actually here

    AIChat *chat = [notification object];
    [[adium notificationCenter] removeObserver:self
                                          name:Chat_WillClose
                                        object:chat];
    
    NSNumber *useCSN = [chat statusObjectForKey:@"XMPPChatStateNotifications"];
    if(!(useCSN && [useCSN boolValue]))
        return; // just ignore it

    NSString *threadid = [chat statusObjectForKey:@"XMPPThreadID"];
    
    if(!threadid || [threadid length] == 0)
        return; // no active thread? The other user might have gone before us, so he/she doesn't care about us closing the window

    NSString *jid = [[chat listObject] UID];
    NSString *resource = [chat statusObjectForKey:@"XMPPResource"];
    if(resource)
        jid = [NSString stringWithFormat:@"%@/%@",jid,resource];
    
    SmackMessage *message = [SmackCocoaAdapter messageTo:jid typeString:@"CHAT"];
    
    [message setThread:threadid];
    [message addExtension:[SmackCocoaAdapter createChatState:@"gone"]];
    
    [[account connection] sendPacket:message];
}

- (void)sendMessage:(NSNotification*)n
{
    if([account currentlyInvisible])
        return; // when invisible, don't send typing notifications to not reveal that we're actually here
    AIContentMessage *inMessageObject = [[n userInfo] objectForKey:AIMessageObjectKey];
    SmackMessage *message = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    AIChat *chat = [inMessageObject chat];
    if([chat isGroupChat])
        return; // ignore group chat messages
    
    NSNumber *useCSN = [chat statusObjectForKey:@"XMPPChatStateNotifications"];
    
    if(!useCSN || [useCSN boolValue])
        [message addExtension:[SmackCocoaAdapter createChatState:@"active"]];
    if(!useCSN || ![useCSN boolValue])
    {
        NSNumber *useMessageEvent = [chat statusObjectForKey:@"XMPPMessageEventNotification"];
        if(!useMessageEvent || [useMessageEvent boolValue])
        {
            SmackXMessageEvent *mevt = [SmackCocoaAdapter messageEvent];
            [mevt setComposing:YES];
            [mevt setOffline:YES];
            [message addExtension:mevt];
        }
    }
}

@end
