//
//  ESGaimNotifyEmailWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Fri May 28 2004.


#import "CBGaimServicePlugin.h"

@interface ESGaimNotifyEmailWindowController : AIWindowController {
	IBOutlet	NSTextField		*textField_title;
	IBOutlet	NSTextView		*textView_msg;
	IBOutlet	NSScrollView	*scrollView_msg;
	
	IBOutlet	NSButton		*button_okay;
	IBOutlet	NSButton		*button_showEmail;
	
	NSString					*urlString;
}

+ (void)showNotifyEmailWindowWithMessage:(NSAttributedString *)inMessage URL:(NSString *)URL;
- (id)initWithWindowNibName:(NSString *)windowNibName withMessage:(NSAttributedString *)inMessage URL:(NSString *)inURL;
- (IBAction)pressedButton:(id)sender;

@end
