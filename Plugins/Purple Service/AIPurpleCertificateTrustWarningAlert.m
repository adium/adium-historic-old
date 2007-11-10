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

// seems to be absent from the headers
OSStatus SecPolicySetValue(SecPolicyRef policyRef, CSSM_DATA *theCssmData);

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

	CSSM_APPLE_TP_SSL_OPTIONS ssloptions = {
		.Version = CSSM_APPLE_TP_SSL_OPTS_VERSION,
		.ServerNameLen = [hostname length]+1,
		.ServerName = [hostname cStringUsingEncoding:NSASCIIStringEncoding],
		.Flags = CSSM_APPLE_TP_SSL_CLIENT
	};
	
	CSSM_DATA theCssmData = {
		.Length = sizeof(ssloptions),
		.Data = (uint8*)&ssloptions 
	};
	
	err = SecPolicySetValue(policyRef, &theCssmData);
	// don't care about the error
	NSLog(@"SecPolicySetValue returned %i", err);
	
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
		// with help from http://lists.apple.com/archives/Apple-cdsa/2006/Apr/msg00013.html
		switch(result) {
			case kSecTrustResultProceed: // trust ok, go right ahead
			case kSecTrustResultUnspecified: // trust ok, user has no particular opinion about this
				query_cert_cb(true, userdata);
				[self release];
				break;
			case kSecTrustResultConfirm: // trust ok, but user asked (earlier) that you check with him before proceeding
			case kSecTrustResultDeny: // trust ok, but user previously said not to trust it anyway
			case kSecTrustResultRecoverableTrustFailure: // trust broken, perhaps argue with the user
				[NSClassFromString(@"AIEditAccountWindowController") editAccount:account onWindow:nil notifyingTarget:self];
				break;
			default:
				/*
				 * kSecTrustResultFatalTrustFailure -> trust broken, user can't fix it
				 * kSecTrustResultOtherError -> something failed weirdly, abort operation
				 * kSecTrustResultInvalid -> logic error; fix your program (SecTrust was used incorrectly
				 */
				query_cert_cb(false, userdata);
				[self release];
				break;
		}
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
	// TODO: if the user confirmed this cert, we should store this information at least until the app is closed

	[trustpanel release];
	CFRelease(trustRef);
	
	[win performSelector:@selector(performClose:) withObject:nil afterDelay:0.0];
	
	[self release];
}

@end
