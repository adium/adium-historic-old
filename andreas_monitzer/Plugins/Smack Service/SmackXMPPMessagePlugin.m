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
#import "AIContentController.h"

#import "AIAccount.h"
#import "AIContentMessage.h"
#import "AIHTMLDecoder.h"

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
    
    if([type isEqualToString:@"normal"] || [type isEqualToString:@"chat"])
    {
        AIChat				*chat;
        AIContentMessage	*messageObject;
        NSAttributedString  *inMessage = nil;
        NSString *from = [packet getFrom];
        NSString *resource = [from jidResource];
        NSString *thread = [packet getThread];
        
        AIListContact *sourceContact = [account contactWithJID:[from jidUserHost]];
        
        if (!(chat = [[adium chatController] existingChatWithContact:sourceContact]))
        {
            chat = [[adium chatController] openChatWithContact:sourceContact];
            [chat setStatusObject:thread?thread:[chat uniqueChatID] forKey:@"XMPPThreadID" notify:NotifyLater];
            if(resource)
                [chat setStatusObject:resource forKey:@"XMPPResource" notify:NotifyLater];
            
            //Apply the change
            [chat notifyOfChangedStatusSilently:[account silentAndDelayed]];
        }
        
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
                inMessage = [[messageencoder decodeHTML:htmlmsg] retain];
            }
        }
        if(!inMessage)
            inMessage = [[NSAttributedString alloc] initWithString:[packet getBody] attributes:nil];
        
        messageObject = [AIContentMessage messageInChat:chat
                                             withSource:sourceContact
                                            destination:account
                                                   date:[NSDate date]
                                                message:inMessage
                                              autoreply:NO];
        [inMessage release];
        
        [[adium contentController] receiveContentObject:messageObject];
    }
}

- (void)sendMessage:(NSNotification*)n
{
    SmackXMPPAccount *account = [n object];
    AIContentMessage *inMessageObject = [[n userInfo] objectForKey:AIMessageObjectKey];
    
    AIChat *chat = [inMessageObject chat];
    
    NSString *threadid = [chat statusObjectForKey:@"XMPPThreadID"];
    NSString *resource = [chat statusObjectForKey:@"XMPPResource"];
    
    if(!threadid) // first message was sent by us
    {
        [chat setStatusObject:threadid = [chat uniqueChatID] forKey:@"XMPPThreadID"  notify:NotifyLater];
        
        //Apply the change
        [chat notifyOfChangedStatusSilently:[account silentAndDelayed]];
    }
    
    NSString *jid = [[[inMessageObject chat] listObject] UID];
    if(resource)
        jid = [NSString stringWithFormat:@"%@/%@",jid,resource];
    
    SmackMessage *newmsg = [SmackCocoaAdapter messageTo:jid typeString:@"CHAT"];
    
    [newmsg setThread:threadid];
    [newmsg setBody:[inMessageObject messageString]];
    
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
    
    [newmsg addExtension:xhtml];
    
    [[account connection] sendPacket:newmsg];
}


@end
