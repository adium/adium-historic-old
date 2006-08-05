//
//  SmackXMPPFileTransferPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-21.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPFileTransferPlugin.h"
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import "ESFileTransferController.h"
#import "AIContactController.h"

#import "SmackInterfaceDefinitions.h"
#import "SmackCocoaAdapter.h"
#import "SmackListContact.h"

#import <JavaVM/NSJavaVirtualMachine.h>
#import <AIUtilities/AIStringUtilities.h>
#import "ESFileTransfer.h"

#define SmackXMPPSendFileTransfer @"SmackXMPPSendFileTransfer"

@interface SmackXMPPFileTransferListener : NSObject {
}

- (SmackXOutgoingFileTransfer*)createOutgoingFileTransfer:(NSString*)userID;

@end

@interface SmackCocoaAdapter (fileTransferPlugin)

+ (SmackXMPPFileTransferListener*)fileTransferListenerWithConnection:(SmackXMPPConnection*)conn andDelegate:(id)delegate;

@end

@implementation SmackCocoaAdapter (fileTransferPlugin)

+ (SmackXMPPFileTransferListener*)fileTransferListenerWithConnection:(SmackXMPPConnection*)conn andDelegate:(id)delegate
{
    return [[[[self classLoader] loadClass:@"net.adium.smackBridge.SmackXMPPFileTransferListener"] newWithSignature:@"(Lorg/jivesoftware/smack/XMPPConnection;Lcom/apple/cocoa/foundation/NSObject;)",conn,delegate] autorelease];
}

@end

@implementation SmackXMPPAccount (fileTransferExtension)

- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact {
    return ![inContact isKindOfClass:[SmackListContact class]] && [inType isEqualToString:CONTENT_FILE_TRANSFER_TYPE];
}

- (BOOL)canSendFolders
{
    return NO;
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    SmackXFileTransferRequest *request = [fileTransfer accountData];
    SmackXIncomingFileTransfer *smackFileTransfer = [request accept];
    
    [smackFileTransfer receiveFile:[SmackCocoaAdapter fileFromPath:[fileTransfer localFilename]]];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(updateFileTransferStatus:)
                                                    userInfo:[NSDictionary dictionaryWithObject:fileTransfer forKey:@"fileTransfer"]
                                                     repeats:YES];
    
    [fileTransfer setAccountData:[NSDictionary dictionaryWithObjectsAndKeys:
        smackFileTransfer, @"smackFileTransfer",
        timer, @"Timer",
        nil]];
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    SmackXFileTransferRequest *request = [fileTransfer accountData];
    [request reject];
}

- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPSendFileTransfer
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:fileTransfer forKey:@"fileTransfer"]];
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
    SmackXIncomingFileTransfer *smackFileTransfer = [[fileTransfer accountData] objectForKey:@"smackFileTransfer"];
    NSTimer *timer = [[fileTransfer accountData] objectForKey:@"Timer"];
    
    [smackFileTransfer cancel];
    [timer invalidate];
    [fileTransfer setStatus:Cancelled_Local_FileTransfer];
}

- (void)updateFileTransferStatus:(NSTimer*)timer
{
    ESFileTransfer *fileTransfer = [[timer userInfo] objectForKey:@"fileTransfer"];
    SmackXIncomingFileTransfer *smackFileTransfer = [[fileTransfer accountData] objectForKey:@"smackFileTransfer"];
    
    [fileTransfer setPercentDone:[smackFileTransfer getProgress]*100.0 bytesSent:[smackFileTransfer getAmountWritten]];
    
    if([smackFileTransfer isDone])
    {
        [timer invalidate];
        [fileTransfer setStatus:Complete_FileTransfer];
    } else {
        NSString *status = [[smackFileTransfer getStatus] toString];
        NSLog(@"file transfer status = %@",status);
        if([status isEqualToString:@"Cancled"])
        {
            [fileTransfer setStatus:Cancelled_Remote_FileTransfer];
            [timer invalidate];
        } else if([status isEqualToString:@"Error"])
        {
            [fileTransfer setStatus:Failed_FileTransfer];
            [timer invalidate];
        } else if([status isEqualToString:@"In Progress"])
            [fileTransfer setStatus:In_Progress_FileTransfer];
        else if([status isEqualToString:@"Initial"])
            [fileTransfer setStatus:Not_Started_FileTransfer];
        else if([status isEqualToString:@"Negotiated"])
            [fileTransfer setStatus:Accepted_FileTransfer];
        else if([status isEqualToString:@"Negotiating Stream"])
            [fileTransfer setStatus:Connecting_FileTransfer];
        else if([status isEqualToString:@"Negotiating Transfer"])
            [fileTransfer setStatus:Connecting_FileTransfer];
        else if([status isEqualToString:@"Refused"])
            [fileTransfer setStatus:Cancelled_Remote_FileTransfer];
        else
            [fileTransfer setStatus:Unknown_Status_FileTransfer];
    }
}

@end

@implementation SmackXMPPFileTransferPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a {
    if((self = [super init])) {
        account = a;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(initiateFileTransfer:)
                                                     name:SmackXMPPSendFileTransfer
                                                   object:account];
    }
    return self;
}

- (void)initiateFileTransfer:(NSNotification*)n
{
    ESFileTransfer *fileTransfer = [[n userInfo] objectForKey:@"fileTransfer"];
    AIListContact *contact = [fileTransfer contact];
    
    NSLog(@"file transfer inital contact %@ (%p)",contact,contact);
    
    while([contact conformsToProtocol:@protocol(AIContainingObject)])
        contact = [contact preferredContact];
    if(!contact)
        return; // not online?
    
    NSLog(@"file transfer file = %@, jid = %@",[fileTransfer localFilename],[fileTransfer contact]);
    
    SmackXOutgoingFileTransfer *smackFileTransfer = [listener createOutgoingFileTransfer:[contact UID]];
    [smackFileTransfer sendFile:[SmackCocoaAdapter fileFromPath:[fileTransfer localFilename]] :[fileTransfer displayFilename]];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:account
                                                    selector:@selector(updateFileTransferStatus:)
                                                    userInfo:[NSDictionary dictionaryWithObject:fileTransfer forKey:@"fileTransfer"]
                                                     repeats:YES];
    
    [fileTransfer setAccountData:[NSDictionary dictionaryWithObjectsAndKeys:
        smackFileTransfer, @"smackFileTransfer",
        timer, @"Timer",
        nil]];
}

- (void)connected:(SmackXMPPConnection*)conn
{
    listener = [[SmackCocoaAdapter fileTransferListenerWithConnection:conn andDelegate:self] retain];
}

- (void)disconnected:(SmackXMPPConnection*)conn
{
    [listener release];
}

- (void)setFileTransferRequest:(SmackXFileTransferRequest*)request
{
    ESFileTransfer *fileTransfer = [[adium fileTransferController] newFileTransferWithContact:[[adium contactController] contactWithService:[account service] account:account UID:[request getRequestor]] forAccount:account type:Incoming_FileTransfer];
    
    [fileTransfer setRemoteFilename:[request getFileName]];
    [fileTransfer setSize:[request getFileSize]];
    [fileTransfer setAccountData:request];
    
    [[adium fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}

@end
