//
//  ESFileTransferController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//


//File transfers
@interface ESFileTransferController : NSObject {
	
	IBOutlet	AIAdium		*owner;
	
	NSMenuItem  *sendFileMenuItem;
	NSMenuItem  *sendFileContextMenuItem;
}

- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)beganFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)transferCanceled:(ESFileTransfer *)fileTransfer;

- (void)sendFile:(NSString *)inFile toListContact:(AIListContact *)listContact;
- (void)requestForSendingFileToListContact:(AIListContact *)listContact;

//Private
- (void)initController;
- (void)closeController;

@end
