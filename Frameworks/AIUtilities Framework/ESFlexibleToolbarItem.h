//
//  ESFlexibleToolbarItem.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ESFlexibleToolbarItem : NSToolbarItem {
	id	validationDelegate;
}

- (void)setValidationDelegate:(id)inDelegate;

@end
