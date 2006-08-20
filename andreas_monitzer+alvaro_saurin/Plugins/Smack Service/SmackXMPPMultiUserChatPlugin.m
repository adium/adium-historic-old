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
#import <Adium/AIContentMessage.h>
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
    return [[[[self classLoader] loadClass:@"net.adium.smackBridge.SmackXMPPMultiUserChatPluginListener"] newWithSignature:@"(Lorg/jivesoftware/smack/XMPPConnection;)",conn] autorelease];
}

+ (SmackXMultiUserChat*)joinMultiUserChatWithName:(NSString*)name connection:(SmackXMPPConnection*)conn {
    return [[[[self classLoader] loadClass:@"org.jivesoftware.smackx.muc.MultiUserChat"] newWithSignature:@"(Lorg/jivesoftware/smack/XMPPConnection;Ljava/lang/String;)",conn,name] autorelease];
}

@end

#define SmackXMPPJoinChatNotification @"SmackXMPPJoinChatNotification"


@implementation SmackXMPPJoinChatViewController

- (void)setJID:(NSString*)jid
{
    [chatRoomNameField setStringValue:[jid jidUsername]];
    [serverField setStringValue:[jid jidHost]];
    [nicknameField setStringValue:[jid jidResource]];
}

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
}

@end

@interface SmackXMPPChat : AIObject {
    SmackXMultiUserChat *chat;
    SmackXMPPAccount *account;
    AIChat *adiumchat;
    
    NSMutableDictionary *participants;
    BOOL initialUpdateDone;
    
    NSString *ownAffiliation;
    NSString *ownRole;
    
    IBOutlet NSPanel *changenickname_window;
    IBOutlet NSTextField *changenickname_textfield;
    IBOutlet NSButton *changenickname_setbutton;

    IBOutlet NSPanel *changesubject_window;
    IBOutlet NSTextView *changesubject_textview;
    IBOutlet NSButton *changesubject_setbutton;
}

- (id)initWithMultiUserChat:(SmackXMultiUserChat*)muc account:(SmackXMPPAccount*)a;
- (void)joinWithNickname:(NSString*)nickname password:(NSString*)password chat:(AIChat*)achat listener:(SmackXMPPMultiUserChatPluginListener*)listener;

- (void)postStatusMessage:(NSString*)fmt, ...;

- (NSString*)ownAffiliation;
- (NSString*)ownRole;

- (IBAction)changeNickname_Set:(id)sender;
- (IBAction)changeNickname_Cancel:(id)sender;

- (IBAction)changeSubject_Set:(id)sender;
- (IBAction)changeSubject_Cancel:(id)sender;

@end

@implementation SmackXMPPChat

- (id)initWithMultiUserChat:(SmackXMultiUserChat*)muc account:(SmackXMPPAccount*)a {
    if((self = [super init])) {
        account = a;
        chat = [muc retain];
        participants = [[NSMutableDictionary alloc] init];
        
/*        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedMessagePacket:)
                                                     name:SmackXMPPMessagePacketReceivedNotification
                                                   object:a];*/
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendMessage:)
                                                     name:SmackXMPPMessageSentNotification
                                                   object:a];
    }
    return [self retain];
}

- (void)dealloc {
    [chat release];
    [participants release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[adium notificationCenter] removeObserver:self];
    [ownAffiliation release];
    [ownRole release];
    [super dealloc];
}

- (NSString*)ownAffiliation {
    return ownAffiliation;
}

- (NSString*)ownRole {
    return ownRole;
}

- (void)joinWithNickname:(NSString*)nickname password:(NSString*)password chat:(AIChat*)achat listener:(SmackXMPPMultiUserChatPluginListener*)listener {
    adiumchat = achat;

    [listener listenToChat:chat :self];
    if(password)
        [chat join:nickname :password];
    else
        [chat join:nickname];
    
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(chatWillClose:)
                                       name:Chat_WillClose
                                     object:adiumchat];
}

