//
//  AIServiceView.h
//  Adium
//
//  Created by Adam Iser on 12/9/04.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIAccountSetupServiceView : NSView {
	AIService			*service;
	NSImage				*serviceIcon;
	NSAttributedString	*serviceName;
	NSSize				serviceNameSize;
	
	BOOL				mouseIn;
	
	NSArray				*accounts;
	NSSize				serviceIconSize;
	
	AIAccount			*hoveredAccount;
	
	int 				accountNameHeight;
	
	id					delegate;
	
	
	NSArray				*trackingRects;
}

- (id)initWithService:(AIService *)inService delegate:(id)inDelegate;
- (void)setServiceIconSize:(NSSize)inSize;
- (void)setAccounts:(NSArray *)array;
- (NSDictionary *)accountNameAttributes;

@end
