//
//  SmackXMPPMessagePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-23.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPMessagePlugin.h"
#import "SmackXMPPAccount.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackCocoaAdapter.h"
#import "SmackListContact.h"

#import "AIAdium.h"
#import "AIChatController.h"
#import "AIChat.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIAccount.h"
#import "AIContentMessage.h"
#import "AIHTMLDecoder.h"
#import "ESTextAndButtonsWindowController.h"
#import <AIUtilities/AIStringUtilities.h>

static AIHTMLDecoder *messageencoder = nil;

@implementation SmackXMPPMessagePlugin

- (id)initWithAccount:(SmackXMPPAccount*)account
{
    if((self = [super init]))
    {
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


- (void)receivedMessagePacket:(NSNotification*)n
{
    SmackXMPPAccount *account = [n object];
    SmackMessage *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    NSString *type = [[packet getType] toString];
    
    if(([type isEqualToString:@"normal"] || [type isEqualToString:@"chat"]) && [packet getBody] != nil)
    {
        AIChat				*chat;
        AIContentMessage	*messageObject;
        NSAttributedString  *inMessage = nil;
        NSString *from = [packet getFrom];
        NSString *resource = [from jidResource];
        NSString *thread = [packet getThread];
        
        AIListContact *chatContact = [[adium contactController] contactWithService:[account service] account:account UID:[from jidUserHost]];
        AIListContact *sourceContact = [[adium contactController] contactWithService:[account service] account:account UID:from];
        
        if (!(chat = [[adium chatController] existingChatWithContact:chatContact]))
        {
            chat = [[adium chatController] openChatWithContact:chatContact];
            [chat setStatusObject:thread?thread:[chat uniqueChatID] forKey:@"XMPPThreadID" notify:NotifyLater];
            
            [chat setStatusObject:type forKey:@"XMPPType" notify:NotifyLater];
            
            //Apply the change
            [chat notifyOfChangedStatusSilently:[account silentAndDelayed]];
        } else {
            [chat setStatusObject:thread?thread:[chat uniqueChatID] forKey:@"XMPPThreadID" notify:NotifyLater];
            
            // always update the chat type
            [chat setStatusObject:type forKey:@"XMPPType" notify:NotifyNow];
        }

        // always update the resource (so we send messages to the one we most recently got a message from)
        if(resource)
            [chat setStatusObject:resource forKey:@"XMPPResource" notify:NotifyLater];

        SmackXXHTMLExtension *spe = [packet getExtension:@"html" :@"http://jabber.org/protocol/xhtml-im"];
        if(spe)
        {
            JavaIterator *iter = [spe getBodies];
            NSString *htmlmsg = nil;
            if(iter && [iter hasNext])
                htmlmsg = [iter next];
            if([htmlmsg length] > 0)
            {
                if(!messageencoder)
                {
                    messageencoder = [[AIHTMLDecoder alloc] init];
                    [messageencoder setGeneratesStrictXHTML:YES];
                    [messageencoder setIncludesHeaders:NO];
                    [messageencoder setIncludesStyleTags:YES];
                    [messageencoder setEncodesNonASCII:NO];
                }
                // the AIHTMLDecoder class doesn't support decoding the XHTML required by JEP-71, so we'll just use the
                // one by Apple, which works fine
//                inMessage = [[messageencoder decodeHTML:htmlmsg] retain];
                NSMutableDictionary *param = [NSMutableDictionary dictionaryWithObject:[[NSString stringWithFormat:@"<html>%@</html>",htmlmsg] dataUsingEncoding:NSUnicodeStringEncoding]
                                                                                forKey:@"htmldata"];
                [self performSelectorOnMainThread:@selector(convertToAttributedString:)
                                       withObject:param waitUntilDone:YES];
                inMessage = [[param objectForKey:@"result"] retain];
            }
        }
        if(!inMessage)
            inMessage = [[NSAttributedString alloc] initWithString:[packet getBody] attributes:nil];
        
        SmackXDelayInformation *delayinfo = [packet getExtension:@"x" :@"jabber:x:delay"];
        NSDate *date = nil;
        if(delayinfo)
            date = [SmackCocoaAdapter dateFromJavaDate:[delayinfo getStamp]];
        else
            date = [NSDate date];
        
        SmackOutOfBandExtension *oob = [packet getExtension:@"x" :@"jabber:x:oob"];
        if(oob && [[oob getUrl] length] > 0)
            [[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"URL From %@","URL From %@"),[sourceContact displayName]]
                                         withDescription:[NSString stringWithFormat:@"%@\n%@",[oob getDesc]?[oob getDesc]:@"",[oob getUrl]]
                                         withWindowTitle:AILocalizedString(@"URL","URL")
                                           defaultButton:AILocalizedString(@"Open URL","Open URL")
                                         alternateButton:AILocalizedString(@"Cancel","Cancel")
                                             otherButton:nil
                                                  target:self
                                                selector:@selector(openURLRequest:userInfo:)
                                                userInfo:oob];

        messageObject = [AIContentMessage messageInChat:chat
                                             withSource:sourceContact
                                            destination:account
                                                   date:date
                                                message:inMessage
                                              autoreply:NO];
        [inMessage release];
        
        [[adium contentController] receiveContentObject:messageObject];
    }
}

- (void)openURLRequest:(NSNumber*)result userInfo:(SmackOutOfBandExtension*)oob
{
    if([result intValue] == AITextAndButtonsDefaultReturn)
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[oob getUrl]]];
}

