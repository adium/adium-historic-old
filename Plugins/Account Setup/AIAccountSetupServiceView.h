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
	
	NSArray				*accounts;
	NSSize				serviceIconSize;
	
	int 				accountNameHeight;
}
- (void)setServiceIconSize:(NSSize)inSize;

@end
