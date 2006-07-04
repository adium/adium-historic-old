//
//  SmackXMPPMultiUserChatPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-03.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPMultiUserChatPlugin.h"
#import "SmackXMPPAccount.h"
#import "AIHTMLDecoder.h"
#import "SmackCocoaAdapter.h"
#import "SmackXMPPService.h"

#import "AIAdium.h"
#import <Adium/AIChat.h>
#import <Adium/DCJoinChatViewController.h>
#import "AIContentController.h"
#import "AIContactController.h"
#import "AIInterfaceController.h"
#import "AIChatController.h"
#import <JavaVM/NSJavaVirtualMachine.h>
#import <AIUtilities/AIStringUtilities.h>
#import "SmackInterfaceDefinitions.h"
#import "SmackXMPPFormController.h"

#import "ESDebugAILog.h"

static AIHTMLDecoder *messageencoder = nil;

@interface SmackXMPPMultiUserChatPluginListener : NSObject {
}

- (void)setDelegate:(id<SmackXMPPMultiUserChatPluginListenerDelegate>)delegate;
- (id<SmackXMPPMultiUserChatPluginListenerDelegate>)delegate;
- (void)destroy;
- (void)listenToChat:(SmackXMultiUserChat*)chat :(id)d;

@end

@interface SmackCocoaAdapter (MultiUserChatAddons)

+ (SmackXMPPMultiUserChatPluginListener*)MUCPluginListenerWithConnection:(SmackXMPPConnection*)conn;

+ (SmackXMultiUserChat*)joinMultiUserChatWithName:(NSString*)name connection:(SmackXMPPConnection*)conn;

@end

@implementation SmackCocoaAdapter (MultiUserChatAddons)

+ (SmackXMPPMultiUserChatPluginListener*)MUCPluginListenerWithConnection:(SmackXMPPConnection*)conn {
    return [[NSClassFromString(@"net.adium.smackBridge.SmackXMPPMultiUserChatPluginListener") newWithSignature:@"(Lorg/jivesoftware/smack/XMPPConnection;)",conn] autorelease];
}

+ (SmackXMultiUserChat*)joinMultiUserChatWithName:(NSString*)name connection:(SmackXMPPConnection*)conn {
    return [[NSClassFromString(@"org.jivesoftware.smackx.muc.MultiUserChat") newWithSignature:@"(Lorg/jivesoftware/smack/XMPPConnection;Ljava/lang/String;)",conn,name] autorelease];
}

@end

#define SmackXMPPJoinChatNotification @"SmackXMPPJoinChatNotification"

@interface SmackXMPPJoinChatViewController : DCJoinChatViewController {
    IBOutlet NSTextField *chatRoomNameField;
    IBOutlet NSTextField *serverField;
    IBOutlet NSTextField *nicknameField;
    IBOutlet NSTextField *passwordField;
}

@end

@implementation SmackXMPPJoinChatViewController

- (NSString*)nibName
{
    return @"SmackXMPPJoinChatView";
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	[[view window] makeFirstResponder:chatRoomNameField];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount {
    
    chat = [[adium chatController] chatWithName:[NSString stringWithFormat:@"%@@%@",[chatRoomNameField stringValue],[serverField stringValue]]
									  onAccount:inAccount
							   chatCreationInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [chatRoomNameField stringValue], @"chatroom",
                                   [serverField stringValue], @"server",
                                   [nicknameField stringValue], @"nickname",
                      ([[passwordField stringValue] length]>0)?[passwordField stringValue]:nil, @"password",
                                   nil]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPJoinChatNotification
                                                        object:inAccount
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [chatRoomNameField stringValue], @"chatroom",
                                                          [serverField stringValue], @"server",
                                                          [nicknameField stringValue], @"nickname",
                                                          chat, @"chat",
                                     ([[passwordField stringValue] length]>0)?[passwordField stringValue]:nil, @"password",
                                                          nil]];
}

@end

@implementation SmackXMPPAccount (MultiUserChatAddons)

