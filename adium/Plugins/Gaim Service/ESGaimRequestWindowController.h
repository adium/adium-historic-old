//
//  ESGaimRequestWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Apr 14 2004.
//

#import "CBGaimServicePlugin.h"

@interface ESGaimRequestWindowController : AIWindowController {	
	IBOutlet		NSTextField		*textField_primary;
	IBOutlet		NSTextField	*textField_secondary;
	IBOutlet		NSTextField	*textField_input;
	IBOutlet		NSButton		*button_okay;
	IBOutlet		NSButton		*button_cancel;
	
	NSValue			*okayCallbackValue;
	NSValue			*cancelCallbackValue;
	NSValue			*userDataValue;
}

+ (void)showInputWindowWithDict:(NSDictionary *)infoDict;
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict multiline:(BOOL)multiline;
- (IBAction)pressedButton:(id)sender;
@end
