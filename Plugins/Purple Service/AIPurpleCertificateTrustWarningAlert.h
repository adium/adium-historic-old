//
//  AIPurpleCertificateTrustWarningAlert.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-05.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>
#import <Adium/AIAccount.h>

@interface AIPurpleCertificateTrustWarningAlert : AIObject {
	IBOutlet NSPanel *panel;
	IBOutlet NSTextField *alertTitle;
	IBOutlet NSTextField *alertInformativeText;
	
	CFArrayRef certificates;
	AIAccount *account;
	
	void (*cert_cleanup)(void *userdata);
	void *userdata;
}

+ (void)displayTrustWarningAlertWithAccount:(AIAccount*)account hostname:(NSString*)hostname error:(OSStatus)err certificates:(CFArrayRef)certs cleanupCallback:(void (*)(void *userdata))_cert_cleanup userData:(void*)ud;

- (IBAction)panelOK:(id)sender;
- (IBAction)panelCancel:(id)sender;
- (IBAction)panelShowCertificate:(id)sender;

@end