- (void)chatWillClose:(NSNotification*)n
{
    [chat leave];
    [self release]; // retained in -initWithMultiUserChat:account:
}

- (void)registerUser:(NSMenuItem*)menuItem
{
    @try {
        [[SmackXMPPFormController alloc] initWithForm:[chat getRegistrationForm] target:self selector:@selector(sendRegistrationForm:) webView:nil registered:NO];
    } @catch (NSException *e) {
        // not allowed to get configuration form
        [self postStatusMessage:AILocalizedString(@"Error Getting the User Registration Form: %@",@"Error Getting the User Registration Form: %@"), [e reason]];
    }
}

- (void)sendRegistrationForm:(SmackXMPPFormController*)fc {
    [chat sendRegistrationForm:[fc resultForm]];
    
    [fc release];
}

- (void)configureRoom:(NSMenuItem*)menuItem
{
    @try {
        [[SmackXMPPFormController alloc] initWithForm:[chat getConfigurationForm] target:self selector:@selector(sendConfigurationForm:) webView:nil registered:NO];
    } @catch (NSException *e) {
        // not allowed to get configuration form
        [self postStatusMessage:AILocalizedString(@"Error Getting the Room Configuration Form: %@",@"Error Getting the Room Configuration Form: %@"), [e reason]];
    }
}

- (void)sendConfigurationForm:(SmackXMPPFormController*)fc {
    [chat sendConfigurationForm:[fc resultForm]];
    
    [fc release];
}

- (void)postStatusMessage:(NSString*)fmt, ... {
    va_list ap;
    NSString *message;
    
    va_start(ap, fmt);
    message = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    
    [self performSelectorOnMainThread:@selector(displayStatusMessage:) withObject:message waitUntilDone:YES];
    
    [message release];
}

- (void)displayStatusMessage:(NSString*)message
{
    [[adium contentController] displayEvent:message
                                     ofType:@"chat-info"
                                     inChat:adiumchat];
}

- (void)setMUCInvitationDeclined:(NSDictionary*)info {
    if([info objectForKey:@"reason"] && [[info objectForKey:@"reason"] length] > 0)
        [self postStatusMessage:AILocalizedString(@"%@ declined your invitation with the reason \"%@\".","%@ declined your invitation with the reason \"%@\"."),[info objectForKey:@"invitee"],[info objectForKey:@"reason"]];
    else
        [self postStatusMessage:AILocalizedString(@"%@ declined your invitation.","%@ declined your invitation."),[info objectForKey:@"invitee"]];
}

- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
    NSMutableArray *menuItems = [NSMutableArray array];
    BOOL isMe = [[[inContact UID] jidResource] isEqualToString:[chat getNickname]];
    NSString *role = [inContact statusObjectForKey:@"XMPPMUCRole"];
    NSString *affiliation = [inContact statusObjectForKey:@"XMPPMUCAffiliation"];
    NSString *jid = [inContact statusObjectForKey:@"XMPPMUCJID"];
    NSString *nick = [[inContact UID] jidResource];
    
    NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Role: %@","Role: %@"),role] action:NULL keyEquivalent:@""];
    [menuItems addObject:mitem];
    [mitem release];
    
    mitem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Affiliation: %@","Affiliation: %@"),affiliation] action:NULL keyEquivalent:@""];
    [menuItems addObject:mitem];
    [mitem release];
    
    [menuItems addObject:[NSMenuItem separatorItem]];
    
    if([ownRole isEqualToString:@"moderator"])
    {
        if(!isMe)
        {
            mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Kick User","Kick User") action:@selector(kickUser:) keyEquivalent:@""];
            [mitem setTarget:self];
            [mitem setRepresentedObject:inContact];
            [menuItems addObject:mitem];
            [mitem release];

            if([role isEqualToString:@"visitor"])
            {
                mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Grant Voice","Grant Voice") action:@selector(changeUserState:) keyEquivalent:@""];
                [mitem setTarget:self];
                [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    nick, @"contact",
                    @"grantVoice", @"action",
                    nil]];
                [menuItems addObject:mitem];
                [mitem release];
            } else {
                mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Revoke Voice","Revoke Voice") action:@selector(changeUserState:) keyEquivalent:@""];
                [mitem setTarget:self];
                [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    nick, @"contact",
                    @"revokeVoice", @"action",
                    nil]];
                [menuItems addObject:mitem];
                [mitem release];
            }

        }
    }
    if(isMe)
    {
        mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Change Nickname...","Change Nickname...") action:@selector(changeNickname:) keyEquivalent:@""];
        [mitem setTarget:self];
        [menuItems addObject:mitem];
        [mitem release];
        
        
        mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Set Subject...","Set Subject...") action:@selector(changeSubject:) keyEquivalent:@""];
        [mitem setTarget:self];
        [menuItems addObject:mitem];
        [mitem release];
        
        // setting the subject might not be allowed in the room, but we'll never know unless we try
        
        [menuItems addObject:[NSMenuItem separatorItem]];
        
        mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Room Configuration...","Room Configuration...") action:@selector(configureRoom:) keyEquivalent:@""];
        [mitem setTarget:self];
        [menuItems addObject:mitem];
        [mitem release];

        mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"User Registration...","User Registration...") action:@selector(registerUser:) keyEquivalent:@""];
        [mitem setTarget:self];
        [menuItems addObject:mitem];
        [mitem release];
    }
    if([ownAffiliation isEqualToString:@"admin"] || [ownAffiliation isEqualToString:@"owner"])
    {
        if(!isMe)
        {
            mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Ban User","Ban User") action:@selector(banUser:) keyEquivalent:@""];
            [mitem setTarget:self];
            [mitem setRepresentedObject:inContact];
            [menuItems addObject:mitem];
            [mitem release];
            
            if([role isEqualToString:@"moderator"]) {
                mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Revoke Moderator Privileges","Revoke Moderator Privileges") action:@selector(changeUserState:) keyEquivalent:@""];
                [mitem setTarget:self];
                [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    nick, @"contact",
                    @"revokeModerator", @"action",
                    nil]];
                [menuItems addObject:mitem];
                [mitem release];
            } else {
                mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Grant Moderator Privileges","Grant Moderator Privileges") action:@selector(changeUserState:) keyEquivalent:@""];
                [mitem setTarget:self];
                [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    nick, @"contact",
                    @"grantModerator", @"action",
                    nil]];
                [menuItems addObject:mitem];
                [mitem release];
            }
            if([affiliation isEqualToString:@"none"] || ([ownAffiliation isEqualToString:@"owner"] && !([affiliation isEqualToString:@"owner"] && [affiliation isEqualToString:@"member"])))
            {
                mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Grant Membership","Grant Membership") action:@selector(changeUserState:) keyEquivalent:@""];
                [mitem setTarget:self];
                [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    jid, @"contact",
                    @"grantMembership", @"action",
                    nil]];
                [menuItems addObject:mitem];
                [mitem release];
            } else if([affiliation isEqualToString:@"member"])
            {
                mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Revoke Membership","Revoke Membership") action:@selector(changeUserState:) keyEquivalent:@""];
                [mitem setTarget:self];
                [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                    jid, @"contact",
                    @"revokeMembership", @"action",
                    nil]];
                [menuItems addObject:mitem];
                [mitem release];
            }
            if([ownAffiliation isEqualToString:@"owner"])
            {
                if([affiliation isEqualToString:@"admin"])
                {
                    mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Revoke Admin Privileges","Revoke Admin Privileges") action:@selector(changeUserState:) keyEquivalent:@""];
                    [mitem setTarget:self];
                    [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        jid, @"contact",
                        @"revokeAdmin", @"action",
                        nil]];
                    [menuItems addObject:mitem];
                    [mitem release];
                } else if(![affiliation isEqualToString:@"owner"]) {
                    mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Grant Admin Privileges","Grant Admin Privileges") action:@selector(changeUserState:) keyEquivalent:@""];
                    [mitem setTarget:self];
                    [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        jid, @"contact",
                        @"grantAdmin", @"action",
                        nil]];
                    [menuItems addObject:mitem];
                    [mitem release];
                }
                if([affiliation isEqualToString:@"owner"])
                {
                    mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Revoke Ownership","Revoke Ownership") action:@selector(changeUserState:) keyEquivalent:@""];
                    [mitem setTarget:self];
                    [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        jid, @"contact",
                        @"revokeOwnership", @"action",
                        nil]];
                    [menuItems addObject:mitem];
                    [mitem release];
                } else {
                    mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Grant Ownership","Grant Ownership") action:@selector(changeUserState:) keyEquivalent:@""];
                    [mitem setTarget:self];
                    [mitem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        jid, @"contact",
                        @"grantOwnership", @"action",
                        nil]];
                    [menuItems addObject:mitem];
                    [mitem release];
                }
            }
        } else {
            if([ownAffiliation isEqualToString:@"owner"]) {
                mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Destroy Room","Destroy Room") action:@selector(destroyRoom:) keyEquivalent:@""];
                [mitem setTarget:self];
                [menuItems addObject:mitem];
                [mitem release];
            }
        }
    }
    
    return menuItems;
}

