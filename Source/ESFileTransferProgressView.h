//
//  ESFileTransferProgressView.h
//  Adium
//
//  Created by Evan Schoenberg on 11/11/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESFileTransferProgressRow, ESFileTransfer, AIRolloverButton;

@interface ESFileTransferProgressView : NSView {
	IBOutlet ESFileTransferProgressRow	*owner;
	
	IBOutlet NSBox					*box_primaryControls;
	IBOutlet NSTextField			*textField_fileName;
	
	IBOutlet NSButton				*button_icon;
	IBOutlet NSProgressIndicator	*progressIndicator;
	
	NSString						*transferBytesStatus;
	NSString						*transferRemainingStatus;
	NSString						*transferSpeedStatus;

	IBOutlet AIRolloverButton		*button_stopResume;
	BOOL							buttonStopResumeIsHovered;

	IBOutlet AIRolloverButton		*button_reveal;
	BOOL							buttonRevealIsHovered;

	//Details in primary view
	BOOL							showingDetails;
	IBOutlet NSButton				*twiddle_details;
	IBOutlet NSTextField			*textField_detailsLabel;
	IBOutlet NSBox					*box_transferStatusFrame; //Placeholder for drawing the transfer status
	NSString						*transferStatus;
	
	//Details view (revealed by twiddle_details)
	IBOutlet NSView					*view_details;
	IBOutlet NSTextField			*textField_rate;
	IBOutlet NSTextField			*textField_source;
	IBOutlet NSImageView			*imageView_source;
	IBOutlet NSTextField			*textField_destination;
	IBOutlet NSImageView			*imageView_destination;
	
	BOOL							isSelected;
	BOOL							progressVisible;
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
- (void)setProgressVisible:(BOOL)flag;

- (void)setTransferBytesStatus:(NSString *)inTransferBytesStatus
			   remainingStatus:(NSString *)inTransferRemainingStatus
				   speedStatus:(NSString *)inTransferSpeedStatus;

- (IBAction)toggleDetails:(id)sender;

- (void)setAllowsCancel:(BOOL)flag;

@end
