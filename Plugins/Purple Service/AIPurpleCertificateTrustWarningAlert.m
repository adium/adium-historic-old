//
//  AIPurpleCertificateTrustWarningAlert.m
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-05.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "AIPurpleCertificateTrustWarningAlert.h"
#import <SecurityInterface/SFCertificateTrustPanel.h>

@interface AIPurpleCertificateTrustWarningAlert (privateMethods)

- (id)initWithHostname:(NSString*)hostname error:(OSStatus)err certificates:(CFArrayRef)certs acceptCallback:(void (*)(void *userdata))_accept_cert rejectCallback:(void (*)(void *userdata))_reject_cert userData:(void*)ud;
- (IBAction)showWindow:(id)sender;

@end

@implementation AIPurpleCertificateTrustWarningAlert

+ (void)displayTrustWarningAlertWithHostname:(NSString*)hostname error:(OSStatus)err certificates:(CFArrayRef)certs acceptCallback:(void (*)(void *userdata))_accept_cert rejectCallback:(void (*)(void *userdata))_reject_cert userData:(void*)ud {
	AIPurpleCertificateTrustWarningAlert *alert = [[self alloc] initWithHostname:hostname error:err certificates:certs acceptCallback:_accept_cert rejectCallback:_reject_cert userData:ud];
	[alert showWindow:nil];
	[alert release];
}

- (id)initWithHostname:(NSString*)hostname error:(OSStatus)err certificates:(CFArrayRef)certs acceptCallback:(void (*)(void *userdata))_accept_cert rejectCallback:(void (*)(void *userdata))_reject_cert userData:(void*)ud {
	if((self = [super init])) {
		[NSBundle loadNibNamed:@"AICertificateTrustWarning" owner:self];
		NSString *informativeText;
		
		switch(err) {
			case errSSLUnknownRootCert:
				informativeText = AILocalizedString(@"The peer has a valid certificate chain, but the root of the chain is not a known anchor certificate.",nil);
				break;
			case errSSLNoRootCert:
				informativeText = AILocalizedString(@"The peer's certificate chain was not verifiable to a root certificate.",nil);
				break;
			case errSSLCertExpired:
				informativeText = AILocalizedString(@"The peer's certificate chain has one or more expired certificates.",nil);
				break;
			case errSSLXCertChainInvalid:
				informativeText = AILocalizedString(@"The peer has an invalid certificate chain; for example, signature verification within the chain failed, or no certificates were found.",nil);
				break;
			default:
				informativeText = AILocalizedString(@"Unknown certificate error.",nil);
				break;
		}
		[alertInformativeText setStringValue:informativeText];
		[alertTitle setStringValue:[NSString stringWithFormat:AILocalizedString(@"Unable to verify the certificate received from %@.",nil), hostname]];
		
		accept_cert = _accept_cert;
		reject_cert = _reject_cert;
		
		certificates = certs;
		CFRetain(certificates);
		
		userdata = ud;
	}
	return [self retain];
}

- (void)dealloc {
	CFRelease(certificates);
	[super dealloc];
}

- (IBAction)showWindow:(id)sender {
	[panel center];
	[panel makeKeyAndOrderFront:nil];
}

- (IBAction)panelOK:(id)sender {
	[panel close];
	accept_cert(userdata);
	[self release];
}

- (IBAction)panelCancel:(id)sender {
	[panel close];
	reject_cert(userdata);
	[self release];
}

- (IBAction)panelShowCertificate:(id)sender {
	
}

@end
