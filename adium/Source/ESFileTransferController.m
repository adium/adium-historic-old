//
//  ESFileTransferController.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//  $Id: ESFileTransferController.m,v 1.5 2004/01/09 04:16:37 adamiser Exp $

#import "ESFileTransferController.h"


@implementation ESFileTransferController
//init and close
- (void)initController
{

}

- (void)closeController
{
    
}

- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer
{
    NSLog(@"receive request in transfer controller");
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setTitle:@"Receive File"];

    NSString * defaultName = [fileTransfer remoteFilename];
    
    if ([savePanel runModalForDirectory:nil file:defaultName] == NSFileHandlingPanelOKButton) {
        [fileTransfer setLocalFilename:[savePanel filename]];
        [(AIAccount<AIAccount_Files> *)[fileTransfer account] acceptFileTransferRequest:fileTransfer];
    } else {
        [(AIAccount<AIAccount_Files> *)[fileTransfer account] rejectFileReceiveRequest:fileTransfer];        
    }
}

- (void)beganFileTransfer:(ESFileTransfer *)fileTransfer
{
    NSLog(@"began a file transfer...");
}

- (void)transferCanceled:(ESFileTransfer *)fileTransfer
{
    NSLog(@"canceled a file transfer...");   
}

@end
