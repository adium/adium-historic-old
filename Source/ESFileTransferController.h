//
//  ESFileTransferController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//

#define	FileTransfer_NewFileTransfer	@"NewFileTransfer"

@class ESFileTransfer, AIListContact, AIAccount;

@protocol AIEventHandler;

//File transfers
@interface ESFileTransferController : NSObject <AIEventHandler> {
	IBOutlet	AIAdium		*adium;
	
	NSMenuItem				*menuItem_sendFile;
	NSMenuItem				*menuItem_sendFileContext;
	
	NSMenuItem				*menuItem_showFileTransferProgress;
	
	NSMutableArray			*fileTransferArray;
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
