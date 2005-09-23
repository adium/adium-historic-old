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

#import <Adium/AIObject.h>

#define	FileTransfer_NewFileTransfer	@"NewFileTransfer"

#define	PREF_GROUP_FILE_TRANSFER		@"FileTransfer"

#define	KEY_FT_AUTO_ACCEPT				@"FT AutoAccept"
#define KEY_FT_AUTO_OPEN_SAFE			@"FT AutoOpenSafe"
#define	KEY_FT_AUTO_CLEAR_COMPLETED		@"FT AutoClearCompleted"
#define	KEY_FT_SHOW_PROGRESS_WINDOW		@"FT ShowProgressWindow"

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

typedef enum {
	AutoAccept_None = 0,
    AutoAccept_All,
    AutoAccept_FromContactList,
} FTAutoAcceptType;

@class AIWindowController, ESFileTransfer, AIListContact, AIAccount;

@protocol AIController, AIEventHandler;

//File transfers
@interface ESFileTransferController : AIObject <AIController, AIEventHandler> {
	NSMenuItem				*menuItem_sendFile;
	NSMenuItem				*menuItem_sendFileContext;
	
	NSMenuItem				*menuItem_showFileTransferProgress;
	
	NSMutableArray			*fileTransferArray;
	NSSet					*safeFileExtensions;
	
	FTAutoAcceptType		autoAcceptType;
	BOOL					autoChooseFolder;
	BOOL					autoOpenSafe;
	BOOL					autoClearCompletedTransfers;
	BOOL					showProgressWindow;
}

//Should be the only vendor of new ESFileTransfer* objects, as it creates, tracks, and returns them
- (ESFileTransfer *)newFileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount;
- (NSArray *)fileTransferArray;

- (AIWindowController *)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer;

- (void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(FileTransferStatus)status;

- (void)sendFile:(NSString *)inFile toListContact:(AIListContact *)listContact;
- (void)requestForSendingFileToListContact:(AIListContact *)listContact;

- (NSString *)stringForSize:(unsigned long long)inSize;
- (NSString *)stringForSize:(unsigned long long)inSize of:(unsigned long long)totalSize ofString:(NSString *)totalSizeString;

@end