#pragma mark Receiving Chat Messages

- (void)setMUCMessage:(SmackPacket*)packet {
    AIContentMessage	*messageObject;
    NSAttributedString  *inMessage = nil;
    NSString *from = [packet getFrom];
    NSString *nickname = [from jidResource];
    
    if([nickname length] == 0) // server message?
    {
        [self postStatusMessage:@"%@",[packet getBody]];
        return;
    }
    
    if([nickname isEqualToString:[chat getNickname]])
        return; // ignore messages from self
    
    AIListContact *user = [participants objectForKey:from];

    if(!user)
    {
        // this user is no longer online, just create him temporarily
        user = [[adium contactController] contactWithService:[account service]
                                                     account:account
                                                         UID:from];
        [user setDisplayName:[from jidResource]];
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
    
    messageObject = [AIContentMessage messageInChat:adiumchat
                                         withSource:user
                                        destination:account
                                               date:date
                                            message:inMessage
                                          autoreply:NO];
    [inMessage release];
    
    [[adium contentController] performSelectorOnMainThread:@selector(receiveContentObject:) withObject:messageObject waitUntilDone:NO];
}

- (void)convertToAttributedString:(NSMutableDictionary*)param
{
    [param setObject:[[[NSAttributedString alloc] initWithHTML:[param objectForKey:@"htmldata"]
                                                 options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnicodeStringEncoding] forKey:NSCharacterEncodingDocumentOption]
                                           documentAttributes:NULL] autorelease] forKey:@"result"];
}

#pragma mark Actions Initiated by the Local User