- (void)convertToAttributedString:(NSMutableDictionary*)param
{
    [param setObject:[[[NSAttributedString alloc] initWithHTML:[param objectForKey:@"htmldata"]
                                                       options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnicodeStringEncoding] forKey:NSCharacterEncodingDocumentOption]
                                            documentAttributes:NULL] autorelease] forKey:@"result"];
}

- (void)sendMessage:(NSNotification*)n
{
    SmackXMPPAccount *account = [n object];
    AIContentMessage *inMessageObject = [[n userInfo] objectForKey:AIMessageObjectKey];
    SmackMessage *message = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    AIChat *chat = [inMessageObject chat];
    if([chat isGroupChat])
        return; // ignore group chat messages
    
    NSString *threadid = [chat statusObjectForKey:@"XMPPThreadID"];
    NSString *resource = [chat statusObjectForKey:@"XMPPResource"];
    NSString *type = [chat statusObjectForKey:@"XMPPType"];
    if(!type)
        type = @"chat";
    
    if(!threadid || [threadid length] == 0) // first message was sent by us
    {
        [chat setStatusObject:threadid = [chat uniqueChatID] forKey:@"XMPPThreadID" notify:NotifyLater];
        
        //Apply the change
        [chat notifyOfChangedStatusSilently:[account silentAndDelayed]];
    }
    
    NSString *to = [[chat listObject] UID];
    
    if(resource && [[to jidResource] length] == 0)
        to = [NSString stringWithFormat:@"%@/%@",to,resource];
    
    [message setTo:to];
    [message setType:[SmackCocoaAdapter messageTypeFromString:[type uppercaseString]]]; // field names are all uppercase
    
    [message setThread:threadid];
    [message setBody:[inMessageObject messageString]];
    
    NSAttributedString *attmessage = [inMessageObject message];
    if(!messageencoder)
    {
        messageencoder = [[AIHTMLDecoder alloc] init];
        [messageencoder setGeneratesStrictXHTML:YES];
        [messageencoder setIncludesHeaders:NO];
        [messageencoder setIncludesStyleTags:YES];
        [messageencoder setEncodesNonASCII:NO];
    }
    
    // add the XHTML representation
    
    NSString *xhtmlmessage = [messageencoder encodeHTML:attmessage imagesPath:nil];
    // for some reason I can't specify that I don't want <html> but that I do want <body>...
    NSString *xhtmlbody = [NSString stringWithFormat:@"<body xmlns='http://www.w3.org/1999/xhtml'>%@</body>",xhtmlmessage];
    
    SmackXXHTMLExtension *xhtml = [SmackCocoaAdapter XHTMLExtension];
    [xhtml addBody:xhtmlbody];
    
    [message addExtension:xhtml];
    
    // sending occurs in SmackXMPPAccount
}


@end
