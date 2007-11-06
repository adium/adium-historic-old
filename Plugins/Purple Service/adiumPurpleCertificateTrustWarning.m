/*
 *  adiumPurpleCertificateTrustWarning.m
 *  Adium
 *
 *  Created by Andreas Monitzer on 2007-11-05.
 *  Copyright 2007 Andreas Monitzer. All rights reserved.
 *
 */

#import "adiumPurpleCertificateTrustWarning.h"
#import "AIPurpleCertificateTrustWarningAlert.h"

#import <Adium/AIObject.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAccountControllerProtocol.h>
#import "ESPurpleJabberAccount.h"

void adium_query_cert_chain(PurpleSslConnection *gsc, OSStatus err, const char *hostname, CFArrayRef certs, void (*cert_cleanup)(void *userdata), void *userdata) {
	NSObject<AIAccountController> *accountController = [[AIObject sharedAdiumInstance] accountController];
	// only the jabber service supports this right now
	NSEnumerator *e = [[accountController accountsCompatibleWithService:[accountController firstServiceWithServiceID:@"Jabber"]] objectEnumerator];
	ESPurpleJabberAccount *account;
	
	while((account = [e nextObject])) {
		if([account secureConnection] == gsc) {
			[AIPurpleCertificateTrustWarningAlert displayTrustWarningAlertWithAccount:account hostname:[NSString stringWithUTF8String:hostname] error:err certificates:certs cleanupCallback:cert_cleanup userData:userdata];
			break;
		}
	}
}

gboolean adium_cert_shouldverify(PurpleSslConnection *gsc) {
	NSObject<AIAccountController> *accountController = [[AIObject sharedAdiumInstance] accountController];
	// only the jabber service supports this right now
	NSEnumerator *e = [[accountController accountsCompatibleWithService:[accountController firstServiceWithServiceID:@"Jabber"]] objectEnumerator];
	ESPurpleJabberAccount *account;
	
	while((account = [e nextObject])) {
		if([account secureConnection] == gsc) {
			return [account shouldVerifyCertificates];
		}
	}
	return false;
}