- (void)sendMessage:(NSNotification*)n
{
//    SmackXMPPAccount *account = [n object];
    AIContentMessage *inMessageObject = [[n userInfo] objectForKey:AIMessageObjectKey];
    SmackMessage *message = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    if([inMessageObject chat] != adiumchat)
        return; // ignore foreign messages

    [message setTo:[chat getRoom]];
    [message setType:[SmackCocoaAdapter messageTypeFromString:@"GROUP_CHAT"]];
    
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

- (void)kickUser:(NSMenuItem*)sender {
    AIListContact *contact = [sender representedObject];
    
    @try {
        [chat kickParticipant:[[contact UID] jidResource] :@""];
    } @catch(NSException *e) {
        [self postStatusMessage:AILocalizedString(@"Error Kicking User %@: %@","Error Kicking User %@: %@"),[[contact UID] jidResource], [e reason]];
    }
}

- (void)banUser:(NSMenuItem*)sender {
    AIListContact *contact = [sender representedObject];
    
    @try {
        [chat banUser:[[contact UID] jidResource] :@""];
    } @catch(NSException *e) {
        [self postStatusMessage:AILocalizedString(@"Error Banning User %@: %@","Error Banning User %@: %@"),[[contact UID] jidResource], [e reason]];
    }
}

- (void)changeSubject:(NSMenuItem*)sender {
    [NSBundle loadNibNamed:@"SmackXMPPMUCChangeSubject" owner:self];
    if(!changesubject_window)
    {
        NSBeep();
        return;
    }
    NSString *subject = [chat getSubject];
    [changesubject_textview setString:subject?subject:@""];
    
    [NSApp beginSheet:changesubject_window
       modalForWindow:[[adium interfaceController] windowForChat:adiumchat]
        modalDelegate:self
       didEndSelector:@selector(changeSubject_sheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)changeSubject_Set:(id)sender
{
    [NSApp endSheet:changesubject_window
         returnCode:NSOKButton];
}

- (IBAction)changeSubject_Cancel:(id)sender
{
    [NSApp endSheet:changesubject_window
         returnCode:NSCancelButton];
}

- (void)changeSubject_sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)ctx
{
    NSString *subject = [[changesubject_textview string] retain];
    [sheet orderOut:nil];
    [sheet close];
    if(returnCode == NSOKButton)
    {
        @try {
            [chat changeSubject:subject];
        } @catch(NSException *e) {
            [self postStatusMessage:AILocalizedString(@"Error changing the subject to \"%@\": %@","Error changing the subject to \"%@\": %@"), subject, [e reason]];
        }
    }
    [subject release];
}

- (void)changeNickname:(NSMenuItem*)sender {
    [NSBundle loadNibNamed:@"SmackXMPPMUCChangeNickname" owner:self];
    if(!changenickname_window)
    {
        NSBeep();
        return;
    }
    
    [changenickname_textfield setStringValue:[chat getNickname]];
    
    [NSApp beginSheet:changenickname_window
       modalForWindow:[[adium interfaceController] windowForChat:adiumchat]
        modalDelegate:self
       didEndSelector:@selector(changeNickname_sheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)changeNickname_Set:(id)sender
{
    [NSApp endSheet:changenickname_window
         returnCode:NSOKButton];
}

- (IBAction)changeNickname_Cancel:(id)sender
{
    [NSApp endSheet:changenickname_window
         returnCode:NSCancelButton];
}

- (void)changeNickname_sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)ctx
{
    NSString *nickname = [[changenickname_textfield stringValue] retain];
    [sheet orderOut:nil];
    [sheet close];
    if(returnCode == NSOKButton && [nickname length] > 0)
    {
        @try {
            [chat changeNickname:nickname];
        } @catch(NSException *e) {
            [self postStatusMessage:AILocalizedString(@"Error changing your nick to \"%@\": %@","Error changing your nick to \"%@\": %@"), nickname, [e reason]];
        }
    }
    [nickname release];
}

- (void)destroyRoom:(NSMenuItem*)sender {
    @try {
        [chat destroy:nil :nil];
        
        [[adium interfaceController] closeChat:adiumchat];
    } @catch(NSException *e) {
        [self postStatusMessage:AILocalizedString(@"Error Destroying Room: %@","Error Destroying Room: %@"), [e reason]];
    }
}

// generic action, since there are so many of them
- (void)changeUserState:(NSMenuItem*)sender
{
    NSDictionary *userInfo = [sender representedObject];
    NSString *contact = [userInfo objectForKey:@"contact"];
    NSString *action = [userInfo objectForKey:@"action"];
    
    @try {
        [SmackCocoaAdapter invokeObject:chat methodWithParamTypeAndParam:action, @"java.lang.String", contact, nil];
//        [chat performSelector:NSSelectorFromString(action) withObject:[[contact UID] jidResource]];
    } @catch(NSException *e) {
        [self postStatusMessage:AILocalizedString(@"Error Changing User State of %@: %@","Error Changing User State of %@: %@"),contact, [e reason]];
    }
}

#pragma mark Smack Callbacks

- (void)setMUCParticipant:(SmackPresence*)packet {
    [self performSelectorOnMainThread:@selector(setMUCParticipantMainThread:) withObject:packet waitUntilDone:NO];
}

- (void)setMUCParticipantMainThread:(SmackPresence*)packet {
    if([[[packet getType] toString] isEqualToString:@"unavailable"])
        return; // handle those in -setMUCLeft:
    
    NSString *participant = [packet getFrom];
    AIListContact *contact = [participants objectForKey:participant];
    NSString *nick = [participant jidResource];
    if(!contact)
    {
        contact = [[adium contactController] contactWithService:[account service]
                                                        account:account
                                                            UID:participant];
        [contact setDisplayName:nick];
        [participants setObject:contact forKey:participant];
        
        [contact setStatusObject:self forKey:@"XMPPMUCChat" notify:NotifyLater];
        
        [adiumchat addParticipatingListObject:contact notify:initialUpdateDone];

        if(!initialUpdateDone && [nick isEqualToString:[chat getNickname]])
            initialUpdateDone = YES;
    }
    SmackXOccupant *occupant = [chat getOccupant:participant];
    
    [contact setStatusObject:[occupant getJid] forKey:@"XMPPMUCJID" notify:NotifyLater];
    [contact setStatusObject:[occupant getRole] forKey:@"XMPPMUCRole" notify:NotifyLater];
    [contact setStatusObject:[occupant getAffiliation] forKey:@"XMPPMUCAffiliation" notify:NotifyLater];
    
    if([nick isEqualToString:[chat getNickname]]) { // is it us?
        [ownAffiliation release];
        [ownRole release];
        ownAffiliation = [[occupant getAffiliation] copy];
        ownRole = [[occupant getRole] copy];
    }

    //Apply any changes
	[contact notifyOfChangedStatusSilently:NO];
}

- (void)setMUCJoined:(NSString*)participant {
//    NSLog(@"participant joined %@",participant);
}

- (void)setMUCLeft:(NSString*)participant
{
    [self performSelectorOnMainThread:@selector(setMUCLeftMainThread:) withObject:participant waitUntilDone:NO];
}
    
- (void)setMUCLeftMainThread:(NSString*)participant
{
    AIListContact *contact = [participants objectForKey:participant];
    if(contact) {
        [adiumchat removeParticipatingListObject:contact];
        [participants removeObjectForKey:participant];
    }
}

- (void)setMUCKicked:(NSDictionary*)info
{
    [self performSelectorOnMainThread:@selector(setMUCKickedMainThread:) withObject:info waitUntilDone:NO];
}
    
- (void)setMUCKickedMainThread:(NSDictionary*)info
{
    NSString *participant = [info objectForKey:@"participant"];
    [self postStatusMessage:AILocalizedString(@"%@ was kicked by %@ (%@).","%@ was kicked by %@ (%@)."), [participant jidResource], [info objectForKey:@"actor"],[info objectForKey:@"reason"]];

    AIListContact *contact = [participants objectForKey:participant];
    if(contact) {
        [adiumchat removeParticipatingListObject:contact];
        [participants removeObjectForKey:participant];
    }
}

- (void)setMUCVoiceGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ was granted voice.","%@ was granted voice."),[participant jidResource]];
}

- (void)setMUCVoiceRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ has been silenced.","%@ has been silenced."),[participant jidResource]];
}

- (void)setMUCBanned:(NSDictionary*)info {
    NSString *participant = [info objectForKey:@"participant"];
    [self postStatusMessage:AILocalizedString(@"%@ was banned by %@ (%@).","%@ was banned by %@ (%@)."), [participant jidResource], [info objectForKey:@"actor"],[info objectForKey:@"reason"]];
    
    AIListContact *contact = [participants objectForKey:participant];
    if(contact) {
        [adiumchat removeParticipatingListObject:contact];
        [participants removeObjectForKey:participant];
    }
}

- (void)setMUCMembershipGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ was granted membership.","%@ was granted membership."),[participant jidResource]];
}

