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

- (id)init
{
	return([super initImageCell:nil]);
}

- (void)setEmbeddedView:(NSView *)inView
{
	embeddedView = inView;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if([embeddedView respondsToSelector:@selector(setIsHighlighted:)]){
		[embeddedView setIsHighlighted:[self isHighlighted]];
	}

	if([embeddedView superview] != controlView) {
		[controlView addSubview:embeddedView];
	}
	
	[embeddedView setFrame:cellFrame];	
}

- (BOOL)drawGridBehindCell
{
	return(YES);
}

@end
