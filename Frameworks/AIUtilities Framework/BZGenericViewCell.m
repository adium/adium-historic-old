//
//  BZGenericViewCell.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sun May 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BZGenericViewCell.h"

//based on sample code at http://www.cocoadev.com/index.pl?NSViewInNSTableView

@implementation BZGenericViewCell

- init
{
	return [super initImageCell:nil];
}

- copyWithZone:(NSZone *)zone
{
	return [super copyWithZone:zone];
}

- (void)dealloc
{
	[super dealloc];
}

- (void)setObjectValue:(id <NSCopying>)object
{
	[super setObjectValue:object];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSView *embeddedView = [self objectValue];

	if([embeddedView superview] == nil) {
		[controlView addSubview:embeddedView];
	}

	[embeddedView setFrame:cellFrame];
}

@end
