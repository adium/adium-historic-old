//
//  ESFileTransferRequestPromptController.m
//  Adium
//
//  Created by Evan Schoenberg on 1/3/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESFileTransferRequestPromptController.h"

#define	TRANSFER_REQUEST_PROMPT_NIB	@"FileTransferRequestPrompt"

@interface ESFileTransferRequestPromptController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName
			forFileTransfer:(ESFileTransfer *)inFileTransfer
			notifyingTarget:(id)inTarget
				   selector:(SEL)inSelector;
@end

@implementation ESFileTransferRequestPromptController

+ (void)displayPromptForFileTransfer:(ESFileTransfer *)inFileTransfer
					 notifyingTarget:(id)inTarget
							selector:(SEL)inSelector
{
	ESFileTransferRequestPromptController	*requestPromptController;
	
	requestPromptController = [[self alloc] initWithWindowNibName:TRANSFER_REQUEST_PROMPT_NIB
												  forFileTransfer:inFileTransfer
												  notifyingTarget:inTarget
														 selector:inSelector];
	
	[requestPromptController showWindow:nil];	
}

- (id)initWithWindowNibName:(NSString *)windowNibName
			forFileTransfer:(ESFileTransfer *)inFileTransfer
			notifyingTarget:(id)inTarget
				   selector:(SEL)inSelector
{	
	fileTransfer = [inFileTransfer retain];
	target = [inTarget retain];
	selector = inSelector;
	
	[super initWithWindowNibName:windowNibName];
	
    return(self);
}

- (void)dealloc
{
	[fileTransfer release];
	[target release];

	[super dealloc];
}

// called as the window closes
- (BOOL)windowShouldClose:(id)sender
{    
    //release the window controller (ourself)
    [self autorelease];
	
    return(YES);
}

- (void)windowDidLoad
{
	NSString	*remoteFilename = [fileTransfer remoteFilename];
	
	//Setup the textviews
    [textView_requestTitle setHorizontallyResizable:NO];
    [textView_requestTitle setVerticallyResizable:YES];
    [textView_requestTitle setDrawsBackground:NO];
    [scrollView_requestTitle setDrawsBackground:NO];
	
    [textView_requestDetails setHorizontallyResizable:NO];
    [textView_requestDetails setVerticallyResizable:YES];
    [textView_requestDetails setDrawsBackground:NO];
    [scrollView_requestDetails setDrawsBackground:NO];
	
	//Setup the buttons
	[button_save setTitle:AILocalizedString(@"Save",nil)];
	[button_saveAs setTitle:AILocalizedString(@"Save As...",nil)];
	[button_cancel setTitle:AILocalizedString(@"Cancel",nil)];

	//Setup the imageView for the file's icon
	NSImage		*iconImage;
	if(iconImage = [fileTransfer iconImage]){
		[imageView_icon setImage:iconImage];
	}
	
	NSRect	frame = [[self window] frame];
    int		heightChange;
	
    //Display the current request title
    [textView_requestTitle setString:[NSString stringWithFormat:AILocalizedString(@"File transfer request from %@",nil),[[fileTransfer contact] displayName]]];
	
	//Resize the window frame to fit the request title
	[textView_requestTitle sizeToFit];
	heightChange = [textView_requestTitle frame].size.height - [scrollView_requestTitle documentVisibleRect].size.height;
	frame.size.height += heightChange;
	frame.origin.y -= heightChange;
	
	//Display the name of the file, with the file's size if available
	NSString	*filenameDisplay;
	unsigned long long fileSize = [fileTransfer size];
	if(fileSize){
			filenameDisplay = [NSString stringWithFormat:@"%@ (%@)",remoteFilename,[[adium fileTransferController] stringForSize:fileSize]];
	}else{
			filenameDisplay = remoteFilename;
	}

	[textView_requestDetails setString:[NSString stringWithFormat:AILocalizedString(@"%@ requests to send you %@",nil),[[fileTransfer contact] formattedUID], filenameDisplay]];

	//Resize the window frame to fit the error message
	[textView_requestDetails sizeToFit];
	heightChange = [textView_requestDetails frame].size.height - [scrollView_requestDetails documentVisibleRect].size.height;
	frame.size.height += heightChange;
    frame.origin.y -= heightChange;
	
	//Perform the window resizing as needed
	if ([NSApp isOnPantherOrBetter]){
		[[self window] setFrame:frame display:YES animate:YES];
	}else{
		[[self window] setFrame:frame display:YES]; //animate:YES can crash in 10.2
	}
	
	//Set the title
	[[self window] setTitle:AILocalizedString(@"File Transfer Request",nil)];

    [[self window] makeKeyAndOrderFront:nil];
	
	[super windowDidLoad];
}

- (IBAction)pressedButton:(id)sender
{
	NSString	*localFilename = nil;
	BOOL		finished = NO;

	if(sender == button_save){
		localFilename = [[[adium preferenceController] userPreferredDownloadFolder] stringByAppendingPathComponent:[fileTransfer remoteFilename]];

		finished = YES;

	}else if(sender == button_saveAs){
		//Prompt for a location to save
		[[NSSavePanel savePanel] beginSheetForDirectory:[[adium preferenceController] userPreferredDownloadFolder]
												   file:[fileTransfer remoteFilename]
										 modalForWindow:[self window]
										  modalDelegate:self
										 didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
											contextInfo:nil];
		
	}else if (sender == button_cancel){
		/* File name remains nil and the transfer will therefore be canceled */
		finished = YES;
	}

	if(finished){
		[target performSelector:selector
					 withObject:fileTransfer
					 withObject:localFilename];
		
		//close the prompt
		[self closeWindow:nil];
	}
}

- (void)savePanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	//Only need to take action if the user pressed OK; if she pressed cancel, just return to our window.
	if(returnCode == NSOKButton){
		[target performSelector:selector
					 withObject:fileTransfer
					 withObject:[savePanel filename]];

		//close the prompt on the next run loop (for smooth animation of the sheet going back into the window)
		[self performSelector:@selector(closeWindow:)
				   withObject:nil
				   afterDelay:0];
	}
}

// closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

@end
