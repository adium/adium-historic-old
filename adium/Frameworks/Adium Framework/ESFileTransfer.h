//
//  ESFileTransfer.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Thu Nov 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIAccount, AIHandle;

@interface ESFileTransfer : AIObject {
    AIHandle *handle;
    AIAccount<AIAccount_Files> *account;
    NSString *localFilename;
    NSString *remoteFilename;
    id accountData;
    
    float percentDone;
    unsigned int size;
    unsigned int bytesSent;
    FileTransferType type;
}

+ (id)fileTransferWithHandle:(AIHandle *)inHandle forAccount:(AIAccount *)inAccount;
- (id)initWithHandle:(AIHandle *)inHandle forAccount:(AIAccount *)inAccount;

- (AIHandle *)handle;
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

@end