- (void)setMUCMembershipRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"The membership of %@ was revoked.","The membership of %@ was revoked."),[participant jidResource]];
}

- (void)setMUCModeratorGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is now moderator.","%@ is now moderator."),[participant jidResource]];
}

- (void)setMUCModeratorRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is no longer moderator.","%@ is no longer moderator."),[participant jidResource]];
}

- (void)setMUCOwnershipGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is now owner of this chatroom.","%@ is now owner of this chatroom."),[participant jidResource]];
}

- (void)setMUCOwnershipRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is no longer owner of this chatroom.","%@ is no longer owner of this chatroom."),[participant jidResource]];
}

- (void)setMUCAdminGranted:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is now admin of this chatroom.","%@ is now admin of this chatroom."),[participant jidResource]];
}

- (void)setMUCAdminRevoked:(NSString*)participant {
    [self postStatusMessage:AILocalizedString(@"%@ is no longer admin of this chatroom.","%@ is no longer admin of this chatroom."),[participant jidResource]];
}

- (void)setMUCNicknameChanged:(NSDictionary*)info
{
    [self performSelectorOnMainThread:@selector(setMUCNicknameChangedMainThread:) withObject:info waitUntilDone:NO];
}

- (void)setMUCNicknameChangedMainThread:(NSDictionary*)info
{
    NSString *participant = [info objectForKey:@"participant"];
    NSString *newNickname = [info objectForKey:@"newNickname"];
    [self postStatusMessage:AILocalizedString(@"%@ is now known as %@.","%@ is now known as %@."),[participant jidResource],newNickname];

    AIListContact *contact = [participants objectForKey:participant];
    if(contact) {
        // XXX clean/easy way to rename a contact?
        
//        [adiumchat removeParticipatingListObject:contact];
        [(NSMutableArray*)[adiumchat participatingListObjects] removeObject:contact]; // XXX uses a way not really recommended
        [participants removeObjectForKey:participant];

        contact = [[adium contactController] contactWithService:[account service]
                                                        account:account
                                                            UID:[NSString stringWithFormat:@"%@/%@",[chat getRoom],newNickname]];
        
        [contact setDisplayName:newNickname];

        SmackXOccupant *occupant = [chat getOccupant:participant];
        
        [contact setStatusObject:self forKey:@"XMPPMUCChat" notify:NotifyLater];
        [contact setStatusObject:[occupant getJid] forKey:@"XMPPMUCJID" notify:NotifyLater];
        [contact setStatusObject:[occupant getRole] forKey:@"XMPPMUCRole" notify:NotifyLater];
        [contact setStatusObject:[occupant getAffiliation] forKey:@"XMPPMUCAffiliation" notify:NotifyLater];

        [participants setObject:contact forKey:newNickname];
        
        [adiumchat addParticipatingListObject:contact notify:NO];
    }
}

