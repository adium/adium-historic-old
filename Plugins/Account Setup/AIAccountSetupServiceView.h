//
//  AIServiceView.h
//  Adium
//
//  Created by Adam Iser on 12/9/04.
//  Copyright (c) 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIAccountSetupServiceView : NSView {
	AIService			*service;
	NSImage				*serviceIcon;
	NSAttributedString	*serviceName;
	NSSize				serviceNameSize;
	
	BOOL				mouseIn;
	NSTrackingRectTag	trackingTag;
	
	NSArray				*accounts;
	NSSize				serviceIconSize;
	
	AIAccount			*hoveredAccount;
	
	int 				accountNameHeight;
}

- (id)initWithService:(AIService *)inService;
- (void)setServiceIconSize:(NSSize)inSize;
- (void)addAccounts:(NSArray *)array;
- (NSDictionary *)accountNameAttributes;

@end
