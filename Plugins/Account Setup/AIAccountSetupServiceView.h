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
	
	
	NSMutableArray		*trackingRects;
}

- (id)initWithService:(AIService *)inService delegate:(id)inDelegate;

//Configure
- (void)setAccounts:(NSArray *)array;
- (void)setServiceIconSize:(NSSize)inSize;
- (NSSize)serviceIconSize;
- (void)setDelegate:(id)inDelegate;
- (id)delegate;

@end

@interface NSObject (AIAccountSetupViewDelegate)
- (void)newAccountOnService:(AIService *)service;
- (void)editExistingAccount:(AIAccount *)account;
@end

