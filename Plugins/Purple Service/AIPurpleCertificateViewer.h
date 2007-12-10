//
//  AIPurpleCertificateViewer.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-04.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIObject.h>

@class AIAccount;

@interface AIPurpleCertificateViewer : AIObject {
	CFArrayRef certificatechain;
	
	AIAccount *account;
}

+ (void)displayCertificateChain:(CFArrayRef)cc forAccount:(AIAccount*)account;

@end
