//
//  ESFileTransfer.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Thu Nov 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESFileTransfer.h"


@implementation ESFileTransfer
//Init
+ (id)fileTransferWithHandle:(AIHandle *)inHandle forAccount:(AIAccount *)inAccount
{
    return([[[self alloc] initWithHandle:(AIHandle *)inHandle forAccount:(AIAccount *)inAccount] autorelease]);    
}

- (id)initWithHandle:(AIHandle *)inHandle forAccount:(AIAccount *)inAccount;
{
    [super init];
    
    //Retain our information
    handle = [inHandle retain];
    account = [inAccount retain];
    type = Unknown_FileTransfer;
    
    return(self);
}

- (void)dealloc
{
    [handle release];
    [account release];
    [remoteFilename release];
    [localFilename release];
    [accountData release];
    
    [super dealloc];
}

- (AIHandle *)handle
{
    return handle;   
}

- (AIAccount *)account
{
    return account;   
}

- (void)setRemoteFilename:(NSString *)inRemoteFilename
{
    [remoteFilename release]; remoteFilename = nil;
    remoteFilename = [inRemoteFilename retain];
}
- (NSString *)remoteFilename
{
    return remoteFilename;
}

- (void)setLocalFilename:(NSString *)inLocalFilename
{
    [localFilename release]; localFilename = nil;
    localFilename = [inLocalFilename retain];
}
- (NSString *)localFilename
{
    return localFilename;
}

- (void)setSize:(unsigned int)inSize
{
    size = inSize;
}
- (unsigned int)size
{
    return size;
}

- (void)setType:(FileTransferType)inType
{
    type = inType;
}
- (FileTransferType)type
{
    return type;   
}

- (void)setPercentDone:(float)inPercent bytesSent:(unsigned int)inBytesSent
{
    if (inPercent == -1) {
        if (inBytesSent != -1 && size != -1)
            percentDone = (inBytesSent / size);
    } else
        percentDone = inPercent;
    
    if (inBytesSent == -1) {
        if (inPercent != -1 && size != -1)
            bytesSent = inPercent * size;
    } else
        bytesSent = inBytesSent;
}
- (float)percentDone
{
    return percentDone;
}
- (unsigned int)bytesSent
{
    return bytesSent;
}

- (void)setAccountData:(id)inAccountData
{
    [accountData release]; accountData = nil;
    accountData = [inAccountData retain];
}
- (id)accountData
{
    return accountData;   
}

@end
