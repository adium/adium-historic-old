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
#import "AIEditAccountWindowController.h"

@interface AIPurpleCertificateTrustWarningAlert (privateMethods)

- (id)initWithAccount:(AIAccount*)account
			 hostname:(NSString*)hostname
		 certificates:(CFArrayRef)certs
	   resultCallback:(void (*)(gboolean trusted, void *userdata))_query_cert_cb
			 userData:(void*)ud;
- (IBAction)showWindow:(id)sender;

@end

@implementation AIPurpleCertificateTrustWarningAlert

+ (void)displayTrustWarningAlertWithAccount:(AIAccount*)account
								   hostname:(NSString*)hostname
							   certificates:(CFArrayRef)certs
							 resultCallback:(void (*)(gboolean trusted, void *userdata))_query_cert_cb
								   userData:(void*)ud
{
	AIPurpleCertificateTrustWarningAlert *alert = [[self alloc] initWithAccount:account hostname:hostname certificates:certs resultCallback:_query_cert_cb userData:ud];
	[alert showWindow:nil];
	[alert release];
}

- (id)initWithAccount:(AIAccount*)_account
			 hostname:(NSString*)_hostname
		 certificates:(CFArrayRef)certs
	   resultCallback:(void (*)(gboolean trusted, void *userdata))_query_cert_cb
			 userData:(void*)ud
{
	if((self = [super init])) {
		query_cert_cb = _query_cert_cb;
		
		certificates = certs;
		CFRetain(certificates);
		
		account = _account;
		hostname = [_hostname copy];
		
		userdata = ud;
	}
	return [self retain];
}

- (void)dealloc {
	CFRelease(certificates);
	[hostname release];
	[super dealloc];
}

- (IBAction)showWindow:(id)sender {
	OSStatus err;
	SecPolicySearchRef searchRef = NULL;
	SecPolicyRef policyRef;
	
	err = SecPolicySearchCreate(CSSM_CERT_X_509v3, &CSSMOID_APPLE_TP_SSL, NULL, &searchRef);
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
	
	// test whether we aren't already trusting this certificate
	SecTrustResultType result;
	err = SecTrustEvaluate(trustRef, &result);
	if(err == noErr) {
		switch(result) {
			case kSecTrustResultProceed:
				query_cert_cb(true, userdata);
				[self release];
				break;
			case kSecTrustResultConfirm:
			case kSecTrustResultDeny: // good idea?
			case kSecTrustResultRecoverableTrustFailure:
			case kSecTrustResultUnspecified:
				[NSClassFromString(@"AIEditAccountWindowController") editAccount:account onWindow:nil notifyingTarget:self];
				break;
			default:
				query_cert_cb(false, userdata);
				[self release];
				break;
		}
	} else if(err == kSecTrustResultUnspecified) {
		// we don't know about the trust, so just ask the user
		[NSClassFromString(@"AIEditAccountWindowController") editAccount:account onWindow:nil notifyingTarget:self];
	} else {
		query_cert_cb(false, userdata);
		[self release];
	}

	CFRelease(searchRef);
	CFRelease(policyRef);
}

- (void)editAccountWindow:(NSWindow*)window didOpenForAccount:(AIAccount *)inAccount {
	SFCertificateTrustPanel *trustpanel = [[SFCertificateTrustPanel alloc] init];
	
	[trustpanel setAlternateButtonTitle:AILocalizedString(@"Cancel",nil)];

	// this could probably be used for a more detailed message:
	//	CFArrayRef certChain;
	//	CSSM_TP_APPLE_EVIDENCE_INFO *statusChain;
	//	err = SecTrustGetResult(trustRef, &result, &certChain, &statusChain);

	[trustpanel beginSheetForWindow:window
	                  modalDelegate:self
	                 didEndSelector:@selector(certificateTrustSheetDidEnd:returnCode:contextInfo:)
	                    contextInfo:window
	                          trust:trustRef
	                        message:[NSString stringWithFormat:AILocalizedString(@"The certificate of the server %@ is not trusted, which means that the server's identity cannot be automatically verified. Do you want to continue connecting?\nFor more information, click \"Show Certificate\".",nil),hostname]];
}
																					  
- (void)certificateTrustSheetDidEnd:(SFCertificateTrustPanel *)trustpanel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSWindow *win = (NSWindow*)contextInfo;
	query_cert_cb(returnCode == NSOKButton, userdata);

	[trustpanel release];
	CFRelease(trustRef);
	
	[win performSelector:@selector(performClose:) withObject:nil afterDelay:0.0];
	
	[self release];
}

@end