- (BOOL)inviteContact:(AIListObject *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage {
    return NO;
}

@end

@implementation SmackXMPPService (MultiUserChatAddons)

- (BOOL)canCreateGroupChats {
    return YES;
}

- (DCJoinChatViewController *)joinChatView{
    return [SmackXMPPJoinChatViewController joinChatView];
    return nil;
}

@end

@interface SmackXMPPChat : AIObject {
    SmackXMultiUserChat *chat;
    SmackXMPPAccount *account;
    AIChat *adiumchat;
    
    NSMutableDictionary *participants;
}

- (id)initWithMultiUserChat:(SmackXMultiUserChat*)muc account:(SmackXMPPAccount*)a;
- (void)joinWithNickname:(NSString*)nickname password:(NSString*)password listener:(SmackXMPPMultiUserChatPluginListener*)listener;

- (void)postStatusMessage:(NSString*)fmt, ...;

@end

@implementation SmackXMPPChat

- (id)initWithMultiUserChat:(SmackXMultiUserChat*)muc account:(SmackXMPPAccount*)a {
    if((self = [super init])) {
        account = a;
        chat = [muc retain];
        participants = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [chat release];
    [participants release];
    [super dealloc];
}

- (void)joinWithNickname:(NSString*)nickname password:(NSString*)password chat:(AIChat*)achat listener:(SmackXMPPMultiUserChatPluginListener*)listener {
    adiumchat = achat;

    [listener listenToChat:chat :self];
    if(password)
        [chat join:nickname :password];
    else
        [chat join:nickname];
    
    SmackXMPPFormController *fc = [[SmackXMPPFormController alloc] initWithForm:[chat getRegistrationForm]];
    // ###
}


- (void)postStatusMessage:(NSString*)fmt, ... {
    va_list ap;
    NSString *message;
    
    va_start(ap, fmt);
    message = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    
    AILog(@"Chat message: %@",message);
    // XXX this is wrong -- group chat rewrite
    
    [message release];
}

- (void)setMUCInvitationDeclined:(NSDictionary*)info {
    if([info objectForKey:@"reason"] && [[info objectForKey:@"reason"] length] > 0)
        [self postStatusMessage:AILocalizedString(@"%@ declined your invitation with the reason \"%@\".","%@ declined your invitation with the reason \"%@\"."),[info objectForKey:@"invitee"],[info objectForKey:@"reason"]];
    else
        [self postStatusMessage:AILocalizedString(@"%@ declined your invitation.","%@ declined your invitation."),[info objectForKey:@"invitee"]];
}

- (void)setMUCMessage:(SmackPacket*)packet {
    AIContentMessage	*messageObject;
    NSAttributedString  *inMessage = nil;
    NSString *from = [packet getFrom];
    NSString *nickname = [from jidResource];
    AIListContact *user = [participants objectForKey:nickname];
    
    if(!user)
        return; // message from unknown user
    
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
            inMessage = [[NSAttributedString alloc] initWithHTML:[[NSString stringWithFormat:@"<html>%@</html>",htmlmsg] dataUsingEncoding:NSUnicodeStringEncoding]
                                                         options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnicodeStringEncoding] forKey:NSCharacterEncodingDocumentOption]
                                              documentAttributes:NULL];
        }
    }
    if(!inMessage)
        inMessage = [[NSAttributedString alloc] initWithString:[packet getBody] attributes:nil];
    
    SmackXDelayInformation *delayinfo = [packet getExtension:@"x" :@"jabber:x:delay"];
    NSDate *date = nil;
    if(delayinfo)
        date = [NSDate dateWithTimeIntervalSince1970:[[delayinfo getStamp] getTime]];
    else
        date = [NSDate date];
    
    messageObject = [AIContentMessage messageInChat:adiumchat
                                         withSource:user
                                        destination:account
                                               date:date
                                            message:inMessage
                                          autoreply:NO];
    [inMessage release];
    
    [[adium contentController] receiveContentObject:messageObject];
}

- (void)setMUCParticipant:(SmackPacket*)packet {
    NSLog(@"MUCParticipant:\n%@",[packet toXML]);
}

