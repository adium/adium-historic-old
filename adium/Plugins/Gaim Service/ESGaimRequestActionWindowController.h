//
//  ESGaimRequestActionWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Wed May 05 2004.

@interface ESGaimRequestActionWindowController : AIWindowController {
    IBOutlet	NSTextField	*textField_errorTitle;
    IBOutlet	NSTextView	*textView_errorInfo;
    IBOutlet	NSButton	*button_okay;
}

+ (void)showActionWindowWithDict:(NSDictionary *)infoDict;

@end
