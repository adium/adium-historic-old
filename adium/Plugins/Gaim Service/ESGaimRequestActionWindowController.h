//
//  ESGaimRequestActionWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed May 05 2004.

#import "GaimCommon.h"

@interface ESGaimRequestActionWindowController : AIWindowController {
    IBOutlet	NSTextField		*textField_title;
    IBOutlet	NSTextView		*textView_msg;
    IBOutlet	NSScrollView	*scrollView_msg;
	IBOutlet	NSButton		*button_default;
	IBOutlet	NSButton		*button_alternate;
	IBOutlet	NSButton		*button_other;
	
	NSValue						*callBacks;
	unsigned int				actionCount;
	NSValue						*userData;
}

+ (void)showActionWindowWithDict:(NSDictionary *)infoDict;
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict;
- (IBAction)pressedButton:(id)sender;

@end
