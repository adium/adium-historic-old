//
//  ESFileTransferProgressView.h
//  Adium
//
//  Created by Evan Schoenberg on 11/11/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESFileTransferProgressRow, ESFileTransfer;

@interface ESFileTransferProgressView : NSView {
	IBOutlet ESFileTransferProgressRow	*owner;
	
	IBOutlet NSBox					*box_primaryControls;
	IBOutlet NSTextField			*textField_fileName;
	
	IBOutlet NSButton				*button_icon;
	IBOutlet NSProgressIndicator	*progressIndicator;
	
	IBOutlet NSTextField			*textField_transferStatus;
	
	NSString						*transferBytesStatus;
	NSString						*transferRemainingStatus;
	NSString						*transferSpeedStatus;

	IBOutlet NSButton				*button_stopResume;
	IBOutlet NSButton				*button_reveal;
	
	BOOL							showingDetails;
	IBOutlet NSButton				*twiddle_details;
	IBOutlet NSView					*view_details;
	IBOutlet NSTextField			*textField_rate;
	IBOutlet NSTextField			*textField_source;
	IBOutlet NSImageView			*imageView_source;
	IBOutlet NSTextField			*textField_destination;
	IBOutlet NSImageView			*imageView_destination;
	
	BOOL							isSelected;
}

- (void)setSourceName:(NSString *)inSourceName;
- (void)setSourceIcon:(NSImage *)inSourceIcon;

- (void)setDestinationName:(NSString *)inDestinationName;
- (void)setDestinationIcon:(NSImage *)inDestinationIcon;

- (void)setFileName:(NSString *)inFileName;
- (void)setIconImage:(NSImage *)inIconImage;

- (void)setProgressDoubleValue:(double)inPercent;
- (void)setProgressIndeterminate:(BOOL)flag;
- (void)setProgressAnimation:(BOOL)flag;

- (void)setTransferBytesStatus:(NSString *)inTransferBytesStatus
			   remainingStatus:(NSString *)inTransferRemainingStatus
				   speedStatus:(NSString *)inTransferSpeedStatus;

- (IBAction)toggleDetails:(id)sender;

- (void)setIsSelected:(BOOL)flag;

@end
