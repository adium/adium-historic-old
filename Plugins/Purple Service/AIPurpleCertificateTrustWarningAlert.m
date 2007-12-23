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

static NSMutableDictionary *acceptedCertificates = nil;

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
		if(!acceptedCertificates)
			acceptedCertificates = [[NSMutableDictionary alloc] init];
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
	
	CSSM_DATA data;
	err = SecCertificateGetData((SecCertificateRef)CFArrayGetValueAtIndex(certificates, 0), &data);
	if(err == noErr) {
		// Did we ask the user to confirm this certificate before?
		// Note that this information is not stored on the disk, which is on purpose.
		NSData *certdata = [[NSData alloc] initWithBytesNoCopy:data.Data length:data.Length freeWhenDone:NO];
		NSData *oldcert = [acceptedCertificates objectForKey:hostname];
		BOOL ok = oldcert ? [certdata isEqualToData:oldcert] : NO;
		[certdata release];
		
		if(ok) {
			query_cert_cb(true, userdata);
			[self release];
			return;
		}
	}
		
	
	err = SecPolicySearchCreate(CSSM_CERT_X_509v3, &CSSMOID_APPLE_TP_SSL, NULL, &searchRef);
	if(err != noErr) {
		NSBeep();
		[self release];
		return;
	}
	
	err = SecPolicySearchCopyNext(searchRef, &policyRef);
	if(err != noErr) {
		CFRelease(searchRef);
		NSBeep();
		[self release];
		return;
	}

	CSSM_APPLE_TP_SSL_OPTIONS ssloptions = {
		.Version = CSSM_APPLE_TP_SSL_OPTS_VERSION,
		.ServerNameLen = [hostname length]+1,
		.ServerName = [hostname cStringUsingEncoding:NSASCIIStringEncoding],
		.Flags = 0
	};
	
	CSSM_DATA theCssmData = {
		.Length = sizeof(ssloptions),
		.Data = (uint8*)&ssloptions 
	};
	
	err = SecPolicySetValue(policyRef, &theCssmData);
	// don't care about the error
	
	err = SecTrustCreateWithCertificates(certificates, policyRef, &trustRef);
	if(err != noErr) {
		CFRelease(searchRef);
		CFRelease(policyRef);
		NSBeep();
		[self release];
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
			case kSecTrustResultOtherError: // failure other than trust evaluation; e.g., internal failure of the SecTrustEvaluate function. We'll let the user decide where to go from here.
			{
				SFCertificateTrustPanel *trustpanel = [[SFCertificateTrustPanel alloc] init];
				
				// this could probably be used for a more detailed message:
				//	CFArrayRef certChain;
				//	CSSM_TP_APPLE_EVIDENCE_INFO *statusChain;
				//	err = SecTrustGetResult(trustRef, &result, &certChain, &statusChain);
#define TRUST_PANEL_WIDTH 535
				NSWindow *fakeWindow = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, TRUST_PANEL_WIDTH, 0)
																	styleMask:NSTitledWindowMask
																	  backing:NSBackingStoreBuffered
																		defer:NO] autorelease];
				[fakeWindow center];

				[trustpanel setAlternateButtonTitle:AILocalizedString(@"Cancel",nil)];
				[trustpanel beginSheetForWindow:fakeWindow
								  modalDelegate:self
								 didEndSelector:@selector(certificateTrustSheetDidEnd:returnCode:contextInfo:)
									contextInfo:fakeWindow
										  trust:trustRef
										message:[NSString stringWithFormat:AILocalizedString(@"The certificate of the server %@ is not trusted, which means that the server's identity cannot be automatically verified. Do you want to continue connecting?\n\nFor more information, click \"Show Certificate\".",nil),hostname]];
				break;
			}				
			default:
				/*
				 * kSecTrustResultFatalTrustFailure -> trust broken, user can't fix it
				 * kSecTrustResultInvalid -> logic error; fix your program (SecTrust was used incorrectly)
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

- (void)certificateTrustSheetDidEnd:(SFCertificateTrustPanel *)trustpanel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSWindow *win = (NSWindow*)contextInfo;
	query_cert_cb(returnCode == NSOKButton, userdata);
	// if the user confirmed this cert, we store this information until the app is closed so the user doesn't have to re-confirm it every time
	// (this might be particularily annoying on auto-reconnect)
	CSSM_DATA certdata;
	OSStatus err = SecCertificateGetData((SecCertificateRef)CFArrayGetValueAtIndex(certificates, 0), &certdata);
	if(err == noErr)
		[acceptedCertificates setObject:[NSData dataWithBytes:certdata.Data length:certdata.Length] forKey:hostname];

	[trustpanel release];
	CFRelease(trustRef);
	
	[win performSelector:@selector(performClose:) withObject:nil afterDelay:0.0];
	
	[self release];
}

@end