- (void)setMUCSubjectUpdated:(NSDictionary*)info {
    [self postStatusMessage:AILocalizedString(@"%@ changed the subject to \"%@\".",@"%@ changed the topic to \"%@\"."),[[info objectForKey:@"from"] jidResource],[info objectForKey:@"subject"]];
    [adiumchat performSelectorOnMainThread:@selector(setDisplayName:) withObject:[NSString stringWithFormat:@"%@: %@",[chat getRoom],[info objectForKey:@"subject"]] waitUntilDone:NO];
}

- (void)setMUCUserKicked:(NSDictionary*)info {
    [[adium notificationCenter] postNotificationName:@"AIChatDidChangeCanSendMessagesNotification"
                                              object:adiumchat
                                            userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                                                 forKey:@"TypingEnabled"]];
    [self postStatusMessage:AILocalizedString(@"You were kicked by %@ (%@)","You were kicked by %@ (%@)"), [info objectForKey:@"actor"], [info objectForKey:@"reason"]];
}

- (void)setMUCUserVoice:(JavaBoolean*)flag {
    if([flag booleanValue])
    {
        [[adium notificationCenter] postNotificationName:@"AIChatDidChangeCanSendMessagesNotification"
                                                  object:adiumchat
                                                userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                                                     forKey:@"TypingEnabled"]];
        [self postStatusMessage:AILocalizedString(@"You were given voice.","You were given voice.")];
    } else {
        [[adium notificationCenter] postNotificationName:@"AIChatDidChangeCanSendMessagesNotification"
                                                  object:adiumchat
                                                userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                                     forKey:@"TypingEnabled"]];
        [self postStatusMessage:AILocalizedString(@"You were silenced.","You were silenced.")];
    }
}