- (void)setMUCJoined:(NSString*)participant {
    AIListContact *contact = [[adium contactController] contactWithService:[account service]
                                                                   account:account
                                                                       UID:[NSString stringWithFormat:@"%@/%@",[chat getRoom],participant]];
    [contact setDisplayName:participant];
    [participants setObject:contact forKey:participant];
    
    [adiumchat addParticipatingListObject:contact];
}

- (void)setMUCLeft:(NSString*)participant {
    AIListContact *contact = [participants objectForKey:participant];
    if(contact) {
        [adiumchat removeParticipatingListObject:contact];
        [participants removeObjectForKey:participant];
    }
}

- (void)setMUCKicked:(NSDictionary*)info {
    NSString *participant = [info objectForKey:@"participant"];
    [self postStatusMessage:AILocalizedString(@"%@ was kicked by %@ (%@).","%@ was kicked by %@ (%@)."), participant, [info objectForKey:@"actor"],[info objectForKey:@"reason"]];

    AIListContact *contact = [participants objectForKey:participant];
    if(contact) {
        [adiumchat removeParticipatingListObject:contact];
        [participants removeObjectForKey:participant];
    }
}

- (void)setMUCVoiceGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ was granted voice.","%@ was granted voice."),participant];
}

- (void)setMUCVoiceRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ has been silenced.","%@ has been silenced."),participant];
}

- (void)setMUCBanned:(NSDictionary*)info {
    NSString *participant = [info objectForKey:@"participant"];
    [self postStatusMessage:AILocalizedString(@"%@ was banned by %@ (%@).","%@ was banned by %@ (%@)."), participant, [info objectForKey:@"actor"],[info objectForKey:@"reason"]];
    
    AIListContact *contact = [participants objectForKey:participant];
    if(contact) {
        [adiumchat removeParticipatingListObject:contact];
        [participants removeObjectForKey:participant];
    }
}

- (void)setMUCMembershipGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ was granted membership.","%@ was granted membership."),participant];
}

- (void)setMUCMembershipRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"The membership of %@ was revoked.","The membership of %@ was revoked."),participant];
}

- (void)setMUCModeratorGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is now moderator.","%@ is now moderator."),participant];
}

- (void)setMUCModeratorRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is no longer moderator.","%@ is no longer moderator."),participant];
}

- (void)setMUCOwnershipGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is now owner of this chatroom.","%@ is now owner of this chatroom."),participant];
}

- (void)setMUCOwnershipRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is no longer owner of this chatroom.","%@ is no longer owner of this chatroom."),participant];
}

- (void)setMUCAdminGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is now admin of this chatroom.","%@ is now admin of this chatroom."),participant];
}

- (void)setMUCAdminRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is no longer admin of this chatroom.","%@ is no longer admin of this chatroom."),participant];
}

- (void)setMUCNicknameChanged:(NSDictionary*)info {
    NSString *participant = [info objectForKey:@"participant"];
    NSString *newNickname = [info objectForKey:@"newNickname"];
    [self postStatusMessage:AILocalizedString(@"%@ is now known as %@.","%@ is now known as %@."),participant,newNickname];

    AIListContact *contact = [participants objectForKey:participant];
    if(contact) {
        // XXX way to rename a contact?
        
        [adiumchat removeParticipatingListObject:contact];
        [participants removeObjectForKey:participant];

        contact = [[adium contactController] contactWithService:[account service]
                                                        account:account
                                                            UID:[NSString stringWithFormat:@"%@/%@",[chat getRoom],newNickname]];
        
        [contact setDisplayName:newNickname];
        [participants setObject:contact forKey:newNickname];
        
        [adiumchat addParticipatingListObject:contact];
    }
}

- (void)setMUCSubjectUpdated:(NSDictionary*)info {
    [self postStatusMessage:AILocalizedString(@"%@ changed the subject to \"%@\".",@"%@ changed the topic to \"%@\"."),[info objectForKey:@"from"],[info objectForKey:@"subject"]];
    [adiumchat setDisplayName:[NSString stringWithFormat:@"%@: %@",[chat getRoom],[info objectForKey:@"subject"]]];
}

