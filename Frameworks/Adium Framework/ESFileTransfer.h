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

#import "AIObject.h"
#import "ESFileTransferController.h"

#define FILE_TRANSFER_TYPE  @"File Transfer Type"

@protocol AIAccount_Files;

@class AIAccount, AIListObject, ESFileTransfer;

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

- (NSString *)displayFilename;

- (void)setSize:(unsigned long long)inSize;
- (unsigned long long)size;

- (void)setType:(FileTransferType)inType;
- (FileTransferType)type;

- (void)setStatus:(FileTransferStatus)inStatus;
- (FileTransferStatus)status;

- (void)setPercentDone:(float)inPercent bytesSent:(int)inBytesSent;
- (float)percentDone;
- (unsigned long long)bytesSent;

- (void)setAccountData:(id)inAccountData;
- (id)accountData;

- (void)setDelegate:(id <FileTransferDelegate>)inDelegate;
- (id <FileTransferDelegate>)delegate;

- (AIListObject *)source;
- (AIListObject *)destination;

- (BOOL)isStopped;

- (void)cancel;
- (void)reveal;
- (void)openFile;

- (NSImage *)iconImage;

@end
