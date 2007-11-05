//
//  AIPurpleCertificateViewer.m
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-04.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "AIPurpleCertificateViewer.h"
#import <SecurityInterface/SFCertificateView.h>
#import <AIUtilities/AITigerCompatibility.h>
#import <AvailabilityMacros.h>
#include <Security/cssmapi.h>
#include <Security/oidscert.h>
#include <Security/oidsattr.h>

#if MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED
@interface SFCertificateView (LeopardKnowsItAll)

- (void)setDetailsDisclosed:(BOOL)perhaps;

@end
#endif

@interface AIPurpleCertificateViewer (privateMethods)

- (id)initWithCertificateChain:(CFArrayRef)cc;
- (IBAction)showWindow:(id)sender;

@end

@implementation AIPurpleCertificateViewer

+ (void)displayCertificateChain:(CFArrayRef)cc {
	AIPurpleCertificateViewer *viewer = [[self alloc] initWithCertificateChain:cc];
	[viewer showWindow:nil];
	[viewer release];
}

- (id)initWithCertificateChain:(CFArrayRef)cc {
	if((self = [super init])) {
		certificatechain = cc;
		CFRetain(certificatechain);
	}
	return [self retain];
}

- (void)dealloc {
	CFRelease(certificatechain);
	[super dealloc];
}

- (IBAction)showWindow:(id)sender {
	if(!window)
		[NSBundle loadNibNamed:@"AICertificateViewer" owner:self];
	if([self numberOfRowsInTableView:chaintable] < 2) // collapse when there's nothing interesting to display
		[[chaintable enclosingScrollView] setFrameSize:NSMakeSize([[chaintable enclosingScrollView] frame].size.width, 0.0)];
	[window makeKeyAndOrderFront:sender];
	[self performSelector:@selector(tableViewSelectionDidChange:) withObject:nil afterDelay:0.0];
}

- (void)windowWillClose:(NSNotification *)notification {
	[self release];
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return CFArrayGetCount(certificatechain);
}

#if MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED
/* compare two OIDs, return CSSM_TRUE if identical */
static CSSM_BOOL compareOids(
							 const CSSM_OID *oid1,
							 const CSSM_OID *oid2)
{
	if((oid1 == NULL) || (oid2 == NULL)) {
		return CSSM_FALSE;
	}	
	if(oid1->Length != oid2->Length) {
		return CSSM_FALSE;
	}
	if(memcmp(oid1->Data, oid2->Data, oid1->Length)) {
		return CSSM_FALSE;
	}
	else {
		return CSSM_TRUE;
	}
}
#endif

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString *commonname = nil;
	SecCertificateRef cert = (SecCertificateRef)CFArrayGetValueAtIndex(certificatechain, row);
	
	// seriously WTF? I want my Leopard!
#if MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED
	CSSM_CL_HANDLE handle;
	CSSM_DATA certdata;
	uint32 numFields;
	CSSM_HANDLE resultsHandle;
	CSSM_DATA_PTR subject;
	CSSM_X509_NAME_PTR x509Name;
	OSStatus err = SecCertificateGetCLHandle(cert, &handle);
	if(err == noErr) {
		err = SecCertificateGetData(cert, &certdata);
		
		if(err == noErr) {
			CSSM_RETURN ret = CSSM_CL_CertGetFirstFieldValue(handle, &certdata, &CSSMOID_X509V1SubjectNameCStruct, &resultsHandle, &numFields, (CSSM_DATA_PTR*)&subject);
			unsigned rdnDex;
			
			if(ret == CSSM_OK) {
				x509Name = (CSSM_X509_NAME_PTR)subject->Data;
				
				for(rdnDex=0; rdnDex<x509Name->numberOfRDNs; rdnDex++) {
					CSSM_X509_RDN_PTR rdnp = &x509Name->RelativeDistinguishedName[rdnDex];
					unsigned pairDex;
					
					for(pairDex=0; pairDex<rdnp->numberOfPairs; pairDex++) {
						CSSM_X509_TYPE_VALUE_PAIR *ptvp = &rdnp->AttributeTypeAndValue[pairDex];
						if(compareOids(&ptvp->type, &CSSMOID_CommonName)) {
							CSSM_DATA_PTR cn = &ptvp->value;
							NSData *data = [NSData dataWithBytes:cn->Data length:cn->Length];
							
							commonname = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
							break;
						}
					}
					if(commonname)
						break;
				}
			}
		}
	}

	if(!commonname)
		err = -1;
	
	CSSM_CL_FreeFieldValue(handle, &CSSMOID_X509V1SubjectNameCStruct, subject);
	
#else
	OSStatus err = SecCertificateCopyCommonName(cert, (CFStringRef*)&commonname);
#endif
	
	if(err == noErr)
		return [commonname autorelease];
	
	return @"N/A";
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	int selectedRow = [chaintable selectedRow];
	if(selectedRow != NSNotFound) {
		SecCertificateRef cert = (SecCertificateRef)CFArrayGetValueAtIndex(certificatechain, selectedRow);
		[certificateview setCertificate:cert];
		if([certificateview respondsToSelector:@selector(setDetailsDisclosed:)])
			[certificateview setDetailsDisclosed:YES]; // we want details!
	} else
		[certificateview setCertificate:NULL];
}

@end
