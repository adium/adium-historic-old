//
//  ESFileTransfer.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Thu Nov 13 2003.
//

#import "ESFileTransfer.h"


@implementation ESFileTransfer
//Init
+ (id)fileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount
{
    return([[[self alloc] initWithContact:inContact forAccount:inAccount] autorelease]);    
}

- (id)initWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount;
{
    [super init];
    
    //Retain our information
    contact = [inContact retain];
    account = [inAccount retain];
    type = Unknown_FileTransfer;
    delegate = nil;
	
    return(self);
}

- (void)dealloc
{
    [contact release];
    [account release];
    [remoteFilename release];
    [localFilename release];
    [accountData release];
    
    [super dealloc];
}

- (AIListContact *)contact
{
    return contact;   
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
	
	if (delegate)
		[delegate fileTransfer:self didSetLocalFilename:localFilename];
}
- (NSString *)localFilename
{
    return localFilename;
}

- (void)setSize:(unsigned int)inSize
{
    size = inSize;
	
	if (delegate)
		[delegate fileTransfer:self didSetSize:size];
}
- (unsigned int)size
{
    return size;
}

- (void)setType:(FileTransferType)inType
{
    type = inType;
	
	if (delegate)
		[delegate fileTransfer:self didSetType:type];
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
	
	if (delegate)
		[delegate gotUpdateForFileTransfer:self];
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

- (void)setDelegate:(id <FileTransferDelegate>)inDelegate
{
	delegate = inDelegate;
}
- (id <FileTransferDelegate>)delegate;
{
	return delegate;
}
@end