- (void)setMUCUserBanned:(NSDictionary*)info {
    [[adium notificationCenter] postNotificationName:@"AIChatDidChangeCanSendMessagesNotification"
                                              object:adiumchat
                                            userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                                                 forKey:@"TypingEnabled"]];
    [self postStatusMessage:AILocalizedString(@"You were banned by %@ (%@)","You were banned by %@ (%@)"), [info objectForKey:@"actor"], [info objectForKey:@"reason"]];
}

- (void)setMUCUserMembership:(JavaBoolean*)flag {
    if([flag booleanValue])
        [self postStatusMessage:AILocalizedString(@"You are now a member.","You are now a member.")];
    else
        [self postStatusMessage:AILocalizedString(@"You are no longer a member.","You are no longer a member.")];
}

- (void)setMUCUserModerator:(JavaBoolean*)flag {
    if([flag booleanValue])
        [self postStatusMessage:AILocalizedString(@"You are now a moderator.","You are now a moderator.")];
    else
        [self postStatusMessage:AILocalizedString(@"You are no longer a moderator.","You are no longer a moderator.")];
}

- (void)setMUCUserOwnership:(JavaBoolean*)flag {
    if([flag booleanValue])
        [self postStatusMessage:AILocalizedString(@"You are now an owner.","You are now an owner.")];
    else
        [self postStatusMessage:AILocalizedString(@"You are no longer an owner.","You are no longer an owner.")];
}

- (void)setMUCUserAdmin:(JavaBoolean*)flag {
    if([flag booleanValue])
        [self postStatusMessage:AILocalizedString(@"You are now an admin.","You are now an admin.")];
    else
        [self postStatusMessage:AILocalizedString(@"You are no longer an admin.","You are no longer an admin.")];
}

@end

@implementation SmackXMPPMultiUserChatPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a {
    if((self = [super init])) {
        account = a;
        
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
    
    [super dealloc];
}

- (void)connected:(SmackXMPPConnection*)conn
{
    [listener release];
    listener = [[SmackCocoaAdapter MUCPluginListenerWithConnection:conn] retain];
    [listener setDelegate:self];
}

- (void)disconnected:(SmackXMPPConnection*)conn
{
    [listener release];
    listener = nil;
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
    
    SmackXMPPChat *handle = nil;
    @try {
        SmackXMultiUserChat *chat = [SmackCocoaAdapter joinMultiUserChatWithName:[NSString stringWithFormat:@"%@@%@", room, server] connection:conn];
        handle = [[SmackXMPPChat alloc] initWithMultiUserChat:chat account:account];
        
        [handle joinWithNickname:nickname password:([password length]>0)?password:nil chat:[info objectForKey:@"chat"] listener:listener];
    } @catch (NSException *e) {
        [[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"XMPP Error","XMPP Error")] withDescription:[e reason] withWindowTitle:AILocalizedString(@"Notice","Notice") defaultButton:AILocalizedString(@"OK","OK") alternateButton:nil otherButton:nil target:nil selector:NULL userInfo:nil];
        [[info objectForKey:@"chat"] receivedError:[NSNumber numberWithInt:AIChatCommandFailed]];
    }
    
    [handle release];
}

- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    SmackXMPPChat *chat = [inContact statusObjectForKey:@"XMPPMUCChat"];
    return [chat menuItemsForContact:(AIListContact *)inContact]; // might be nil target if this is not our contact
}

@end
