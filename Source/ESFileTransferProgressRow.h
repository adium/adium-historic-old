//
//  ESFileTransferProgressRow.h
//  Adium
//
//  Created by Evan Schoenberg on 11/11/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ESFileTransferProgressView.h"

@interface ESFileTransferProgressRow : NSObject<FileTransferDelegate> {
	ESFileTransfer			*fileTransfer;
	id						owner;

	UInt32					lastUpdateTick;
	unsigned long long		lastBytesSent;
	unsigned long long		size;
	NSString				*sizeString;
	BOOL					forceUpdate;
	
	IBOutlet				ESFileTransferProgressView	*view;
}

+ (ESFileTransferProgressRow *)rowForFileTransfer:(ESFileTransfer *)inFileTransfer withOwner:(id)owner;

- (IBAction)stopResumeAction:(id)sender;
- (IBAction)revealAction:(id)sender;
- (IBAction)openFileAction:(id)sender;

- (ESFileTransfer *)fileTransfer;
- (ESFileTransferProgressView *)view;

- (void)fileTransferProgressView:(ESFileTransferProgressView *)inView
			   heightChangedFrom:(float)oldHeight
							  to:(float)newHeight;

- (FileTransferType)type;
- (BOOL)isStopped;

- (NSMenu *)menuForEvent:(NSEvent *)theEvent;

@end
