//
//  ESFileTransfer.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 13 2003.
//

#import "ESFileTransfer.h"
#import "AIListContact.h"
#import "AIAccount.h"

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
	status = Unknown_Status_FileTransfer;
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

- (AIAccount<AIAccount_Files> *)account
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

- (void)setSize:(unsigned long long)inSize
{
    size = inSize;
	
	if (delegate)
		[delegate fileTransfer:self didSetSize:size];
}
- (unsigned long long)size
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

- (void)setStatus:(FileTransferStatus)inStatus
{
	if(status != inStatus){
		status = inStatus;
		
		[[adium fileTransferController] fileTransfer:self didSetStatus:status];
		
		if (delegate)
			[delegate fileTransfer:self didSetStatus:status];
	}
}
- (FileTransferStatus)status
{
	return status;
}

//Progress update
- (void)setPercentDone:(float)inPercent bytesSent:(unsigned int)inBytesSent
{
	float oldPercentDone = percentDone;
	unsigned int oldBytesSent = bytesSent;
	
    if (inPercent == -1){
        if (inBytesSent != -1 && size != -1){
            percentDone = (inBytesSent / size);
		}
    }else{
        percentDone = inPercent;
    }
	
    if (inBytesSent == -1){
        if (inPercent != -1 && size != -1){
            bytesSent = inPercent * size;
		}
    }else{
        bytesSent = inBytesSent;
	}
	
	if ((percentDone != oldPercentDone) || (bytesSent != oldBytesSent)){
		if (delegate){
			[delegate gotUpdateForFileTransfer:self];
		}
		
		if (percentDone >= 1.0){
			[self setStatus:Complete_FileTransfer];
		}else if ((percentDone != 0) && (status != In_Progress_FileTransfer)){
			[self setStatus:In_Progress_FileTransfer];
		}
	}
}
- (float)percentDone
{
    return percentDone;
}
- (unsigned long long)bytesSent
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

- (AIListObject *)source
{
	AIListObject	*source;
	switch(type){
		case Incoming_FileTransfer:
			source = contact;
			break;
		case Outgoing_FileTransfer:
			source = account;
			break;
		default:
			source = nil;
			break;
	}
	
	return(source);
}
- (AIListObject *)destination
{
	AIListObject	*destination;
	switch(type){
		case Incoming_FileTransfer:
			destination = account;
			break;
		case Outgoing_FileTransfer:
			destination = contact;
			break;
		default:
			destination = nil;
			break;
	}
	
	return(destination);	
}

- (void)cancel
{
	[[self account] cancelFileTransfer:self];
}

- (void)reveal
{
	[[NSWorkspace sharedWorkspace] selectFile:localFilename
					 inFileViewerRootedAtPath:[localFilename stringByDeletingLastPathComponent]];
}

- (void)openFile
{
	[[NSWorkspace sharedWorkspace] openFile:localFilename];
}

@end
