//
//  RAFjoscarSecuridPromptController.h
//  Adium
//
//  Created by Augie Fackler on 3/21/06.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIWindowController.h>

@class AIAccount;

@interface RAFjoscarSecuridPromptController : AIWindowController {
	//this is the secure field we get the securid from:
	IBOutlet NSSecureTextField *securid;
	// the caption on the field to fill out
	IBOutlet NSTextField *securidView;
	//the window title line
	IBOutlet NSTextField *securidTitle;
	
	IBOutlet NSTextField *accountTitle;
	IBOutlet NSTextField *accountText;
	
	IBOutlet NSButton *okButton;
	IBOutlet NSButton *cancelButton;
	
	NSString *accountUID;
	NSString *securidString;
}

- (RAFjoscarSecuridPromptController *)initWithAccount:(AIAccount *)account;
+ (NSString *)getSecuridForAccount:(AIAccount *)account;

- (IBAction)okButtonClicked:(id)sender;
- (IBAction)cancelButtonClicked:(id)sender;
- (NSString *)getSecurid;

@end
