//
//  AdiumUnreadMessagesQuitConfirmation.h
//  Adium
//
//  Created by Evan Schoenberg on 12/15/05.


#import <Adium/AIWindowController.h>

@interface AdiumUnreadMessagesQuitConfirmation : AIWindowController {
	IBOutlet	NSTextField	*textField_quitConfirmation;

	IBOutlet	NSButton	*button_quit;
	IBOutlet	NSButton	*button_cancel;
	IBOutlet	NSButton	*checkBox_dontAskAgain;
}

+ (void)showUnreadMessagesQuitConfirmation;

- (IBAction)pressedButton:(id)sender;

@end
