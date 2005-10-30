//
//  MessageStyleViewController.h
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"

@interface MessageStyleViewController : NSObject <ViewController> {
	IBOutlet NSTextField * DisplayNameForNoVariantField;
	IBOutlet NSTextField * DefaultFontFamilyField;
	IBOutlet NSTextField * DefaultFontSizeField;
	IBOutlet NSButton * showUserIconsCheckbox;
	IBOutlet NSView * view;
}

@end
