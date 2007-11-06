//
//  AIPurpleCertificateTrustWarningAlert.m
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-05.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "AIPurpleCertificateTrustWarningAlert.h"
#import <SecurityInterface/SFCertificateTrustPanel.h>
#import <Security/SecureTransport.h>
#import <Security/SecPolicySearch.h>
#import <Security/oidsalg.h>
#import "ESPurpleJabberAccount.h"

@interface AIPurpleCertificateTrustWarningAlert (privateMethods)

- (id)initWithAccount:(AIAccount*)account hostname:(NSString*)hostname error:(OSStatus)err certificates:(CFArrayRef)certs cleanupCallback:(void (*)(void *userdata))_cert_cleanup userData:(void*)ud;
- (IBAction)showWindow:(id)sender;

@end

@implementation AIPurpleCertificateTrustWarningAlert

+ (void)displayTrustWarningAlertWithAccount:(AIAccount*)account hostname:(NSString*)hostname error:(OSStatus)err certificates:(CFArrayRef)certs cleanupCallback:(void (*)(void *userdata))_cert_cleanup userData:(void*)ud {
	AIPurpleCertificateTrustWarningAlert *alert = [[self alloc] initWithAccount:account hostname:hostname error:err certificates:certs cleanupCallback:_cert_cleanup userData:ud];
	[alert showWindow:nil];
	[alert release];
}

- (id)initWithAccount:(AIAccount*)_account hostname:(NSString*)hostname error:(OSStatus)err certificates:(CFArrayRef)certs cleanupCallback:(void (*)(void *userdata))_cert_cleanup userData:(void*)ud {
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
		
		cert_cleanup = _cert_cleanup;
		
		certificates = certs;
		CFRetain(certificates);
		
		account = _account;
		
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
	if([account respondsToSelector:@selector(setShouldVerifyCertificates:)])
		[(ESPurpleJabberAccount*)account setShouldVerifyCertificates:NO];
	
	[panel close];
	cert_cleanup(userdata);
	[self release];
}

- (IBAction)panelCancel:(id)sender {
	[panel close];
	cert_cleanup(userdata);
	[self release];
}

- (IBAction)panelShowCertificate:(id)sender {
	SecTrustRef trustRef;
	OSStatus err;
	SecPolicySearchRef searchRef = NULL;
	SecPolicyRef policyRef;
	
	err = SecPolicySearchCreate(CSSM_CERT_X_509v3, &CSSMOID_APPLE_X509_BASIC, NULL, &searchRef);
	if(err != noErr) {
		NSBeep();
		return;
	}
	err = SecPolicySearchCopyNext(searchRef, &policyRef);
	if(err != noErr) {
		CFRelease(searchRef);
		NSBeep();
		return;
	}
	
	err = SecTrustCreateWithCertificates(certificates, policyRef, &trustRef);
	if(err != noErr) {
		CFRelease(searchRef);
		CFRelease(policyRef);
		NSBeep();
		return;
	}
	
	SFCertificateTrustPanel *trustpanel = [[SFCertificateTrustPanel alloc] init];
	
	[trustpanel beginSheetForWindow:panel modalDelegate:self didEndSelector:@selector(certificateTrustSheetDidEnd:returnCode:contextInfo:) contextInfo:trustRef trust:trustRef message:AILocalizedString(@"Please verify the certificate chain.",nil)];
	
	CFRelease(searchRef);
	CFRelease(policyRef);
}
																					  
- (void)certificateTrustSheetDidEnd:(SFCertificateTrustPanel *)trustpanel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	SecTrustRef trustRef = (SecTrustRef)contextInfo;
	if(returnCode == NSOKButton) {
		SecTrustResultType result;
		CFArrayRef certChain;
		CSSM_TP_APPLE_EVIDENCE_INFO *statusChain;
		OSStatus err = SecTrustGetResult(trustRef, &result, &certChain, &statusChain);
		if(err == noErr) {
			if(result == kSecTrustResultProceed)
				[self performSelector:@selector(panelOK:) withObject:nil afterDelay:0.0];
		}
	}
	[trustpanel release];
	CFRelease(trustRef);
}

@end
