//
//  AIPurpleCertificateViewer.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-04.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SFCertificateView;

@interface AIPurpleCertificateViewer : NSObject {
	CFArrayRef certificatechain;
	
	IBOutlet SFCertificateView *certificateview;
	IBOutlet NSTableView *chaintable;
	IBOutlet NSWindow *window;
	IBOutlet NSSplitView *splitview;
}

+ (void)displayCertificateChain:(CFArrayRef)cc;

@end
