/*
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIPreferenceController.h"
#import "ESFileTransferController.h"
#import "ESFileTransferRequestPromptController.h"
#import <Adium/AIListContact.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface ESFileTransferRequestPromptController (PRIVATE)
- (id)initForFileTransfer:(ESFileTransfer *)inFileTransfer
		  notifyingTarget:(id)inTarget
				 selector:(SEL)inSelector;
- (ESTextAndButtonsWindowController *)windowController;
@end

@implementation ESFileTransferRequestPromptController

/*
 * @brief Display a prompt for a file transfer to save, save as, or cancel
 *
 * @param inFileTransfer The file transfer
 * @param inSelector A selector, which must accept two arguments. The first will be inFileTransfer. The second will be the filename to save to, or nil to cancel.
 * @result The NSWindowController for the displayed prompt
 */
+ (AIWindowController *)displayPromptForFileTransfer:(ESFileTransfer *)inFileTransfer
									 notifyingTarget:(id)inTarget
											selector:(SEL)inSelector
{
	ESFileTransferRequestPromptController	*promptController;
	AIWindowController						*windowController = nil;
	
	if ((promptController = [[self alloc] initForFileTransfer:inFileTransfer
											  notifyingTarget:inTarget
													 selector:inSelector])) {
		windowController = [promptController windowController];
	}
	
	return windowController;
}

- (id)initForFileTransfer:(ESFileTransfer *)inFileTransfer
		  notifyingTarget:(id)inTarget
				 selector:(SEL)inSelector
{
	if ((self = [super init])) {		
		fileTransfer = [inFileTransfer retain];
		target       = [inTarget retain];
		selector     =  inSelector;
		
		NSAttributedString	*message;
		NSString			*filenameDisplay;
		NSString			*remoteFilename = [fileTransfer remoteFilename];

		//Display the name of the file, with the file's size if available
		unsigned long long fileSize = [fileTransfer size];
		
		if (fileSize) {
			NSString	*fileSizeString;
			
			fileSizeString = [[adium fileTransferController] stringForSize:fileSize];
			filenameDisplay = [NSString stringWithFormat:@"%@ (%@)",remoteFilename,fileSizeString];
		} else {
			filenameDisplay = remoteFilename;
		}
		
		message = [NSAttributedString stringWithString:
			[NSString stringWithFormat:AILocalizedString(@"%@ requests to send you %@",nil),
				[[fileTransfer contact] formattedUID],
				filenameDisplay]];
			
		windowController = [[ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:AILocalizedString(@"File Transfer Request",nil)
																				 defaultButton:AILocalizedString(@"Save",nil)
																			   alternateButton:AILocalizedString(@"Cancel",nil)
																				   otherButton:[AILocalizedString(@"Save As",nil) stringByAppendingEllipsis]
																					  onWindow:nil
																			 withMessageHeader:nil
																					andMessage:message
																						target:self
																					  userInfo:nil] retain];
	}

	return self;
}

- (void)dealloc
{
	[fileTransfer release];
	[target release];
	[windowController release];

	[super dealloc];
}

- (ESTextAndButtonsWindowController *)windowController
{
	return windowController;
}

/*!
 * @brief Window was closed, either by a button being clicked or the user closing it
 */
- (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo
{
	NSString	*localFilename = nil;
	BOOL		finished = NO;

	switch (returnCode) {			
		case AITextAndButtonsDefaultReturn: /* Save */
		{
			localFilename = [[[adium preferenceController] userPreferredDownloadFolder] stringByAppendingPathComponent:[fileTransfer remoteFilename]];
			
			/* If the file doesn't exist, we're done.  If it does, fall through to AITextAndButtonsOtherReturn
			 * triggering a Save As... panel.
			*/
			if (![[NSFileManager defaultManager] fileExistsAtPath:localFilename]) {
				finished = YES;
				break;
			}
		}
		case AITextAndButtonsOtherReturn: /* Save As... */
		{
			//Prompt for a location to save
			[[[NSSavePanel savePanel] retain] beginSheetForDirectory:[[adium preferenceController] userPreferredDownloadFolder]
																file:[fileTransfer remoteFilename]
													  modalForWindow:[windowController window]
													   modalDelegate:self
													  didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
														 contextInfo:nil];
			break;
		}
		case AITextAndButtonsAlternateReturn: /* Cancel */			
		case AITextAndButtonsClosedWithoutResponse: /* Closed = Cancel */
		{
			/* File name remains nil and the transfer will therefore be canceled */
			finished = YES;
			break;
		}
	}

	if (finished) {
		[target performSelector:selector
					 withObject:fileTransfer
					 withObject:localFilename];
		
		//Release our instance	
		[self autorelease];
		
		//Close the window
		return YES;
	}
	
	//Don't close the window if we're not finished.
	return NO;
}


- (void)savePanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	//Only need to take action if the user pressed OK; if she pressed cancel, just return to our window.
	if (returnCode == NSOKButton) {
		[target performSelector:selector
					 withObject:fileTransfer
					 withObject:[savePanel filename]];

		//close the prompt on the next run loop (for smooth animation of the sheet going back into the window)
		[windowController performSelector:@selector(closeWindow:)
							   withObject:nil
							   afterDelay:0];
		[self autorelease];
	}

	[savePanel release];
}

@end
