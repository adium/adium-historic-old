//
//  AILicenseWindowController.h
//  Adium
//
//  Created by Adam Iser on Tue Mar 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AILicenseWindowController : NSWindowController {
	IBOutlet		NSTextView		*textView_license;
    id				target;
    SEL				selector;
}

+ (BOOL)displayLicenseAgreement;
- (IBAction)quit:(id)sender;
- (IBAction)agree:(id)sender;

@end
