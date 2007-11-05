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

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString *commonname;
	SecCertificateRef cert = (SecCertificateRef)CFArrayGetValueAtIndex(certificatechain, row);
	
	OSStatus err = SecCertificateCopyCommonName(cert, (CFStringRef*)&commonname);
	
	if(err == noErr)
		return [commonname autorelease];
	
	return @"N/A";
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	int selectedRow = [chaintable selectedRow];
	if(selectedRow != NSNotFound) {
		SecCertificateRef cert = (SecCertificateRef)CFArrayGetValueAtIndex(certificatechain, selectedRow);
		[certificateview setCertificate:cert];
		[certificateview setDetailsDisclosed:YES]; // we want details!
	} else
		[certificateview setCertificate:NULL];
}

@end
