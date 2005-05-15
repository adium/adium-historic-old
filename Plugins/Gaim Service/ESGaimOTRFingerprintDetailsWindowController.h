//
//  ESGaimOTRFingerprintDetailsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 5/11/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

@interface ESGaimOTRFingerprintDetailsWindowController : AIWindowController {
	IBOutlet	NSTextField	*textField_UID;
	IBOutlet	NSTextField	*textField_fingerprint;
	
	IBOutlet	NSImageView	*imageView_service;
	IBOutlet	NSImageView	*imageView_lock;
	
	NSDictionary	*fingerprintDict;
}

+ (void)showDetailsForFingerprintDict:(NSDictionary *)inFingerprintDict;

- (IBAction)forgetFingerprint:(id)sender;

@end
