//
//  ESFileTransferProgressWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 11/14/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESFileTransfer, ESFileTransferProgressRow;

@interface ESFileTransferProgressWindowController : AIWindowController {
	NSMutableArray				*progressRows;
	ESFileTransferProgressRow	*selectedRow;
	
	IBOutlet NSScrollView					*scrollView;
	IBOutlet AIVariableHeightOutlineView	*outlineView;
	
	IBOutlet NSTextField		*textField_statusBar;
}

+ (id)showFileTransferProgressWindow;

//For use by ESFileTransferProgressRow
- (void)progressRowDidAwakeFromNib:(ESFileTransferProgressRow *)progressView;
- (void)fileTransferProgressRow:(ESFileTransferProgressRow *)inRow
			  heightChangedFrom:(float)oldHeight
							 to:(float)newHeight;
- (void)progressRowDidChangeType:(ESFileTransferProgressRow *)progressRow;

@end
