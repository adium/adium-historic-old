//
//  BZGenericViewCell.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sun May 09 2004.
//

#import "AIGradientCell.h"

//Based on sample code from SubViewTableView by Joar Wingfors, http://www.joar.com/code/

@interface BZGenericViewCell : AIGradientCell
{
	NSView	*embeddedView;
}

- (void)setEmbeddedView:(NSView *)inView;

@end
