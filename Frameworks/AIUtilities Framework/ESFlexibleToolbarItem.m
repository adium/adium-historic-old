//
//  ESFlexibleToolbarItem.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESFlexibleToolbarItem.h"


@implementation ESFlexibleToolbarItem

- (id)initWithItemIdentifier:(NSString *)itemIdentifier
{
	[super initWithItemIdentifier:itemIdentifier];
	
	validationDelegate = nil;
	
	return(self);
}

- (id)copyWithZone:(NSZone *)inZone
{
	return([super copyWithZone:inZone]);
}

- (void)setValidationDelegate:(id)inDelegate
{
	validationDelegate = inDelegate;
}

- (void)validate
{
	[validationDelegate validateToolbarItem:self];
	
	[super validate];
}

@end
