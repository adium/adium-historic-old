//
//  ESFileTransfer.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Thu Nov 13 2003.
//

#define FILE_TRANSFER_TYPE  @"File Transfer Type"

typedef enum {
    Incoming_FileTransfer = 0,
    Outgoing_FileTransfer,
    Unknown_FileTransfer
} FileTransferType;

@protocol FileTransferDelegate
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetType:(FileTransferType)type;
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetSize:(unsigned int)size;
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetLocalFilename:(NSString *)inLocalFilename;
-(void)gotUpdateForFileTransfer:(ESFileTransfer *)fileTransfer;
@end

@class AIAccount;

@interface ESFileTransfer : AIObject {
    AIListContact				*contact;
    AIAccount<AIAccount_Files> 	*account;
    NSString					*localFilename;
    NSString					*remoteFilename;
    id							accountData;
    
    float						percentDone;
    unsigned int				size;
    unsigned int				bytesSent;
    FileTransferType			type;
	
	id <FileTransferDelegate>   delegate;
}

+ (id)fileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount;
- (id)initWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount;

- (AIListContact *)contact;
- (AIAccount *)account;

- (void)setRemoteFilename:(NSString *)inRemoteFilename;
- (NSString *)remoteFilename;

- (void)setLocalFilename:(NSString *)inLocalFilename;
- (NSString *)localFilename;

- (void)setSize:(unsigned int)inSize;
- (unsigned int)size;

- (void)setType:(FileTransferType)inType;
- (FileTransferType)type;

- (void)setPercentDone:(float)inPercent bytesSent:(unsigned int)inBytesSent;
- (float)percentDone;
- (unsigned int)bytesSent;

- (void)setAccountData:(id)inAccountData;
- (id)accountData;

- (void)setDelegate:(id <FileTransferDelegate>)inDelegate;
- (id <FileTransferDelegate>)delegate;

@end
