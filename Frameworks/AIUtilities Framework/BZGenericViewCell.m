//
//  BZGenericViewCell.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sun May 09 2004.
//

#import "BZGenericViewCell.h"

//Based on sample code from SubViewTableView by Joar Wingfors, http://www.joar.com/code/

@interface NSView (BZGenericViewCellEmbeddedView)
- (void)setIsHighlighted:(BOOL)flag;
@end

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
