//
//  ESFileTransferController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//

#define	FileTransfer_NewFileTransfer	@"NewFileTransfer"

#define	PREF_GROUP_FILE_TRANSFER		@"FileTransfer"

#define	KEY_FT_AUTO_ACCEPT				@"FT AutoAccept"
#define KEY_FT_AUTO_OPEN_SAFE			@"FT AutoOpenSafe"
#define	KEY_FT_AUTO_CLEAR_COMPLETED		@"FT AutoClearCompleted"
#define	KEY_FT_SHOW_PROGRESS_WINDOW		@"FT ShowProgressWindow"

typedef enum {
	AutoAccept_None = 0,
    AutoAccept_All,
    AutoAccept_FromContactList,
} FTAutoAcceptType;

@class ESFileTransfer, AIListContact, AIAccount;

@protocol AIEventHandler;

//File transfers
@interface ESFileTransferController : NSObject <AIEventHandler> {
	IBOutlet	AIAdium		*adium;
	
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

- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer;

- (void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(FileTransferStatus)status;

- (void)sendFile:(NSString *)inFile toListContact:(AIListContact *)listContact;
- (void)requestForSendingFileToListContact:(AIListContact *)listContact;

//Private
- (void)initController;
- (void)closeController;

@end
