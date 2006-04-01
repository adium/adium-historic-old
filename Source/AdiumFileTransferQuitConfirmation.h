//
//  AdiumFileTransferQuitConfirmation.h
//  Adium
//
//  Created by Matt Molinaro on 03/25/06.


#import <Adium/AIWindowController.h>

@interface AdiumFileTransferQuitConfirmation : AIWindowController {
	IBOutlet	NSTextField	*textField_quitConfirmation;

	IBOutlet	NSButton	*button_quit;
	IBOutlet	NSButton	*button_cancel;
	IBOutlet	NSButton	*checkBox_dontAskAgain;
}

+ (void)showFileTransferQuitConfirmation;

- (IBAction)pressedButton:(id)sender;

@end
