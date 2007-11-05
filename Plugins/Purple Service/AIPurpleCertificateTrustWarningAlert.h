//
//  AIPurpleCertificateTrustWarningAlert.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-05.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@interface AIPurpleCertificateTrustWarningAlert : AIObject {
	IBOutlet NSPanel *panel;
	IBOutlet NSTextField *alertTitle;
	IBOutlet NSTextField *alertInformativeText;
	
	CFArrayRef certificates;
	
	void (*accept_cert)(void *userdata);
	void (*reject_cert)(void *userdata);
	void *userdata;
}

+ (void)displayTrustWarningAlertWithHostname:(NSString*)hostname error:(OSStatus)err certificates:(CFArrayRef)certs acceptCallback:(void (*)(void *userdata))_accept_cert rejectCallback:(void (*)(void *userdata))_reject_cert userData:(void*)ud;

- (IBAction)panelOK:(id)sender;
- (IBAction)panelCancel:(id)sender;
- (IBAction)panelShowCertificate:(id)sender;

@end
