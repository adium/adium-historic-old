//
//  AIListGroupGradientCell.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupCell.h"

@interface AIListGroupGradientCell : AIListGroupCell {
	NSColor	*backgroundColor;
	NSColor	*gradientColor;
}

- (AIGradient *)backgroundGradient;
- (void)setBackgroundColor:(NSColor *)inBackgroundColor gradientColor:(NSColor *)inGradientColor;

@end
