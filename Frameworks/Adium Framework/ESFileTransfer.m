/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIAccount.h"
#import "AIListContact.h"
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
    if (remoteFilename != inRemoteFilename){
        [remoteFilename release];
        remoteFilename = [inRemoteFilename retain];
    }
}
- (NSString *)remoteFilename
{
    return remoteFilename;
}

- (void)setLocalFilename:(NSString *)inLocalFilename
{
    if (localFilename != inLocalFilename){
        [localFilename release];
        localFilename = [inLocalFilename retain];
	}
	
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
- (void)setPercentDone:(float)inPercent bytesSent:(int)inBytesSent
{
	float oldPercentDone = percentDone;
	int oldBytesSent = bytesSent;
	
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
    if (accountData != inAccountData){
        [accountData release];
        accountData = [inAccountData retain];
    }
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

- (NSImage *)iconImage
{
	NSImage		*iconImage = nil;
	NSString	*extension;
	
	extension = [[self localFilename] pathExtension];
	
	//Fall back on the remote filename if necessary
	if(!extension) extension = [[self remoteFilename] pathExtension]; 
	
	if(extension && [extension length]){

		//XXX - Test for file transfer type, overlay a light up arrow or down arrow?
		iconImage = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
	}

	return(iconImage);
}	

- (BOOL)isStopped
{
	return((status == Complete_FileTransfer) ||
		   (status == Canceled_Local_FileTransfer) ||
		   (status == Canceled_Remote_FileTransfer));
}

@end
