//
//  ESFileTransferController.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//


//File transfers
@interface ESFileTransferController : NSObject {
	
}

- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)beganFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)transferCanceled:(ESFileTransfer *)fileTransfer;

//Private
- (void)initController;
- (void)closeController;

@end
