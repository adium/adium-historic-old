//
//  ESFileTransfer.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 13 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIObject.h"

#define FILE_TRANSFER_TYPE  @"File Transfer Type"

@protocol AIAccount_Files;

@class AIAccount, ESFileTransfer;

typedef enum {
	Unknown_FileTransfer = 0,
    Incoming_FileTransfer,
    Outgoing_FileTransfer,
} FileTransferType;

typedef enum {
	Unknown_Status_FileTransfer = 0,
	Not_Started_FileTransfer,		//File transfer is pending confirmation from a user, either local or remote
	Accepted_FileTransfer,			//Could also be called Began_FileTransfer or Started_FileTransfer
	In_Progress_FileTransfer,		//Currently transferring, not yet complete
	Complete_FileTransfer,			//File is complete; transferring is finished.
	Canceled_Local_FileTransfer,	//The local user canceled the transfer
	Canceled_Remote_FileTransfer	//The remote user canceled the transfer
} FileTransferStatus;

@protocol FileTransferDelegate
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetType:(FileTransferType)type;
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(FileTransferStatus)status;
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetSize:(unsigned long long)size;
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetLocalFilename:(NSString *)inLocalFilename;
-(void)gotUpdateForFileTransfer:(ESFileTransfer *)fileTransfer;
@end

@interface ESFileTransfer : AIObject {
    AIListContact				*contact;
    AIAccount<AIAccount_Files> 	*account;
    NSString					*localFilename;
    NSString					*remoteFilename;
    id							accountData;
    
    float						percentDone;
    unsigned long long			size;
    unsigned long long			bytesSent;
    FileTransferType			type;
	FileTransferStatus			status;
	
	id <FileTransferDelegate>   delegate;
}

+ (id)fileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount;
- (id)initWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount;

- (AIListContact *)contact;
- (AIAccount<AIAccount_Files> *)account;

- (void)setRemoteFilename:(NSString *)inRemoteFilename;
- (NSString *)remoteFilename;

- (void)setLocalFilename:(NSString *)inLocalFilename;
- (NSString *)localFilename;

- (void)setSize:(unsigned long long)inSize;
- (unsigned long long)size;

- (void)setType:(FileTransferType)inType;
- (FileTransferType)type;

- (void)setStatus:(FileTransferStatus)inStatus;
- (FileTransferStatus)status;

- (void)setPercentDone:(float)inPercent bytesSent:(unsigned int)inBytesSent;
- (float)percentDone;
- (unsigned long long)bytesSent;

- (void)setAccountData:(id)inAccountData;
- (id)accountData;

- (void)setDelegate:(id <FileTransferDelegate>)inDelegate;
- (id <FileTransferDelegate>)delegate;

- (AIListObject *)source;
- (AIListObject *)destination;

- (void)cancel;
- (void)reveal;
- (void)openFile;

- (NSImage *)iconImage;

@end
