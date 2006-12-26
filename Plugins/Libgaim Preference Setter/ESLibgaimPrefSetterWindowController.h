//
//  ESLibgaimPrefSetterWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 12/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	ESLibgaimPrefBool = 0,
	ESLibgaimPrefInt,
	ESLibgaimPrefString
} ESLibgaimPrefType;

@interface ESLibgaimPrefSetterWindowController : NSWindowController {
	IBOutlet NSTextField *textField_pref;
	IBOutlet NSTextField *textField_value;
	IBOutlet NSPopUpButton *popUp_type;
}

+ (void)show;
- (IBAction)setPref:(id)sender;
@end