- (void)setMUCUserKicked:(NSDictionary*)info {
    [[NSAlert alertWithMessageText:[NSString stringWithFormat:AILocalizedString(@"You were kicked from the chatroom %@ by %@!","You were kicked from the chatroom %@ by %@!"), [chat getRoom],[info objectForKey:@"actor"]]
                     defaultButton:AILocalizedString(@"OK","OK")
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:@"%@",[info objectForKey:@"reason"]] runModal];
    [adiumchat setIsOpen:NO];
}

- (void)setMUCUserVoice:(BOOL)flag {
    if(flag)
        [self postStatusMessage:AILocalizedString(@"You were given voice.","You were given voice.")];
    else
        [self postStatusMessage:AILocalizedString(@"You were silenced.","You were silenced.")];
}

- (void)setMUCUserBanned:(NSDictionary*)info {
    [[NSAlert alertWithMessageText:[NSString stringWithFormat:AILocalizedString(@"You were banned from the chatroom %@ by %@!","You were banned from the chatroom %@ by %@!"), [chat getRoom],[info objectForKey:@"actor"]]
                     defaultButton:AILocalizedString(@"OK","OK")
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:@"%@",[info objectForKey:@"reason"]] runModal];
    [adiumchat setIsOpen:NO];
}

- (void)setMUCUserMembership:(BOOL)flag {
    if(flag)
        [self postStatusMessage:AILocalizedString(@"You are now a member.","You are now a member.")];
    else
        [self postStatusMessage:AILocalizedString(@"You are no longer a member.","You are no longer a member.")];
}

- (void)setMUCUserModerator:(BOOL)flag {
    if(flag)
        [self postStatusMessage:AILocalizedString(@"You are now a moderator.","You are now a moderator.")];
    else
        [self postStatusMessage:AILocalizedString(@"You are no longer a moderator.","You are no longer a moderator.")];
}

- (void)setMUCUserOwnership:(BOOL)flag {
    if(flag)
        [self postStatusMessage:AILocalizedString(@"You are now an owner.","You are now an owner.")];
    else
        [self postStatusMessage:AILocalizedString(@"You are no longer an owner.","You are no longer an owner.")];
}

- (void)setMUCUserAdmin:(BOOL)flag {
    if(flag)
        [self postStatusMessage:AILocalizedString(@"You are now an admin.","You are now an admin.")];
    else
        [self postStatusMessage:AILocalizedString(@"You are no longer an admin.","You are no longer an admin.")];
}

@end

@implementation SmackXMPPMultiUserChatPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a {
    if((self = [super init])) {
        account = a;
        listener = [[SmackCocoaAdapter MUCPluginListenerWithConnection:[account connection]] retain];
        [listener setDelegate:self];
        mucs = [[NSMutableDictionary alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(joinMultiUserChat:)
                                                     name:SmackXMPPJoinChatNotification
                                                   object:account];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [listener release];
    [mucs release];
    
    [super dealloc];
}

- (void)setMUCInvitation:(NSDictionary*)info {
    SmackXMPPConnection *conn = [info objectForKey:@"connection"];
    
    
    NSLog(@"MUC invite!");
}

- (void)joinMultiUserChat:(NSNotification*)notification {
    SmackXMPPConnection *conn = (id)[[notification object] connection];
    NSDictionary *info = [notification userInfo];
    NSString *server = [info objectForKey:@"server"];
    NSString *room = [info objectForKey:@"chatroom"];
    NSString *nickname = [info objectForKey:@"nickname"];
    NSString *password = [info objectForKey:@"password"];
    
    SmackXMultiUserChat *chat = [SmackCocoaAdapter joinMultiUserChatWithName:[NSString stringWithFormat:@"%@@%@", room, server] connection:conn];
    SmackXMPPChat *handle = [[SmackXMPPChat alloc] initWithMultiUserChat:chat account:account];
    [mucs setObject:handle forKey:[NSValue valueWithNonretainedObject:chat]];

    [handle joinWithNickname:nickname password:([password length]>0)?password:nil chat:[info objectForKey:@"chat"] listener:listener];
    
    [handle release];
}

@end
